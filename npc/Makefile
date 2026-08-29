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
TOPNAME = top
NXDC_FILES = constr/top.nxdc
INC_PATH ?=

VERILATOR_CFLAGS += -MMD --build -cc \
				-O3 --x-assign fast --x-initial fast --noassert --trace-fst

# ---- 仿真模式选择: 默认 difftest, make BOARD=1 使用 NVBoard ----
BOARD ?= 0
ifeq ($(BOARD),1)
  MAIN_SRC = nvboard_main.cpp
  BIN = $(BUILD_DIR)/$(TOPNAME)-nvboard
else
  MAIN_SRC = main.cpp
  BIN = $(BUILD_DIR)/$(TOPNAME)
endif

BUILD_DIR = ./build
OBJ_DIR = $(BUILD_DIR)/obj_dir

# 待加载的程序镜像, 可通过 make sim IMG=xxx.bin 覆盖
IMG ?= $(abspath ../am-kernels/tests/cpu-tests/build/dummy-minirv-npc.bin)

$(shell mkdir -p $(BUILD_DIR))

default: $(BIN)

# constraint file
SRC_AUTO_BIND = $(abspath $(BUILD_DIR)/auto_bind.cpp)
$(SRC_AUTO_BIND): $(NXDC_FILES)
	python3 $(NVBOARD_HOME)/scripts/auto_pin_bind.py $^ $@

# project source
VSRCS = $(shell find $(abspath ./vsrc) -name "*.v")
CSRCS = $(shell find $(abspath ./csrc) -name "*.c" -or -name "*.cc" -or -name "*.cpp")
# 两个 main 不能同时编译, 只保留当前模式选中的那个
CSRCS := $(filter-out %main.cpp, $(CSRCS))
CSRCS += $(abspath ./csrc)/$(MAIN_SRC)
CSRCS += $(SRC_AUTO_BIND)

# rules for NVBoard
include $(NVBOARD_HOME)/scripts/nvboard.mk

# rules for verilator
INCFLAGS = $(addprefix -I, $(INC_PATH))
CXXFLAGS += $(INCFLAGS) -DTOP_NAME="\"V$(TOPNAME)\""

$(BIN): $(VSRCS) $(CSRCS) $(NVBOARD_ARCHIVE)
	@rm -rf $(OBJ_DIR)
	$(VERILATOR) $(VERILATOR_CFLAGS) \
		--top-module $(TOPNAME) $^ \
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
		--top-module $(TOPNAME) $(addprefix -I, $(INC_PATH))

clean:
	rm -rf $(BUILD_DIR)

.PHONY: all clean run sim lint
include ../Makefile
