# CRC Stream Task

## Task Description

Create a AXI Stream Interface to calculate CRC for each stream.

The agent should create 'axis_crc_top' that :
1. Instatiates two sub modules for FIFO and CRC_ENGINE
2. Create a transimssion controller
3. Calculates CRC for N streams
4. Store the input data and calculated final CRC value for each stream to verify it using a python script

## Directory Structure

- 'sources/' - Buggy RTL Files 
- 'golden/'  - RTL files(golden implementation)
- 'test/'   - Hidden grading scripts