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
    //Internal Logic for FIFO

endmodule