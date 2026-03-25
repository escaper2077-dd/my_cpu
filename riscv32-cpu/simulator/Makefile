TOPNAME :=top_cpu
CPU_DIR=$(CPU_HOME)/IP/rv32-single-cycle-cpu-akun
SRC_DIR:=$(SIM_HOME)/src  

#simulator的参数
override ARGS ?= --log=$(SIM_HOME)/log/npc-log.txt
override ARGS += --diff=$(SIM_HOME)/diff/riscv32-spike-so


#文件目录设置
BUILD_DIR := $(SIM_HOME)/build
OBJ_DIR := $(BUILD_DIR)/obj_dir
INC_DIR := $(SIM_HOME)/include
WAVE_DIR:= $(SIM_HOME)/gtkwave

#文件
BIN := $(BUILD_DIR)/$(TOPNAME)
TOP_V := $(CPU_DIR)/$(TOPNAME).v


# --- 编译器设置 ---
VERILATOR = verilator
VERILATOR_CFLAGS += -MMD --build -j 8 -trace-fst -cc -O0
VERILATOR_CFLAGS += --x-assign fast --x-initial fast --noassert
VERILATOR_CFLAGS += -I$(CPU_DIR) --top-module $(TOPNAME) --prefix npc

INC_PATH = $(INC_DIR) $(INC_DIR)/utils $(INC_DIR)/riscv $(INC_DIR)/difftest $(INC_DIR)/generated
INCFLAGS := $(addprefix -I, $(INC_PATH))


LDFLAGS += -lreadline -lhistory -ldl -pie $(shell llvm-config --libs)
CXXFLAGS += $(INCFLAGS) -DTOP_NAME=npc -fpermissive

ALL_V = $(shell find $(abspath $(CPU_DIR)) -name "*.v" -o -name "*.sv")
VSRCS = $(filter-out $(TOP_V), $(ALL_V))
CSRCS = $(shell find $(abspath $(SRC_DIR)) -name "*.c" -o -name "*.cpp" -o -name "*.cc")

# --- 颜色与图标定义 ---
BLUE   = \033[1;34m
GREEN  = \033[1;32m
PURPLE = \033[1;35m
CYAN   = \033[1;36m
YELLOW = \033[1;33m
RESET  = \033[0m
ROCKET = 🚀
CHECK  = ✅
BUILD  = 🛠️
RUN    = 🏃

# --- 构建规则 ---
PREPROCESS_STAMP = $(BUILD_DIR)/.preprocess_done
$(BIN): $(PREPROCESS_STAMP) $(VSRCS) $(CSRCS) $(AUTOCONF_H)
	@echo "$(BLUE)$(BUILD) [1/2] Preparing build directory...$(RESET)"
	@mkdir -p $(BUILD_DIR)
	@rm -rf $(OBJ_DIR)
	@echo "$(PURPLE)$(ROCKET) [2/2] Starting Verilator compilation...$(RESET)"

	@$(VERILATOR) $(VERILATOR_CFLAGS) $(TOP_V) $(VSRCS) $(CSRCS) \
		$(addprefix -CFLAGS , $(CXXFLAGS)) \
		$(addprefix -LDFLAGS , $(LDFLAGS)) \
		--Mdir $(OBJ_DIR) --exe -o $(abspath $(BIN))
	@echo "$(GREEN)$(CHECK) Build successful! Binary: $(BIN)$(RESET)"

$(PREPROCESS_STAMP): $(TOP_V) scripts/verilog.py
	@mkdir -p $(BUILD_DIR)
#	@python3 scripts/verilog.py $(TOP_V)
	@touch $@  

run: $(BIN)
	@echo "$(CYAN)$(RUN) Launching simulation...$(RESET)"
	@$(BIN) $(ARGS) $(IMAGE)

sim:
	@echo "$(BLUE)🌊 Opening GTKWave...$(RESET)"
	@gtkwave $(WAVE_DIR)/waveform.fst $(WAVE_DIR)/waveform.view

clean:
	@echo "$(YELLOW)🧹 Cleaning up build artifacts...$(RESET)"
	@rm -rf $(BUILD_DIR)
	@rm -f $(AUTOCONF_H)
	@rm -rf $(WAVE_DIR)/waveform.fst
	@echo "$(GREEN)$(CHECK) Clean done.$(RESET)"

#menuconfig
-include $(SIM_HOME)/include/config/auto.conf
-include $(SIM_HOME)/include/config/auto.conf.cmd
include $(SIM_HOME)/scripts/config.mk

default: $(BIN)
.PHONY: default all clean run sim menuconfig syncconfig preprocess