TOPLEVEL = async_fifo
MODULE = tb_$(TOPLEVEL).cpp
RTL_DIR = $(PWD)/../rtl/SystemVerilog

.PHONY:sim
sim: waveform.vcd

.PHONY:verilate
verilate: .stamp.verilate

.PHONY:build
build: obj_dir/Valu

.PHONY:waves
waves: waveform.vcd
	@echo
	@echo "### WAVES ###"
	gtkwave waveform.vcd 

waveform.vcd: ./obj_dir/V$(TOPLEVEL)
	@echo
	@echo "### SIMULATING ###"
	./obj_dir/V$(TOPLEVEL) +verilator+rand+reset+2 

./obj_dir/V$(TOPLEVEL): .stamp.verilate
	@echo
	@echo "### BUILDING SIM ###"
	make -C obj_dir -f V$(TOPLEVEL).mk V$(TOPLEVEL)

.stamp.verilate: $(RTL_DIR)/$(TOPLEVEL).sv tb_$(TOPLEVEL).cpp
	@echo
	@echo "### VERILATING ###"
	verilator -Wall --trace --x-assign unique --x-initial unique -I$(RTL_DIR) -cc $(RTL_DIR)/$(TOPLEVEL).sv --exe tb_$(TOPLEVEL).cpp
	@touch .stamp.verilate

.PHONY:lint
lint: $(RTL_DIR)/$(TOPLEVEL).sv
	@verilator --lint-only $(RTL_DIR)/$(TOPLEVEL).sv
	@verible-verilog-lint $(RTL_DIR)/$(TOPLEVEL).sv

.PHONY: clean
clean:
	rm -rf .stamp.*;
	rm -rf ./obj_dir
	rm -rf waveform.vcd
