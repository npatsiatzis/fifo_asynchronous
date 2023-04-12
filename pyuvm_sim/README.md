![example workflow](https://github.com/npatsiatzis/fifo_asynchronous/actions/workflows/regression_pyuvm.yml/badge.svg)
![example workflow](https://github.com/npatsiatzis/fifo_asynchronous/actions/workflows/coverage_pyuvm.yml/badge.svg)


### asynchronous FIFO RTL implementation


- used to communicate data between 2 asynchronous clock domains
- Gray fifo pointers for avoiding data incoherency
- configurable FIFO depth and width
- logic for generating empty/full
- pyuvm testbench for functional verification
    - $ make
- CoCoTB-test unit testing (on pyuvm-based tb) to exercise the pyuvm tests across a range of values for the generic parameters
    - $  SIM=ghdl pytest -n auto -o log_cli=True --junitxml=test-results.xml --cocotbxml=test-cocotb.xml

