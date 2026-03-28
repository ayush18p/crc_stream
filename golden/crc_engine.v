module crc_engine(
    input clk,
    input rstn,
    input [7:0] data,

    input       crc_en,
    output reg [31:0] crc_out,
    output reg  crc_done        

);

reg [31:0] crc_init;
wire [31:0] crc_next;
reg [31:0] crc_prev;
reg crc_en_r, crc_en_rr, crc_en_rrr;


assign crc_pulse = (crc_en_r^crc_en) && crc_en_r;

always@(posedge clk or negedge rstn) 
begin
    if(!rstn) begin
        crc_en_r <= 0;
        crc_en_rr <= 0;
        crc_en_rrr <= 0;
    end
    else begin
        crc_en_r <= crc_en;
        crc_en_rr <= crc_en_r;
        crc_en_rrr <= crc_en_rr;
    end
end 
always@(posedge clk or negedge rstn) 
begin
    if(!rstn) begin
        crc_init <= 32'hFFFFFFFF;
        crc_prev <= crc_init;   
    end
    else begin
    if(crc_en)
        crc_prev <=  crc_next;
    end
end 


always@(*) 
begin
    if(crc_pulse) begin
        crc_out = crc_prev; crc_prev = crc_init; crc_done = 1;
    end
    else 
    crc_done = 0;
end

CRC32_08 xCRC32_08 (.data (data), .prev_crc(crc_prev), .en(crc_en), .crc_calc(crc_next));

endmodule

module CRC32_08(
    input [7:0]     data,
    input [31:0]    prev_crc,
    input           en,
    output [31:0]   crc_calc
);

