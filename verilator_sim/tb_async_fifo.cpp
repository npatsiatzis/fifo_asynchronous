// Verilator Example
#include <stdlib.h>
#include <iostream>
#include <cstdlib>
#include <memory>
#include <set>
#include <deque>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include <verilated_cov.h>
#include "Vasync_fifo.h"
#include "Vasync_fifo_async_fifo.h"   //to get parameter values, after they've been made visible in SV


#define POSEDGE(ns, period, phase) \
    ((ns) % (period) == (phase))

#define NEGEDGE(ns, period, phase) \
    ((ns) % (period) == ((phase) + (period)) / 2 % (period))

#define CLK_A_PERIOD 30
#define CLK_A_PHASE 0

#define CLK_B_PERIOD 50
#define CLK_B_PHASE 0




#define MAX_SIM_TIME 300
#define VERIF_START_TIME 2*std::max(CLK_A_PERIOD,CLK_B_PERIOD)
vluint64_t sim_time = 0;
vluint64_t posedge_cnt = 0;

// input interface transaction item class
class InTx {
    private:
    public:
        unsigned int i_wren;
        unsigned int i_ren;
        unsigned int i_dataW;
};


// output interface transaction item class (data)
class OutTx {
    public:
        unsigned int o_dataR;

};

// output interface transaction item class (control flow)
class OutTxControl {
    public:
        unsigned int o_empty;
        unsigned int o_full;
};



//in domain Coverage
class InCoverage{
    private:
        std::set <unsigned int> in_cvg;
    
    public:
        void write_coverage(InTx *tx){
            in_cvg.insert(tx->i_dataW);
        }

        bool is_covered(unsigned int A){            
            return in_cvg.find(A) == in_cvg.end();
        }
};

//out domain Coverage
class OutCoverage {
    private:
        std::set <unsigned int> o_data_coverage;
        std::set <unsigned int> o_full_coverage;
        std::set <unsigned int> o_empty_coverage;

    public:
        void write_coverage(OutTx* tx){
            o_data_coverage.insert(tx->o_dataR); 
        }

        void write_coverage_control(OutTxControl* tx){
            o_full_coverage.insert(tx->o_full);
            o_empty_coverage.insert(tx->o_empty);
            delete tx;
        }

        bool is_covered(unsigned int A){
            return o_data_coverage.find(A) == o_data_coverage.end();
        }
        bool is_full_coverage_full_empty(){
            if(o_full_coverage.size() == 2 && o_empty_coverage.size() == 2){
                return true;
            } else {
                return false;
            }
        }

        bool is_full_coverage(){
            return o_data_coverage.size() == (1 << (Vasync_fifo_async_fifo::g_width));
        }
};


// scoreboard
class Scb {
    private:
        std::deque<InTx*> in_q;
        std::deque<OutTx*> out_q;
        
    public:
        // Input interface monitor port
        void writeIn(InTx *tx){
            // Push the received transaction item into a queue for later
            in_q.push_back(tx);
        }

        // Output interface monitor port
        void writeOut(OutTx *tx){
            // Push the received transaction item into a queue for later
            out_q.push_back(tx);
        }

        void checkPhase(){
            while(out_q.empty() == 0){
                InTx* in;
                in = in_q.front();
                in_q.pop_front(); 

                OutTx* out;
                out = out_q.front();
                out_q.pop_front(); 

                std::cout << "asdas" << std::endl;

                if(in->i_dataW != out->o_dataR){
                    std::cout << "Test Failure!" << std::endl;
                    std::cout << "Expected : " <<  in->i_dataW << std::endl;
                    std::cout << "Got : " << out->o_dataR << std::endl;
                    exit(1);
                } else {
                    std::cout << "Test PASS!" << std::endl;
                    std::cout << "Expected : " <<  in->i_dataW << std::endl;
                    std::cout << "Got : " << out->o_dataR << std::endl;   
                }

                // As the transaction items were allocated on the heap, it's important
                // to free the memory after they have been used
                delete in;    //input monitor transaction
                delete out;    //output monitor transaction
            }
        }

};

// interface driver
class InDrv {
    private:
        // Vasync_fifo *dut;
        std::shared_ptr<Vasync_fifo> dut;
        int state;
    public:
        InDrv(std::shared_ptr<Vasync_fifo> dut){
            this->dut = dut;
            state = 0;
        }


        void drive(InTx *tx, int & new_tx_ready,int is_a_pos,int is_b_pos){

            dut->i_wren = tx->i_wren;
            dut->i_dataW = tx->i_dataW;
            dut->i_ren = tx->i_ren;
        }
};

