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

# ---- 配置 ----
TOPNAME = top
INC_PATH ?=

VERILATOR_CFLAGS += -MMD --build -cc \
				-O3 --x-assign fast --x-initial fast --noassert --trace-fst

BUILD_DIR = ./build
OBJ_DIR = $(BUILD_DIR)/obj_dir
BIN = $(BUILD_DIR)/$(TOPNAME)

$(shell mkdir -p $(BUILD_DIR))

default: $(BIN)

# project source
VSRCS = $(shell find $(abspath ./vsrc) -name "*.v")
CSRCS = $(shell find $(abspath ./csrc) -name "*.c" -or -name "*.cc" -or -name "*.cpp")

# rules for verilator
INCFLAGS = $(addprefix -I, $(INC_PATH))
CXXFLAGS += $(INCFLAGS) -DTOP_NAME="\"V$(TOPNAME)\""

$(BIN): $(VSRCS) $(CSRCS)
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
	@$(BIN)
	@echo "-- DONE --------------------"

run: $(BIN)
	@$^

lint:
	$(VERILATOR) --lint-only $(VSRCS) \
		--top-module $(TOPNAME) $(addprefix -I, $(INC_PATH))

clean:
	rm -rf $(BUILD_DIR)

.PHONY: all clean run sim lint
include ../Makefile