assign crc_calc[31] = en ? data[5] ^ prev_crc[23] ^ prev_crc[29] : 0;
assign crc_calc[30] = en ? data[4] ^ data[7] ^ prev_crc[22] ^ prev_crc[28] ^ prev_crc[31] : 0;
assign crc_calc[29] = en ? data[3] ^ data[6] ^ data[7] ^ prev_crc[21] ^ prev_crc[27] ^ prev_crc[30] ^ prev_crc[31]: 0;
assign crc_calc[28] = en ? data[2] ^ data[5] ^ data[6] ^ prev_crc[20] ^ prev_crc[26] ^ prev_crc[29] ^ prev_crc[30]: 0;
assign crc_calc[27] = en ? data[1] ^ data[4] ^ data[5] ^ data[7] ^ prev_crc[19] ^ prev_crc[25] ^ prev_crc[28] ^ prev_crc[29] ^ prev_crc[31]: 0;
assign crc_calc[26] = en ? data[0] ^ data[3] ^ data[4] ^ data[6] ^ prev_crc[18] ^ prev_crc[24] ^ prev_crc[27] ^ prev_crc[28] ^ prev_crc[30]: 0;
assign crc_calc[25] = en ? data[2] ^ data[3] ^ prev_crc[17] ^ prev_crc[26] ^ prev_crc[27]: 0;
assign crc_calc[24] = en ? data[1] ^ data[2] ^ data[7] ^ prev_crc[16] ^ prev_crc[25] ^ prev_crc[26] ^ prev_crc[31]: 0;
assign crc_calc[23] = en ? data[0] ^ data[1] ^ data[6] ^ prev_crc[15] ^ prev_crc[24] ^ prev_crc[25] ^ prev_crc[30]: 0;
assign crc_calc[22] = en ? data[0] ^ prev_crc[14] ^ prev_crc[24]: 0;
assign crc_calc[21] = en ? data[5] ^ prev_crc[13] ^ prev_crc[29]: 0;
assign crc_calc[20] = en ? data[4] ^ prev_crc[12] ^ prev_crc[28]: 0;
assign crc_calc[19] = en ? data[3] ^ data[7] ^ prev_crc[11] ^ prev_crc[27] ^ prev_crc[31]: 0;
assign crc_calc[18] = en ? data[2] ^ data[6] ^ data[7] ^ prev_crc[10] ^ prev_crc[26] ^ prev_crc[30] ^ prev_crc[31]: 0;
assign crc_calc[17] = en ? data[1] ^ data[5] ^ data[6] ^ prev_crc[25] ^ prev_crc[29] ^ prev_crc[30] ^ prev_crc[9]: 0;
assign crc_calc[16] = en ? data[0] ^ data[4] ^ data[5] ^ prev_crc[24] ^ prev_crc[28] ^ prev_crc[29] ^ prev_crc[8]: 0;
assign crc_calc[15] = en ? data[3] ^ data[4] ^ data[5] ^ data[7] ^ prev_crc[27] ^ prev_crc[28] ^ prev_crc[29] ^ prev_crc[31] ^ prev_crc[7]: 0;
assign crc_calc[14] = en ? data[2] ^ data[3] ^ data[4] ^ data[6] ^ data[7] ^ prev_crc[26] ^ prev_crc[27] ^ prev_crc[28] ^ prev_crc[30] ^ prev_crc[31] ^ prev_crc[6] : 0;
assign crc_calc[13] = en ? data[1] ^ data[2] ^ data[3] ^ data[5] ^ data[6] ^ data[7] ^ prev_crc[25] ^ prev_crc[26] ^ prev_crc[27] ^ prev_crc[29] ^ prev_crc[30] ^ prev_crc[31] ^ prev_crc[5]: 0;
assign crc_calc[12] = en ? data[0] ^ data[1] ^ data[2] ^ data[4] ^ data[5] ^ data[6] ^ prev_crc[24] ^ prev_crc[25] ^ prev_crc[26] ^ prev_crc[28] ^ prev_crc[29] ^ prev_crc[30] ^ prev_crc[4]: 0;
assign crc_calc[11] = en ? data[0] ^ data[1] ^ data[3] ^ data[4] ^ prev_crc[24] ^ prev_crc[25] ^ prev_crc[27] ^ prev_crc[28] ^ prev_crc[3]: 0;
assign crc_calc[10] = en ? data[0] ^ data[2] ^ data[3] ^ data[5] ^ prev_crc[24] ^ prev_crc[26] ^ prev_crc[27] ^ prev_crc[29] ^ prev_crc[2]: 0;
assign crc_calc[9] = en ?data[1] ^ data[2] ^ data[4] ^ data[5] ^ prev_crc[1] ^ prev_crc[25] ^ prev_crc[26] ^ prev_crc[28] ^ prev_crc[29]: 0;
assign crc_calc[8] = en ?data[0] ^ data[1] ^ data[3] ^ data[4] ^ prev_crc[0] ^ prev_crc[24] ^ prev_crc[25] ^ prev_crc[27] ^ prev_crc[28]: 0;
assign crc_calc[7] = en ?data[0] ^ data[2] ^ data[3] ^ data[5] ^ data[7] ^ prev_crc[24] ^ prev_crc[26] ^ prev_crc[27] ^ prev_crc[29] ^ prev_crc[31]: 0;
assign crc_calc[6] = en ?data[1] ^ data[2] ^ data[4] ^ data[5] ^ data[6] ^ data[7] ^ prev_crc[25] ^ prev_crc[26] ^ prev_crc[28] ^ prev_crc[29] ^ prev_crc[30] ^ prev_crc[31]: 0;
assign crc_calc[5] = en ?data[0] ^ data[1] ^ data[3] ^ data[4] ^ data[5] ^ data[6] ^ data[7] ^ prev_crc[24] ^ prev_crc[25] ^ prev_crc[27] ^ prev_crc[28] ^ prev_crc[29] ^ prev_crc[30] ^ prev_crc[31]: 0;
assign crc_calc[4] = en ?data[0] ^ data[2] ^ data[3] ^ data[4] ^ data[6] ^ prev_crc[24] ^ prev_crc[26] ^ prev_crc[27] ^ prev_crc[28] ^ prev_crc[30]: 0;
assign crc_calc[3] = en ?data[1] ^ data[2] ^ data[3] ^ data[7] ^ prev_crc[25] ^ prev_crc[26] ^ prev_crc[27] ^ prev_crc[31]: 0;
assign crc_calc[2] = en ?data[0] ^ data[1] ^ data[2] ^ data[6] ^ data[7] ^ prev_crc[24] ^ prev_crc[25] ^ prev_crc[26] ^ prev_crc[30] ^ prev_crc[31]: 0;
assign crc_calc[1] = en ?data[0] ^ data[1] ^ data[6] ^ data[7] ^ prev_crc[24] ^ prev_crc[25] ^ prev_crc[30] ^ prev_crc[31]: 0;
assign crc_calc[0] = en ?data[0] ^ data[6] ^ prev_crc[24] ^ prev_crc[30]: 0;

endmodule