// input interface monitor
class InMon {
    private:
        // Vasync_fifo *dut;
        std::shared_ptr<Vasync_fifo> dut;
        // Scb *scb;
        std::shared_ptr<Scb>  scb;
        // InCoverage *cvg;
        std::shared_ptr<InCoverage> cvg;
    public:
        InMon(std::shared_ptr<Vasync_fifo> dut, std::shared_ptr<Scb>  scb, std::shared_ptr<InCoverage> cvg){
            this->dut = dut;
            this->scb = scb;
            this->cvg = cvg;
        }

        void monitor(int is_a_pos){
            if(is_a_pos ==1 && dut->i_wren == 1 && dut->o_full ==0) {
                InTx *tx = new InTx();
                tx->i_dataW = dut->i_dataW;
                // then pass the transaction item to the scoreboard
                scb->writeIn(tx);
                cvg->write_coverage(tx);
            }
        }
};

// output interface monitor
class OutMon {
    private:
        // Vasync_fifo *dut;
        std::shared_ptr<Vasync_fifo> dut;
        // Scb *scb;
        std::shared_ptr<Scb> scb;
        // OutCoverage *cvg;
        std::shared_ptr<OutCoverage> cvg;
        int state;
    public:
        OutMon(std::shared_ptr<Vasync_fifo> dut, std::shared_ptr<Scb> scb, std::shared_ptr<OutCoverage> cvg){
            this->dut = dut;
            this->scb = scb;
            this->cvg = cvg;
            state = 0;
        }

        void monitor(int is_a_pos, int is_b_pos){

            //cover the empty and full signals independently from the o_dataR one.
            if(is_a_pos == 1 || is_b_pos == 1){
                OutTxControl *tx_control = new OutTxControl();
                tx_control->o_empty = dut->o_empty;
                tx_control->o_full = dut->o_full;
                cvg->write_coverage_control(tx_control);
            }


            switch(state) {
                case 0:
                    // a read is about to take place, save the value on next cycle
                    if(is_b_pos == 1 && dut->i_ren == 1 && dut->o_empty ==0) {
                        state = 1;
                     }

                    break;
                case 1: {
                    // read value from previous cycle, stay in state to read next value
                    if(is_b_pos == 1 && dut->i_ren == 1 && dut->o_empty ==0) {
                        state = 1;

                        OutTx *tx = new OutTx();
                        tx->o_dataR = dut->o_dataR;


                        // then pass the transaction item to the scoreboard
                        scb->writeOut(tx);
                        cvg->write_coverage(tx);
                    }
                    // read value from previous cycle, go to that state next
                    else if(is_b_pos == 1) {
                        state = 0;

                        OutTx *tx = new OutTx();
                        tx->o_dataR = dut->o_dataR;


                        // then pass the transaction item to the scoreboard
                        scb->writeOut(tx);
                        cvg->write_coverage(tx);
                    }
                    break;
                }
                default:
                    state = 0;
            }
        }
};

//sequence (transaction generator)
// coverage-driven random transaction generator
// This will allocate memory for an InTx
// transaction item, randomise the data, until it gets
// input values that have yet to be covered and
// return a pointer to the transaction item object
class Sequence{
    private:
        InTx* in;
        std::shared_ptr<OutCoverage> cvg;
        unsigned int wren;
        unsigned int data;
        unsigned int ren;
    public:
        Sequence(std::shared_ptr<OutCoverage> cvg){
            this->cvg = cvg;
            wren = 0;
            ren = 0;
            data = 0;
        }

        InTx* genTx(int & new_tx_ready,int is_a_pos,int is_b_pos){
            in = new InTx();
            if(is_a_pos == 1) {
                in->i_dataW = rand() % (1 << Vasync_fifo_async_fifo::g_width);  
                in->i_wren = rand() %2;

                while(cvg->is_covered(in->i_dataW) == false  && cvg->is_full_coverage() == false){
                   in->i_dataW = rand() % (1 << Vasync_fifo_async_fifo::g_width); 

                }
                wren = in->i_wren;
                data = in->i_dataW;
            } else{
                in->i_dataW = data;
                in->i_wren = wren;
            }
            if(is_b_pos == 1) {
                in->i_ren = rand() %2; 

                ren = in->i_ren;
            } else {
                in->i_ren = ren;
            }

            return in;
        }
};


void dut_reset (std::shared_ptr<Vasync_fifo> dut, vluint64_t &sim_time){
    dut->i_arstnW = 1;
    dut->i_arstnR = 1; 
    if(sim_time >= 0 && sim_time < VERIF_START_TIME-1){
        dut->i_arstnW = 0;
        dut->i_arstnR = 0;
    }
}

