TOPLEVEL = async_fifo

RTL_DIR = $(PWD)

.PHONY:lint
lint: $(RTL_DIR)/$(TOPLEVEL).sv
	@verilator --lint-only $(RTL_DIR)/$(TOPLEVEL).sv
	@verible-verilog-lint $(RTL_DIR)/$(TOPLEVEL).sv
