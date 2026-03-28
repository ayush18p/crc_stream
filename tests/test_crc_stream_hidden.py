from __future__ import annotations

import os
import random
from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ReadOnly, RisingEdge

from cocotb_tools.runner import get_runner

skip_next = False

LANGUAGE = os.getenv("HDL_TOPLEVEL_LANG", "verilog").lower().strip()

@cocotb.test()
async def run_test(dut):

    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    dut.rstn.value = 0
    dut.mode.value = 1;

    dut.S_AXIS_TDATA.value = 0
    dut.S_AXIS_TVALID.value = 0
    dut.S_AXIS_TLAST.value = 0

    dut.M_AXIS_TREADY.value = 1
    dut.stream_number.value = 0

    f_in  = open("input_data.txt", "w")
    f_out = open("output_data.txt", "w")

    for _ in range(5):
        await RisingEdge(dut.clk)

    dut.rstn.value = 1

    for _ in range(5):
        await RisingEdge(dut.clk)

    num_pkts = random.randint(2, 10)
    dut.stream_number.value = num_pkts

    # ---------------- OUTPUT MONITOR ----------------
    async def monitor_output():
        pkt_id = 0
        global skip_next

        while True:
            await RisingEdge(dut.clk)
            await ReadOnly()

            if skip_next:   
                skip_next = False
                continue

            if dut.M_AXIS_TVALID.value and dut.M_AXIS_TREADY.value:
                data = int(dut.M_AXIS_TDATA.value)
                tlast = int(dut.M_AXIS_TLAST.value)

                f_out.write(f"{data:02X}\n")

                if tlast:
                    f_out.write(f"--- END PACKET {pkt_id} ---\n")
                    pkt_id += 1
                    skip_next = True
                    
    cocotb.start_soon(monitor_output())

    # ---------------- INPUT DRIVER ----------------
    for pkt in range(num_pkts):

        if pkt == num_pkts - 1:
            pkt_len = 10
        else:
            pkt_len = random.randint(12, 40)

        f_in.write(f"\nPACKET {pkt} LEN {pkt_len}\n")

        i = 0

        while i < pkt_len:

            if pkt == num_pkts - 1:
                data = 0
            else:
                data = random.randint(0, 255)

            dut.S_AXIS_TVALID.value = 1
            dut.S_AXIS_TDATA.value  = data
            dut.S_AXIS_TLAST.value  = 1 if i == pkt_len - 1 else 0

            await RisingEdge(dut.clk)

            if dut.S_AXIS_TREADY.value == 1:
                f_in.write(f"{data:02X}\n")
                i += 1

        await RisingEdge(dut.clk)
        dut.S_AXIS_TVALID.value = 0
        dut.S_AXIS_TLAST.value  = 0

        # CRC logging only if mode = 1
        if dut.mode.value == 1:
            await RisingEdge(dut.crc_done)
            crc_val = int(dut.crc_final.value)
            f_in.write(f"CRC {crc_val:08X}\n")

    for _ in range(300):
        await RisingEdge(dut.clk)

    f_in.close()
    f_out.close()

def test_crc_stream_hidden_runner():
   sim = os.getenv("SIM", "icarus")

   proj_path = Path(__file__).resolve().parent.parent

   sources = [
       proj_path / "golden/fifo.v",
       proj_path / "golden/crc_engine.v",
       proj_path / "golden/CRC_stream.v",
   ]

   runner = get_runner(sim)
   runner.build(
       sources=sources,
       hdl_toplevel="axis_crc_top",
       always=True,
       timescale=("1ns", "1ps"),
   )

   runner.test(hdl_toplevel="axis_crc_top", test_module="test_crc_stream_hidden")