![example workflow](https://github.com/npatsiatzis/fifo_asynchronous/actions/workflows/regression.yml/badge.svg)
![example workflow](https://github.com/npatsiatzis/fifo_asynchronous/actions/workflows/formal.yml/badge.svg)
![example workflow](https://github.com/npatsiatzis/fifo_asynchronous/actions/workflows/regression_pyuvm.yml/badge.svg)
![example workflow](https://github.com/npatsiatzis/fifo_asynchronous/actions/workflows/coverage_pyuvm.yml/badge.svg)
![example workflow](https://github.com/npatsiatzis/fifo_asynchronous/actions/workflows/verilator_regression.yml/badge.svg)
![example workflow](https://github.com/npatsiatzis/fifo_asynchronous/actions/workflows/verilator_regression.yml/badge.svg)
### asynchronous FIFO RTL implementation


- used to communicate data between 2 asynchronous clock domains
- Gray fifo pointers for avoiding data incoherency
- configurable FIFO depth and width
- logic for generating empty/full


-- RTL code in:
- [VHDL](https://github.com/npatsiatzis/fifo_asynchronous/tree/main/rtl/VHDL)
- [SystemVerilog](https://github.com/npatsiatzis/fifo_asynchronous/tree/main/rtl/SystemVerilog)

-- Functional verification with methodologies:
- [cocotb](https://github.com/npatsiatzis/fifo_asynchronous/tree/main/cocotb_sim)
- [pyuvm](https://github.com/npatsiatzis/fifo_asynchronous/tree/main/pyuvm_sim)
- [uvm](https://github.com/npatsiatzis/fifo_asynchronous/tree/main/uvm_sim)
- [verilator](https://github.com/npatsiatzis/fifo_asynchronous/tree/main/verilator_sim)
