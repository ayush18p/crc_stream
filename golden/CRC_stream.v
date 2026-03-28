module axis_crc_top(
    input       clk,
    input       rstn,
    input       mode,
    input [9:0] stream_number,
    //AXIS Slave
    input [7:0]     S_AXIS_TDATA,
    input           S_AXIS_TVALID,
    input           S_AXIS_TLAST,
    output          S_AXIS_TREADY,

    //AXIS MASTER
    output reg [7:0]    M_AXIS_TDATA,
    output reg          M_AXIS_TVALID,
    output reg          M_AXIS_TLAST,
    input               M_AXIS_TREADY,
    
    output reg          drop_packet,
    output [31:0]         crc_final,
    output                crc_done
);
reg [9:0] counter;
//FIFO Instantitation

wire [7:0] fifo_data;
wire       fifo_empty;
wire       fifo_full;

wire        rd_en;
wire        wr_en;
reg         rd_en_r;

assign wr_en = S_AXIS_TREADY && S_AXIS_TVALID;
assign S_AXIS_TREADY    = !fifo_full;


fifo xfifo(
    .clk(clk),
    .rstn(rstn),
    .wr_en(wr_en),
    .rd_en(rd_en),
    .din({S_AXIS_TLAST, S_AXIS_TDATA}),
    .dout({fifo_tlast,fifo_data}),
    .full(fifo_full),
    .empty(fifo_empty)
);

//CRC Engine Instantiation

wire xcrc_en;
wire [31:0] crc_out;

crc_engine xcrc_engine(
    .clk(clk),
    .rstn(rstn),
    .data(fifo_data),
    .crc_en(xcrc_en),
    .crc_out(crc_out),
    .crc_done(crc_done)
);


//Control FSM
localparam  PASSTHROUGH = 1'b0;
localparam  CALC_CRC    = 1'b1;

localparam  xIDLE   = 2'd0 ;
localparam  xCALC   = 2'd1 ;
localparam  xAPPEND = 2'd2 ;
localparam  xWAIT   = 2'd3 ;

reg [1:0] xstate;
reg [1:0] crc_bcnt;


reg fifo_tlast_r;

always@(posedge clk or negedge rstn)
begin
    if(!rstn) begin
        fifo_tlast_r <= 0;
    end
    else begin
        fifo_tlast_r <= fifo_tlast;
    end
end

always@(posedge clk or negedge rstn)
begin
    if(!rstn) begin
        xstate   <= xIDLE;
        crc_bcnt <= 0;
    end
    else begin
        case(xstate)
        xIDLE : begin
            if(!fifo_empty) begin
                xstate <= xCALC;
            end
        end

        xCALC : begin
            if(mode == CALC_CRC && rd_en_r)
            if(fifo_tlast) begin
                if(mode == CALC_CRC) 
                begin
                    xstate   <= xWAIT;
                    crc_bcnt <= 1;
                end
                else begin
                    xstate <= xIDLE;
                end
            end
        end
        xWAIT   : begin
             xstate   <= xAPPEND;
        end
        xAPPEND : begin
            crc_bcnt <= crc_bcnt + 1;
            if(crc_bcnt == 2'd3)
                xstate <= xIDLE;

        end

        default : xstate <= xIDLE;
        endcase
    end
end

reg restart;//from 2nd sample to adjust for 1 cycle delay

always @(posedge clk or negedge rstn) begin
    if (!rstn) 
        restart <= 0;
    else 
        restart <= (xstate == xAPPEND && crc_bcnt == 3);     
end

 assign   rd_en = (xstate == xCALC || restart) && !fifo_empty && M_AXIS_TREADY;

 always @(posedge clk or negedge rstn) begin
    if (!rstn) 
        restart <= 0;
    else 
        rd_en_r <= rd_en;   
end

 
 assign   xcrc_en = (M_AXIS_TLAST) ? rd_en : rd_en_r && rd_en;

//OUTPUT Data formatter

always@(posedge clk or negedge rstn)
begin
    if(!rstn) begin
        M_AXIS_TLAST    <= 0;
        M_AXIS_TVALID   <= 0;

    end
    else begin
        case(xstate)
        xIDLE : begin
            if(M_AXIS_TLAST)begin
             M_AXIS_TDATA <= fifo_data;
             M_AXIS_TLAST <= 0;
             end
             if(counter == stream_number - 1) begin
                M_AXIS_TVALID <= 0;
             end
        end
        xCALC : begin
            M_AXIS_TVALID   <= rd_en_r;
            M_AXIS_TDATA    <= fifo_data;

            if(mode == PASSTHROUGH)
                M_AXIS_TLAST   <= fifo_tlast;
            else
                M_AXIS_TLAST    <= 0;
        end
        
        xWAIT : begin
             M_AXIS_TVALID <= 1;
             M_AXIS_TDATA  <= crc_out[31:24];
        end

        xAPPEND : begin
            M_AXIS_TVALID <= 1;
            case(crc_bcnt)
                2'd1: M_AXIS_TDATA  <= crc_out[23:16];
                2'd2: M_AXIS_TDATA  <= crc_out[15:8];
                2'd3: M_AXIS_TDATA  <= crc_out[7:0];
            endcase
            M_AXIS_TLAST    <= (crc_bcnt == 2'd3);            
        end

        default : begin
            M_AXIS_TDATA <= 0;
            M_AXIS_TLAST <= 0;
        end

        endcase
    end
end

always@(posedge clk or negedge rstn)
begin
    if(!rstn) begin
        counter <= 0;
        drop_packet <= 0;
    end
    else begin
        drop_packet <= 0; 
            if(M_AXIS_TLAST) begin
                if(counter == stream_number - 1) begin
                    counter <= 0;
                    drop_packet <= 1;
                end
                else begin
                    counter <= counter + 1;
                end      
        end
    end
end

assign crc_final = crc_out;

endmodule