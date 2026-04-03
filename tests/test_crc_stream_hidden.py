from __future__ import annotations

import os
import random
from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ReadOnly, RisingEdge, SimTimeoutError, with_timeout

from cocotb_tools.runner import get_runner

_MAX_STALL_CYCLES_PER_BEAT = 50_000
_CRC_DONE_TIMEOUT_NS = 500_000.0


@cocotb.test()
async def run_test(dut):

    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    dut.rstn.value = 0
    dut.mode.value = 1

    dut.S_AXIS_TDATA.value = 0
    dut.S_AXIS_TVALID.value = 0
    dut.S_AXIS_TLAST.value = 0

    dut.M_AXIS_TREADY.value = 1
    dut.stream_number.value = 0

    f_in = open("input_data.txt", "w")
    f_out = open("output_data.txt", "w")

    for _ in range(5):
        await RisingEdge(dut.clk)

    dut.rstn.value = 1

    for _ in range(5):
        await RisingEdge(dut.clk)

    # Cap packet count so broken DUTs hit crc_done timeouts without multi-hour wall-clock runs
    # (agent bash tool default timeout is HUD_BASH_TIMEOUT, typically 20 minutes).
    num_pkts = random.randint(2, 64)
    dut.stream_number.value = num_pkts

    # ---------------- OUTPUT MONITOR ----------------
    async def monitor_output():
        pkt_id = 0

        while True:
            await RisingEdge(dut.clk)
            await ReadOnly()

            if dut.M_AXIS_TVALID.value and dut.M_AXIS_TREADY.value:
                data = int(dut.M_AXIS_TDATA.value)
                tlast = int(dut.M_AXIS_TLAST.value)

                f_out.write(f"{data:02X}\n")

                if tlast:
                    f_out.write(f"--- END PACKET {pkt_id} ---\n")
                    pkt_id += 1

    cocotb.start_soon(monitor_output())

    # ---------------- INPUT DRIVER ----------------
    for pkt in range(num_pkts):

        if pkt == num_pkts - 1:
            pkt_len = 10
        else:
            pkt_len = random.randint(12, 250)

        f_in.write(f"\nPACKET {pkt} LEN {pkt_len}\n")

        i = 0
        stall_cycles = 0

        while i < pkt_len:

            if pkt == num_pkts - 1:
                data = 0
            else:
                data = random.randint(0, 255)

            dut.S_AXIS_TVALID.value = 1
            dut.S_AXIS_TDATA.value = data
            dut.S_AXIS_TLAST.value = 1 if i == pkt_len - 1 else 0

            await RisingEdge(dut.clk)

            if dut.S_AXIS_TREADY.value == 1:
                f_in.write(f"{data:02X}\n")
                i += 1
                stall_cycles = 0
            else:
                stall_cycles += 1
                if stall_cycles > _MAX_STALL_CYCLES_PER_BEAT:
                    raise AssertionError(
                        f"S_AXIS_TREADY stuck low for >{_MAX_STALL_CYCLES_PER_BEAT} cycles "
                        f"(packet {pkt}, beat {i}/{pkt_len})"
                    )

        await RisingEdge(dut.clk)
        dut.S_AXIS_TVALID.value = 0
        dut.S_AXIS_TLAST.value = 0

        if dut.mode.value == 1:
            try:
                await with_timeout(RisingEdge(dut.crc_done), _CRC_DONE_TIMEOUT_NS, "ns")
            except SimTimeoutError as e:
                raise AssertionError(
                    f"crc_done did not assert within {_CRC_DONE_TIMEOUT_NS} ns "
                    f"(packet {pkt}; check CRC engine / FSM)"
                ) from e

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
        proj_path / "sources/fifo.v",
        proj_path / "sources/crc_engine.v",
        proj_path / "sources/CRC_stream.v",
    ]

    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="axis_crc_top",
        always=True,
        timescale=("1ns", "1ps"),
    )

    runner.test(hdl_toplevel="axis_crc_top", test_module="test_crc_stream_hidden")