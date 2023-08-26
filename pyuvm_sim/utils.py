from cocotb.triggers import Timer,RisingEdge,ClockCycles
from cocotb.queue import QueueEmpty, Queue
import cocotb
import enum
import random
from cocotb_coverage import crv 
from cocotb_coverage.coverage import CoverCross,CoverPoint,coverage_db
from pyuvm import utility_classes



class A_FifoBfm(metaclass=utility_classes.Singleton):
    def __init__(self):
        self.dut = cocotb.top
        self.driver_queue = Queue(maxsize=1)
        self.data_mon_queue = Queue(maxsize=0)
        self.result_mon_queue = Queue(maxsize=0)

    async def send_data(self, data):
        await self.driver_queue.put(data)

    async def get_data(self):
        data = await self.data_mon_queue.get()
        return data

    async def get_result(self):
        result = await self.result_mon_queue.get()
        return result

    async def resetW(self):
        await RisingEdge(self.dut.i_clkW)
        self.dut.i_arstnW.value = 0
        self.dut.i_wren.value = 0
        self.dut.i_dataW.value = 0 
        await ClockCycles(self.dut.i_clkW,5)
        self.dut.i_arstnW.value = 1
        await RisingEdge(self.dut.i_clkW)

    async def resetR(self):
        await RisingEdge(self.dut.i_clkR)
        self.dut.i_arstnR.value = 0
        self.dut.i_ren.value = 0
        await ClockCycles(self.dut.i_clkR,8)
        self.dut.i_arstnR.value = 1
        await RisingEdge(self.dut.i_clkR)

    async def driver_bfm(self):
        while True:
            await RisingEdge(self.dut.i_clkW)
            try:
                (wren,ren,data) = self.driver_queue.get_nowait()
                self.dut.i_wren.value = wren
                self.dut.i_ren.value = ren
                self.dut.i_dataW.value = data
            except QueueEmpty:
                pass

    async def data_mon_bfm(self):
        while True:
            # await RisingEdge(self.dut.f_wr_done)
            if(self.dut.i_wren.value == 1 and self.dut.o_full.value ==0):
                data = self.dut.i_dataW.value
                self.data_mon_queue.put_nowait(data)
            await RisingEdge(self.dut.i_clkW)

    async def result_mon_bfm(self):
        while True:
            # await RisingEdge(self.dut.f_rd_done)
            if(self.dut.i_ren.value == 1 and self.dut.o_empty.value ==0):
                await RisingEdge(self.dut.i_clkR)
                self.result_mon_queue.put_nowait(self.dut.o_dataR.value)
            await RisingEdge(self.dut.i_clkR)

    def start_bfm(self):
        cocotb.start_soon(self.driver_bfm())
        cocotb.start_soon(self.data_mon_bfm())
        cocotb.start_soon(self.result_mon_bfm())