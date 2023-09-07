import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer,RisingEdge,FallingEdge,ClockCycles
from cocotb.utils import get_sim_time
from cocotb.result import TestFailure
import random
from cocotb_coverage.coverage import CoverCross,CoverPoint,coverage_db
from cocotb.queue import Queue,QueueEmpty,QueueFull


covered_number = []
g_width = int(cocotb.top.g_width)
g_depth = int(cocotb.top.g_depth)

fifo = []
fifo_rd = []


wr = 0 
rd = 0 
data = 0 


# #Callback functions to capture the bin content showing
full_cross = False
def notify():
	global full_cross
	full_cross = True

# at_least = value is superfluous, just shows how you can determine the amount of times that
# a bin must be hit to considered covered
@CoverPoint("top.data",xf = lambda x : x.i_dataW.value, bins = list(range(2**g_width)), at_least=1)
@CoverPoint("top.wr",xf = lambda x : x.i_wren.value, bins = [True,False], at_least=1)
@CoverCross("top.cross", items = ["top.wr","top.data"], at_least=1)
def number_cover(dut):
	covered_number.append((dut.i_wren.value,dut.i_dataW.value))
	

async def reset(dut,cycles=1):
	dut.i_arstnW.value = 0
	dut.i_arstnR.value = 0

	dut.i_wren.value = 0 
	dut.i_ren.value = 0
	dut.i_dataW.value = 0

	await ClockCycles(dut.i_clkW,cycles)
	await FallingEdge(dut.i_clkW)
	dut.i_arstnW.value = 1
	dut.i_arstnR.value = 1
	await RisingEdge(dut.i_clkW)
	dut._log.info("the core was reset")


@cocotb.test()
async def test_overflow(dut):
	#clocks with variable phase difference
	cocotb.start_soon(Clock(dut.i_clkW, (1/(2*10**8)), units="sec").start())
	cocotb.start_soon(Clock(dut.i_clkR, 22, units="ns").start())
	await reset(dut,5)	

	wr = 1 
	rd = 0 
	data = random.randint(0,2**g_width-1)

	dut.i_wren.value = wr
	dut.i_dataW.value = data
	dut.i_ren.value = rd


	await RisingEdge(dut.i_clkW)
	for i in range(2**g_depth +2):
		if(i < 2**g_depth):
			fifo.append(data)
		data = random.randint(0,2**g_width-1)
		dut.i_dataW.value = data
		await RisingEdge(dut.i_clkW)

	assert not (dut.o_full.value != 1),"Full flag, falsely not set!"
	wr = 0 
	rd = 1 

	dut.i_wren.value = wr
	dut.i_dataW.value = data
	dut.i_ren.value = rd
	await RisingEdge(dut.i_clkR)
	while(dut.o_empty.value == 1):
		await RisingEdge(dut.i_clkR)
	for i in range(2**g_depth):
		await RisingEdge(dut.i_clkR)
		fifo_rd.append(int(dut.o_dataR.value))

	assert not (fifo != fifo_rd),"Potential overflow issue!"

@cocotb.test()
async def test_underflow(dut):
	#clocks with variable phase difference
	cocotb.start_soon(Clock(dut.i_clkW, 3, units="ns").start())
	cocotb.start_soon(Clock(dut.i_clkR, 11, units="ns").start())
	await reset(dut,5)

	data = random.randint(0,2**g_width-1)

	await RisingEdge(dut.i_clkW)
	for i in range (2):
		data = random.randint(0,2**g_width-1)
		dut.i_dataW.value = data 
		await RisingEdge(dut.i_clkW)

	wr = 0 
	rd = 1 

	dut.i_wren.value = wr 
	dut.i_ren.value = rd 
	await RisingEdge(dut.i_clkR)
	for i in range(2**g_depth + 2):
		await RisingEdge(dut.i_clkR)

	assert not (dut.o_empty.value != 1),"Empty flag falsely not set!"
	assert not (dut.addr_r.value != dut.addr_w.value),"Overflow issue detected!"
