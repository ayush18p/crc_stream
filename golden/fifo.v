//added delay for rd_en
module fifo#(parameter WIDTH = 8, 
            DEPTH = 16) 
    (

    input                clk,
    input                rstn,

    input [WIDTH:0]     din,
    input               wr_en,
    input               rd_en,

    output reg [WIDTH:0]    dout,
    output              empty,
    output              full                         

);
reg ADD_WIDTH = $clog2(DEPTH);
reg [WIDTH:0] FIFO_MEM [0:DEPTH-1];
reg [4:0] wr_ptr; 
reg [4:0] rd_ptr; 
reg       rd_in_r;

assign full = (wr_ptr[4]     != rd_ptr[4]) &&
       (wr_ptr[3:0] == rd_ptr[3:0]);
// assign full     = ((wr_ptr+1)%DEPTH) == rd_ptr;
assign empty    = wr_ptr == rd_ptr;

always@(posedge clk or negedge rstn) 
begin
    if(!rstn) begin
        rd_in_r <= 0;
    end
    else rd_in_r <= rd_en;

end


//Write
always@(posedge clk or negedge rstn) 
begin
    if(!rstn) begin
       wr_ptr           <= 0;
    end
    else begin
        if(wr_en && !full) begin
         FIFO_MEM[wr_ptr[3:0]]    <= din;
         wr_ptr              <= wr_ptr + 1; 
        end
    end
end
    
//Read
always@(posedge clk or negedge rstn) 
begin
    if(!rstn) begin
       rd_ptr           <= 0;
       dout             <= 0;
    end
    else begin
        if(rd_en && !empty) begin
         dout           <= FIFO_MEM[rd_ptr[3:0]];
         rd_ptr         <= rd_ptr+1;
        end
    end
end
    

endmodule