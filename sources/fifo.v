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
// --- CRC_STREAM_STUB_FIFO_BEGIN ---
// CRC_STREAM_MARKER_FIFO_IMPLEMENT
// Internal Logic for FIFO
// --- CRC_STREAM_STUB_FIFO_END ---

endmodule
