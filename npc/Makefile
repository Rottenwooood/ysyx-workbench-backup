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

# ---- NVBoard 相关配置 ----
NXDC_FILES = constr/top.nxdc
INC_PATH ?=

# ---- ysyxSoC 外设 ----
PERIP_DIR = ../ysyxSoC/perip
PERIP_SRCS = $(shell find $(abspath $(PERIP_DIR)) -name "*.v" -o -name "*.sv")
INC_PATH += $(abspath ../ysyxSoC/perip/uart16550/rtl) $(abspath ../ysyxSoC/perip/spi/rtl)

VERILATOR_CFLAGS += -MMD --build -cc \
				-O3 --x-assign fast --x-initial fast --noassert --trace-fst \
				--timescale "1ns/1ns" --no-timing \
				-D__VERILOG__ -DPDK_BEHAV -D__UART_TO_CONSOLE__ \
				-Wno-TIMESCALEMOD -Wno-PINMISSING

# ---- 仿真模式: 默认 ysyxSoC(SimTop), make DIFFTEST=1 独立CPU仿真, make BOARD=1 NVBoard ----
BOARD ?= 0
DIFFTEST ?= 0
ifeq ($(BOARD),1)
  TOPNAME = top
  MAIN_SRC = nvboard_main.cpp
  BIN = $(BUILD_DIR)/$(TOPNAME)-nvboard
else ifeq ($(DIFFTEST),1)
  TOPNAME = top
  MAIN_SRC = main.cpp
  BIN = $(BUILD_DIR)/$(TOPNAME)
else
  TOPNAME = SimTop
  MAIN_SRC = soc_main.cpp
  BIN = $(BUILD_DIR)/$(TOPNAME)
endif

BUILD_DIR = ./build
OBJ_DIR = $(BUILD_DIR)/obj_dir

# 待加载的程序镜像, 可通过 make sim IMG=xxx.bin 覆盖
ifeq ($(BOARD),1)
  IMG ?= $(abspath ../am-kernels/tests/cpu-tests/build/dummy-minirv-npc.bin)
else ifeq ($(DIFFTEST),1)
  IMG ?= $(abspath ../am-kernels/tests/cpu-tests/build/dummy-minirv-npc.bin)
else
  IMG ?= $(abspath ../ysyxSoC/ready-to-run/minirv/hello-minirv-ysyxsoc.bin)
endif

$(shell mkdir -p $(BUILD_DIR))

default: $(BIN)

# constraint file
SRC_AUTO_BIND = $(abspath $(BUILD_DIR)/auto_bind.cpp)
$(SRC_AUTO_BIND): $(NXDC_FILES)
	python3 $(NVBOARD_HOME)/scripts/auto_pin_bind.py $^ $@

# project source
VSRCS = $(shell find $(abspath ./vsrc) -name "*.v") $(PERIP_SRCS) $(abspath ../ysyxSoC/ready-to-run/minirv/ElaborateTop.v)
CSRCS = $(shell find $(abspath ./csrc) -name "*.c" -or -name "*.cc" -or -name "*.cpp")
# 多个 main 不能同时编译, 只保留当前模式选中的那个
CSRCS := $(filter-out %main.cpp %minirvEMU.cpp, $(CSRCS))
CSRCS += $(abspath ./csrc)/$(MAIN_SRC)
ifeq ($(DIFFTEST),1)
CSRCS += $(abspath ./csrc)/minirvEMU.cpp
endif
ifeq ($(BOARD),1)
CSRCS += $(SRC_AUTO_BIND)
endif

# rules for NVBoard
include $(NVBOARD_HOME)/scripts/nvboard.mk

# rules for verilator
INCFLAGS = $(addprefix -I, $(INC_PATH))
CXXFLAGS += $(INCFLAGS) -DTOP_NAME="\"V$(TOPNAME)\""

$(BIN): $(VSRCS) $(CSRCS) $(NVBOARD_ARCHIVE)
	@rm -rf $(OBJ_DIR)
	$(VERILATOR) $(VERILATOR_CFLAGS) \
		--top-module $(TOPNAME) $^ \
		$(addprefix -I, $(INC_PATH)) \
		$(addprefix -CFLAGS , $(CXXFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS)) \
		--Mdir $(OBJ_DIR) --exe -o $(abspath $(BIN))

default: $(BIN)

all: default

sim:
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	@echo "-- VERILATE & BUILD --------"
	$(MAKE) $(BIN)
	@echo "-- RUN ---------------------"
	@$(BIN) $(IMG)
	@echo "-- DONE --------------------"

run: $(BIN)
	@$^ $(IMG)

lint:
	$(VERILATOR) --lint-only $(VSRCS) \
		--top-module $(TOPNAME) $(addprefix -I, $(INC_PATH)) -Wno-TIMESCALEMOD

clean:
	rm -rf $(BUILD_DIR)

.PHONY: all clean run sim lint
include ../Makefile
