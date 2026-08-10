# 抄自example的makefile
ifneq ($(words $(CURDIR)),1)
  $(error Unsupported: GNU Make cannot build in directories containing spaces, build elsewhere: '$(CURDIR)')
endif

ifeq ($(VERILATOR_ROOT),)
  VERILATOR = verilator
else
  export VERILATOR_ROOT
  VERILATOR = $(VERILATOR_ROOT)/bin/verilator
endif

all:
	@echo "Write this Makefile by your self."

sim:
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	@echo "-- VERILATE & BUILD --------"
	$(VERILATOR) --trace-fst -cc --exe --build -j top.v sim_main.cpp
	@echo "-- RUN ---------------------"
	obj_dir/Vtop
	@echo "-- DONE --------------------"
include ../Makefile