void simulation_eval(std::shared_ptr<Vasync_fifo> dut,VerilatedVcdC *m_trace, vluint64_t & ns)
{
    dut->eval();
    m_trace->dump(ns);
}

void simulation_tick_posedge(VerilatedVcdC *m_trace,char clk_source,std::shared_ptr<Vasync_fifo> dut, vluint64_t &ns)
{   
    if (clk_source == 'A'){
        dut->i_clkW = 1;
    } else {
        dut->i_clkR = 1;
    }
}

void simulation_tick_negedge(VerilatedVcdC *m_trace,char clk_source,std::shared_ptr<Vasync_fifo> dut, vluint64_t &ns)
{
    if (clk_source == 'A'){
        dut->i_clkW = 0;
    } else {
        dut->i_clkR = 0;
    }
}


int main(int argc, char** argv, char** env) {
    srand (time(NULL));
    Verilated::commandArgs(argc, argv);
    // Vasync_fifo *dut = new Vasync_fifo;
    std::shared_ptr<Vasync_fifo> dut(new Vasync_fifo);

    Verilated::traceEverOn(true);
    VerilatedVcdC *m_trace = new VerilatedVcdC;
    dut->trace(m_trace, 5);
    m_trace->open("waveform.vcd");

    InTx   *tx;
    int new_tx_ready = 1;

    // Here we create the driver, scoreboard, input and output monitor and coverage blocks
    std::unique_ptr<InDrv> drv(new InDrv(dut));
    std::shared_ptr<Scb> scb(new Scb());
    std::shared_ptr<InCoverage> inCoverage(new InCoverage());
    std::shared_ptr<OutCoverage> outCoverage(new OutCoverage());
    std::unique_ptr<InMon> inMon(new InMon(dut,scb,inCoverage));
    std::unique_ptr<OutMon> outMon(new OutMon(dut,scb,outCoverage));
    std::unique_ptr<Sequence> sequence(new Sequence(outCoverage));

    while (outCoverage->is_full_coverage() == false || outCoverage->is_full_coverage_full_empty() == false) {
    // while(sim_time < MAX_SIM_TIME*20) {
        // random reset 
        // 0-> all 0s
        // 1 -> all 1s
        // 2 -> all random
        Verilated::randReset(2); 
        dut_reset(dut,sim_time);     

        if (POSEDGE(sim_time, CLK_A_PERIOD, CLK_A_PHASE)) {
                simulation_tick_posedge(m_trace, 'A',dut,sim_time);
        }
        if (NEGEDGE(sim_time, CLK_A_PERIOD, CLK_A_PHASE)) {
                simulation_tick_negedge(m_trace, 'A',dut,sim_time);
        }
        
        if (POSEDGE(sim_time, CLK_B_PERIOD, CLK_B_PHASE)){
                simulation_tick_posedge(m_trace, 'B',dut,sim_time);
        }
        if (NEGEDGE(sim_time, CLK_B_PERIOD, CLK_B_PHASE)) {
                simulation_tick_negedge(m_trace, 'B',dut,sim_time);
        }
        simulation_eval(dut, m_trace, sim_time);


        if (sim_time >= VERIF_START_TIME) {
            // Generate a randomised transaction item 
            tx = sequence->genTx(new_tx_ready,POSEDGE(sim_time, CLK_A_PERIOD, CLK_A_PHASE),POSEDGE(sim_time, CLK_B_PERIOD, CLK_B_PHASE));
            // Pass the generated transaction item in the driver
            //to convert it to pin wiggles
            //operation similar to than of a connection between
            //a sequencer and a driver in a UVM tb
            drv->drive(tx,new_tx_ready,POSEDGE(sim_time, CLK_A_PERIOD, CLK_A_PHASE),POSEDGE(sim_time, CLK_B_PERIOD, CLK_B_PHASE));
            // Monitor the input interface
            // also writes recovered transaction to
            // input coverage and scoreboard
            inMon->monitor(POSEDGE(sim_time, CLK_A_PERIOD, CLK_A_PHASE));
            // Monitor the output interface
            // also writes recovered result (out transaction) to
            // output coverage and scoreboard 
            outMon->monitor(POSEDGE(sim_time, CLK_A_PERIOD, CLK_A_PHASE),POSEDGE(sim_time, CLK_B_PERIOD, CLK_B_PHASE));
        }
        sim_time++;
    }

    scb->checkPhase();

    Verilated::mkdir("logs");
    VerilatedCov::write("logs/coverage.dat");
    m_trace->close();  
    exit(EXIT_SUCCESS);
}
