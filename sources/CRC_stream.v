module axis_crc_top(
    input       clk,
    input       rstn,
    input       mode,
    input [9:0] stream_number,

    input [7:0]     S_AXIS_TDATA,
    input           S_AXIS_TVALID,
    input           S_AXIS_TLAST,
    output          S_AXIS_TREADY,

    output reg [7:0]    M_AXIS_TDATA,
    output reg          M_AXIS_TVALID,
    output reg          M_AXIS_TLAST,
    input               M_AXIS_TREADY,
    
    output reg          drop_packet,
    output [31:0]         crc_final,
    output                crc_done

);


// Instantiate a FIFO

// Instantiate a  CRC Engine

// Instantiate a FSM controller to handle processing and operation


endmodule