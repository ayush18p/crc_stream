# CRC Stream Specifications

## Overview

The design task is mainly aimed to generate CRC for a stream of data which is transmitted by AXI Stream Protocol and outputs the data and CRC through AXI Stream Protocol.

## AXI Stream Protocol

The AXI-Stream protocol is used as a standard interface to exchange data between connected components.
AXI-Stream is a point-to-point protocol, connecting a single Transmitter and a single Receiver

1. **AXIS_TDATA** : Carries the data from one point to other point.
2. **AXIS_TVALID** : A resposne signal which is active when a stream of data is being transmitted.
3. **AXIS_TLAST** : Indicates the transmission of last sample of stream.
4. **AXIS_TREADY**: Indicates readiness of the module to transmit data


## FIFO

FIFO is a commonly used module which acts a temproary buffer especially for data stream activities. 

## CRC Engine

A Cyclic Redundancy Check (CRC) is a widely used error-detecting code in digital networks and storage devices that identifies accidental data changes. It works by calculating a short, fixed-length binary sequence—based on polynomial division—which is appended to the data, allowing the receiver to verify integrity

A CRC Engine should calculate CRC for given sample based on initial value of CRC which is usaully set as a standard based on the version of the CRC used as required. There are 4 bit CRCs, 5 bit CRCs, 8 bit CRCs, 16 bit CRCs, 28 bit CRCs, 31 bit CRCs, 32 bit CRCs and 64 bit CRCs. Again there are divided on the bit width of their input data and initial CRC value.

## Interface Details

### Axi Stream and CRC generation process

&nbsp;&nbsp;&nbsp;&nbsp; **Parameter 'WIDTH' for data width of FIFO and AXI Stream Protocol**\
&nbsp;&nbsp;&nbsp;&nbsp; **Parameter 'DEPTH' for data depth of FIFO**

**NOTE :** for simplcity I will use WIDTH as 'w' and DEPTH as 'd'

### Inputs:
• **clk (1-bit)** : A single bit input clk that drives the entire design, which includes top module and submodule
• **rstn (1-bit)** : A single bit input control signal which resets the state of the design. It is asynchronous and active low
• **mode (1-bit)** : A single bit which decides what state the design runs at. Do you need to just pass the data as is or calculate the crc and stream the data
• **stream_number (10-bit)** : A 10 bit input which decides the number of streams which will be transmitted. i.e if stream_number = N, then N streams will be transmitted from source (2,1023)
• **S_AXIS_TDATA(w bits) (w-1:0)** : A w bit sized input which carries stream data from source
• **S_AXIS_TVALID (1-bit)** : A single bit input which indicates valid input data
• **S_AXIS_TLAST (1-bit)** : A single bit input which indicates last sample of input data
• **M_AXIS_TREADY(1-bit)** : A single bit input which indicates destination is ready to recieve data

### Outpus:
• **M_AXIS_TDATA(w bits) (w-1:0)** : A w bit sized output which carries stream data to destination
• **M_AXIS_TVALID (1-bit)** : A single bit output which indicates valid output data
• **M_AXIS_TLAST (1-bit)** : A single bit output which indicates last sample of output data
• **S_AXIS_TREADY(1-bit)** : A single bit output which indicates the source to send the data
• **drop_packet (1-bit)** : A single bit output which indicates the source that the (N-1)th stream to be discarded.
• **crc_final (32-bit)** : A 32 bit output which contains the final crc data for the input stream
• **crc_done (1-bit)** : A single bit output which indicates completion of CRC for 1 stream

## Functionality
WIDTH = 8;
DEPTH = 16;

### TOP Module 

The input stream contains 8 bit wide data input which may contain n samples. As mentioned earlier CRC is calculated for each sample in the stream. The Output CRC is generated at the last sample of the stream and sent out. The input stream should be continually streamed outside as is at the end of the input data stream then only the CRC shoulde be appended. 

The total stream number is provided by stream_number, assume N. As mentioned, N streams of n samples. The CRC is calcuated to all the N streams
range : stream_number(2,1023)
        n samples    (8,250) for simplicty

crc_final contains the final crc value for the stream. The first crc_final comes after 1st streams final sample is detected and crc_done is detected 

The input stream and crc_final are stored in a file named input_data.txt. Which will be verifed with a python script

#### mode :
To calculate and append the CRC is at the users discretion. If the user chooses not to calculate and append CRC they can choose mode = 0, else mode = 1;

#### CRC Calculation :
CRC Calculation and Append is done for all N(2,1023) streams, but there is a catch. The CRC is valid only N-1 Streams. At Nth Stream a dummy input with 10 zeroes are provided so that it calculates a dummy crc with a packet_drop pulse. This pulse indicates the destination to drop the final stream samples. 

### FIFO 

A typical synchronous FIFO module with 9 bit input and 9 bit output with rd_en, wr_en, empty and full ports. This FIFO acts as intrmediate buffer between sample stream and CRC Engine.

### CRC Engine Details :

CRC32x08 : Input data of 8 bits, calculates 32 bit output. Initial CRC fetch from online sources. One CRC Calculation should happen within one cycle of the arrival of the sample. Final CRC is sent out only when last sample of the data stream is detected. It has an internal reg to store crc

### FSM Controller

The FSM is responsible for the major operational and process flow.
1. It controls the input stream to FIFO from S_AXIS. The data input to CRC Engine based on rd_en and wr_en.
2. It controls when the CRC Engine should be enabled based on mode
3. It controls the output stream to M_AXIS. Do you need to send the data as is in a mode 0 or CRC Calcuated data appended with data? 
4. It controls the entire AXI Stream Protocol Handling as per AXI Stream Norms and design under testing