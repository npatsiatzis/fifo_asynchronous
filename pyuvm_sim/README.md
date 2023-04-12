
### asynchronous FIFO RTL implementation


- used to communicate data between 2 asynchronous clock domains
- Gray fifo pointers for avoiding data incoherency
- configurable FIFO depth and width
- logic for generating empty/full
- CoCoTB testbench for functional verification
    - $ make
- CoCoTB-test unit testing to exercise the CoCoTB tests across a range of values for the generic parameters
    - $  SIM=ghdl pytest -n auto -o log_cli=True --junitxml=test-results.xml --cocotbxml=test-cocotb.xml

