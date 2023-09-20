TOPLEVEL = async_fifo
MODULE = tb_$(TOPLEVEL).cpp
RTL_DIR = ./../rtl/SystemVerilog


GENHTML = /usr/bin/genhtml
# If $VERILATOR_ROOT isn't in the environment, we assume it is part of a
# package install, and verilator is in your path. Otherwise find the
# binary relative to $VERILATOR_ROOT (such as when inside the git sources).
ifeq ($(VERILATOR_ROOT),)
VERILATOR = verilator
VERILATOR_COVERAGE = verilator_coverage
else
export VERILATOR_ROOT
VERILATOR = $(VERILATOR_ROOT)/bin/verilator
VERILATOR_COVERAGE = $(VERILATOR_ROOT)/bin/verilator_coverage
endif	

.PHONY:coverage
coverage: sim
	@echo "### Getting Line Coverage information ###"
	@$(VERILATOR_COVERAGE) --annotate logs/annotated --annotate-min 1 -write-info logs/merged.info logs/coverage.dat

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
	$(VERILATOR) --assert -DUSE_VERILATOR -Wno-fatal --build -j --coverage --trace --trace-coverage -Wall --trace --x-assign unique --x-initial unique -I$(RTL_DIR) -cc $(RTL_DIR)/$(TOPLEVEL).sv --exe tb_$(TOPLEVEL).cpp
	@touch .stamp.verilate

.PHONY:html_coverage
html_coverage: coverage
	@echo ""
	@echo "### Generating html Coverage analysis ###"
	@$(GENHTML) logs/merged.info --output-directory html

.PHONY:lint
lint:
	@$(VERILATOR) --lint-only $(RTL_DIR)/*.sv
	@verible-verilog-lint $(RTL_DIR)/*.sv

.PHONY: clean
clean:
	rm -rf .stamp.*;
	rm -rf ./obj_dir
	rm -rf waveform.vcd
	rm -rf logs
	rm -rf html
	rm -rf coverage.dat
