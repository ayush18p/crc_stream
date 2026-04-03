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

// --- CRC_STREAM_STUB_AXIS_TOP_BEGIN ---
// Replace this block with FIFO instance, CRC engine instance, and control FSM.
// Use the line markers below so search_replace old_string stays unique.

// CRC_STREAM_STUB_MARKER_FIFO
// Instantiate a FIFO

// CRC_STREAM_STUB_MARKER_CRC_ENGINE
// Instantiate a CRC Engine

// CRC_STREAM_STUB_MARKER_FSM
// Instantiate a FSM controller to handle processing and operation

// --- CRC_STREAM_STUB_AXIS_TOP_END ---

endmodule
