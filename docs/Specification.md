## Requirements Specification


### 1. SCOPE

1. **Scope**

   This document establishes the requirements for an Intellectual Property (IP) that provides an asynchronous FIFO function.
1. **Purpose**
 
   These requirements shall apply to an asynchronous FIFO core with a simple interface for inclusion as a component.
1. **Classification**
    
   This document defines the requirements for a hardware design.


### 2. DEFINITIONS

1. **Push**

   The action of inserting data into the FIFO.
2. **Pop**
   
   The axtion of extracting data from the FIFO.
3. **Empty** 
   The FIFO buffer with no valid data.

1. **Full**

   The FIFO buffer being at its maximum level.
1. **Read and Write pointers**

   Pointers represent the internal structure of the FIFO to identify where the data will be stored or be read. Since there are multiple clock domains in this design, we also need to synchronize the pointers in their oposite domain.


### 3. APPLICABLE DOCUMENTS 

1. **Government Documents**

   None
1. **Non-government Documents**

   None


### 4. ARCHITECTURAL OVERVIEW

1. **Introduction**

   The asynchronous FIFO component shall represent a design written in an HDL (VHDL and/or SystemVerilog) that can easily be incorporateed into a larger design. The FIFO shall be asynchronous with one clock that governs reads and another for writes. This asynchronous FIFO shall include the following features : 
     1. Parameterized word width, and FIFO depth.
     1. asynchronous FIFO push/pop operation.
     1. asynchronous active-low reset.

   The CPU interface in this case is the standard FIFO interface.

1. **System Application**
   
    The asynchronous FIFO can be applied to a variety of system configurations. An example use is the FIFO being used to resolve differences in processing capabilities between a producer and a consumer operating on the same clock.

### 5. PHYSICAL LAYER

 1. i_dataW, word to insert to FIFO
 6. o_dataR, word extracted from FIFO
 7. wren, FIFO write request
 8. ren, FIFO read request
 9. full, flag indicating FIFO is full
 1. empty, flag indicating FIFO is empty with valid data
 7. clkW, clock, domain write
 8. clkR, clock, domain read
 9. arstn_W, reset, asynchronous active low, domain write
 10. arstn_R, reset, asynchronous active low, domain read

### 6. PROTOCOL LAYER

The FIFO operates on single word writes or single word reads 

### 7. ROBUSTNESS

Does not apply.

### 8. HARDWARE AND SOFTWARE

1. **Parameterization**

   The asynchronous FIFO shall provide for the following parameters used for the definition of the implemented hardware during hardware build:

   | Param. Name | Description |
   | :------: | :------: |
   | width | width of data words |
   | depth | number of bits to express FIFO depth |

1. **CPU interface**

   The CPU shall request the write of data in the FIFO issuing a write request (wren active) and the extractiong of data from the FIFO with a read request (ren active).


### 9. PERFORMANCE

1. **Frequency**
1. **Power Dissipation**
1. **Environmental**
 
   Does not apply.
1. **Technology**

   The design shall be adaptable to any technology because the design shall be portable and defined in an HDL.

### 10. TESTABILITY
None required.

### 11. MECHANICAL
Does not apply.
