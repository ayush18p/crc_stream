from __future__ import annotations

import os
import random
from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

from cocotb_tools.runner import get_runner

LANGUAGE = os.getenv("HDL_TOPLEVEL_LANG", "verilog").lower().strip()

@cocotb.test()
async def crc_stream_test(dut):

    cocotb.start_soon(Clock(dut.clk_0, 10, units="ns").start())

    dut.rstn.value = 0
    dut.mode.value = 1

    dut.S_AXIS_TDATA.value = 0
    dut.S_AXIS_TVALID.value = 0
    dut.S_AXIS_TLAST.value = 0

    dut.M_AXIS_TREADY.value = 0
    dut.stream_number.value = 0

    # Open file
    f = open("input_data.txt", "w")

    for _ in range(5):
        await RisingEdge(dut.clk_0)

    dut.rstn_0.value = 1

    for _ in range(5):
        await RisingEdge(dut.clk_0)

    dut.M_AXIS_TREADY.value = 1

    total_samples = 0

    num_pkts = random.randint(2, 1023)
    dut.stream_number.value = num_pkts

    for pkt in range(num_pkts):

        if pkt == num_pkts - 1:
            pkt_len = 10
        else:
            pkt_len = random.randint(12, 250)

        f.write(f"\nPACKET {pkt} LEN {pkt_len}\n")

        i = 0

        while i < pkt_len:
            await RisingEdge(dut.clk_0)

            dut.S_AXIS_TVALID.value = 1

            if pkt == num_pkts - 1:
                data = 0
            else:
                data = random.randint(0, 255)

            dut.S_AXIS_TDATA.value = data
            dut.S_AXIS_TLAST.value = 1 if i == pkt_len - 1 else 0

            if dut.S_AXIS_TREADY.value == 1:
                total_samples += 1
                f.write(f"{data:02X}\n")
                i += 1

        await RisingEdge(dut.clk_0)
        dut.S_AXIS_TVALID.value = 0
        dut.S_AXIS_TLAST.value = 0

        crc_val = int(dut.crc_final.value)
        f.write(f"CRC {crc_val:08X}\n")

    for _ in range(300):
        await RisingEdge(dut.clk_0)

    f.close()

    cocotb.log.info(f"Packets sent = {num_pkts}")
    cocotb.log.info(f"Total samples sent = {total_samples}")

def test_crc_stream_hidden_runner():
   sim = os.getenv("SIM", "icarus")

   proj_path = Path(__file__).resolve().parent.parent

   sources = [proj_path / "sources/CRC_stream.v"]

   runner = get_runner(sim)
   runner.build(
       sources=sources,
       hdl_toplevel="axis_crc_top",
       always=True,
   )

   runner.test(hdl_toplevel="axis_crc_top", test_module="test_crc_stream_hidden")