## Verification Plan

### 1. SCOPE

1. **Scope**

   This document establishes the verification plan for the asynchronous fifo design specified in
the requirements specification. It identifies the features to be tested, the test 
cases, the expected responses, and the methods of test case application and 
verification. 

1. **Purpose**

   The verification plan provides a definition of the testbench, verification 
properties, test environment, coverage sequences, application of test cases, and 
verification approaches for the asynchronous fifo design as specified in the requirement 
specification number asynchronous fifo_req_001(Specification.md).
   The goals of this plan is not only to provide an outline on how the component 
will be tested, but also to provide a strawman document that can be scrutinized 
by other design and system engineers to refine the verification approach. 

1. **Classification**

   This document defines the test methods for a hardware design. 
### 2. DEFINITIONS

1. **BFM**
   
   A Bus Functional Model emulates the operation of an interface.


1. **transaction**
    
    A transaction describes a high-level interace operation, e.g. WRITE DATA on ADDRESS at specified time.

### 3.APPLICABLE DOCUMENTS 

1. **Government Documents**

   None. 
1. **Non-government Documents**

   Document #: asynchronous fifo_req_001(Specification.md), Requirement Specification for asynchronous fifo.

1. **Executable specifications**

   None. 
1. **Reference Sources**

   IEEE Standard VHDL Language Reference Manual - Redline," in IEEE Std 1076-2008 (Revision of IEEE Std 1076-2002) - Redline , vol., no., pp.1-620, 26 Jan. 2009.

   IEEE Standard for SystemVerilog--Unified Hardware Design, Specification, and Verification Language," in IEEE Std 1800-2012 (Revision of IEEE Std 1800-2009) , vol., no., pp.1-1315, 21 Feb. 2013, doi: 10.1109/IEEESTD.2013.6469140.
### 4. COMPLIANCE PLAN

   SystemVerilog with assertions along with simulation will be used as the
verification language because it is an open language that provides good 
constructs and verification features. This plan consists of the following:
* **Feature Extractions and Test Strategy**
* **Test application approach for the asynchronous fifo**
* **Test verification approach**

1. **Feature Extractions and Test Strategy**

   The design features are extracted from the requirements specification. For each 
feature of the design, a test strategy is recognized. The strategy consists of 
directed and pseudo-random tests. A verification criterion for each of the design 
feature is documented. This feature definition, test strategy, test sequence, and
verification criteria forms the basis of the functional verification plan. The following
summarizes the feature extraction and verification criteria for the functional 
requirements. 
For corner testing, pseudo-random receive/transmit transactions will be simulated 
to mimic a asynchronous fifo in a system environment. The environment will perform the
following transactions at pseudo-random intervals: 
   1. Create push requests 
   2. Create pop requests
   3. Force resets

   For each feature-strategy pair, verification (pass/fail) criteria are proposed.

   | Feature | Testing Strategy | Test Sequence | Verification Criteria |
   | :------: | :------: | :------: | :------: |
   | Parameterization | compilation | does not apply. | Design compiles and elaborates correctly. |
   | Reset | Directed Test | set reset signal active (high) | All components of asynchronous fifo enter reset state |
   | push/ pop requests | Constrained Random | Coverage Driven (full coverage for data input space) |    *assert* observed data = expected data, for each test |


1. **Testbench Architecture**
   
   Several architectural elements must be considered in the definition of the testbench 
environment, including the following: 

   * Reusability / ease of use / portability / verification language 
   * Number of BFMs to emulate the separate busses 
   * Synchronization methods between BFMs 
   * Transactions definition and sequencing methods 
   * Transactions driving methods 
   * Verification strategies for design and its subblocks


   1. **Reusability / ease of use / portability / verification language**
   
      SystemVerilog will be used for this design because it is a standard language, and is 
portable across tools. A reusable design style will be applied. More precisely, the Universal Verification Methodology (UVM) will be used to build the testbench architecture.

1. **Number of BFMs to emulate the separate busses**

   The number of BFMs in this case is 1. The BFM is a SystemVerilog interface that cover all ports of the design, either of the processor or of the serial interface. Specific components of the UVM testbench architecture can access the specific ports of interest via this BFM.
2. **Synchronization methods between BFMs**

   As stated above, there will be 1 BFM in this case.  
3. **Transactions definition and sequencing methods**

   Transactions (except for the case of reset and error injection) will be generated randomly in a coverage-driven constrained random generation pattern. Transaction sequencing will be performed via the sequence-sequencer pipeline of the UVM testbench architecture.
4. **Transactions driving methods**

   Transaction driving will be achieved by the sequence-sequencer-driver classes in the UVM testbench architecture.
5. **Verification strategies for design and its subblocks**
