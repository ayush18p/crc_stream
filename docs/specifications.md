Design a parameterizable RTL module in Verilog that implements a streaming data processor over an AXI-Stream interface.

The module must support two modes of operation:

1. Pass-through mode (no modification to data)
2. CRC append mode (compute CRC-32 over packet and append it)


### Interface Requirements:
* Input : `clk` : The main clock which drives the design
* Input : `rstn` : Drives the reset for design, asynchronous and active low
* AXI-Stream slave input (S_AXIS): `tdata[7:0]`, `tvalid`, `tready`, `tlast`
* AXI-Stream master output (M_AXIS): `tdata[7:0]`, `tvalid`, `tready`, `tlast`
* Control input: `mode`
* Output: `crc_done` (asserted when crc_final is driven)
* Input : `stream_number` -> The maximum number of streams supported, Range (2,1023)
* Output : `drop_packet` -> indicates the destination to discard the packet
* Output : `crc_final` : 32 bit CRC output for the stream

### Functional Requirements:

* Data arrives as packets of variable length (minimum 2 bytes, maximum unbounded)
* In append mode:

  * Compute CRC-32 over entire packet
  * Append 4-byte CRC after last data byte
  * It should compute for N-1 Streams, at the Nth Stream a dummy packet of tens 0's will be sent at which drop+packet is asserted

* In pass-through mode:

  * Forward data unchanged with correct AXI signaling

### Constraints and Edge Cases:

* The design must handle backpressure 
* No data loss or duplication is allowed across packet boundaries
* `tlast` must be preserved correctly and aligned with output data
* The CRC engine has a latency of 1 cycle (input valid → output valid next cycle)
* Input data is continuous (back-to-back packets allowed without idle cycles)
* FIFO or buffering may be required but is not mandated — designer must decide
* CRC Engine Should only have the following ports : `clk`,`rstn`,`data[7:0]`,`crc_en` as inputs and `crc_out [31:0]` and `crc_done` as outputs

### Additional Requirements:

* The design must ensure correct handling of the final byte in a packet
* No assumptions should be made about gaps between packets
* The module must be synthesizable
* The agent must save input stream data in hex format and end of each stream the crc should be stored as CRC_VALUE in a input_data.txt file
* The agent should also store the output stream data with its corresponding crc as stream output in a output_data.txt

### Deliverables:

* Complete Verilog RTL implementation
* Clear handling of control/data alignment
* Correct AXI-Stream protocol behavior under all conditions

### Evaluation Criteria:

* Functional correctness across all modes
* Proper AXI handshake handling
* Correct CRC computation and alignment
* Robustness to corner cases (packet boundaries, backpressure)
