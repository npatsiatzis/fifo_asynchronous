### asynchronous FIFO RTL implementation

- used to communicate data between 2 asynchronous clock domains
- Gray fifo pointers for avoiding data incoherency
- configurable FIFO depth and width
- logic for generating empty/full

- Link to the playground : https://www.edaplayground.com/x/Y9BV
- Make sure that "Use run.do Tcl file" and "Download files after run" options remain checked 
- results.zip is downloaded at the end of the execution
    - contains all the SV/UVM tb files, coverage information etc...
    