TOPNAME :=top_cpu

# ==================== CPU 选择 ====================
# 用法: make CPU=pipeline   (默认，五级流水线)
#        make CPU=single     (单周期)
#        make CPU=akun       (akun 的单周期)
#        make CPU=old-pipe   (旧流水线, 调试用)
CPU ?= pipeline
ifeq ($(CPU),single)
  CPU_DIR=$(CPU_HOME)/IP/rv32-single-cycle-cpu-escaper
else ifeq ($(CPU),akun)
  CPU_DIR=$(CPU_HOME)/IP/rv32-single-cycle-cpu-akun
else ifeq ($(CPU),old-pipe)
  CPU_DIR=$(CPU_HOME)/IP/rv32-pipeline-cpu-escaper
else
  CPU_DIR=$(CPU_HOME)/IP/rv32-pipeline-cpu-new
endif

SRC_DIR:=$(SIM_HOME)/src  

#simulator的参数
override ARGS ?= --log=$(SIM_HOME)/log/npc-log.txt
override ARGS += --diff=$(SIM_HOME)/diff/riscv32-spike-so


#文件目录设置
BUILD_DIR := $(SIM_HOME)/build/$(CPU)
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
	@echo "$(BLUE)$(BUILD) [1/2] Building [$(CPU)] from $(CPU_DIR)...$(RESET)"
	@mkdir -p $(BUILD_DIR)
	@rm -rf $(OBJ_DIR)
	@echo "$(PURPLE)$(ROCKET) [2/2] Starting Verilator compilation...$(RESET)"

	@$(VERILATOR) $(VERILATOR_CFLAGS) $(TOP_V) $(VSRCS) $(CSRCS) \
		$(addprefix -CFLAGS , $(CXXFLAGS)) \
		$(addprefix -LDFLAGS , $(LDFLAGS)) \
		--Mdir $(OBJ_DIR) --exe -o $(abspath $(BIN))
	@echo "$(GREEN)$(CHECK) Build [$(CPU)] successful! Binary: $(BIN)$(RESET)"

$(PREPROCESS_STAMP): $(TOP_V) scripts/verilog.py
	@mkdir -p $(BUILD_DIR)
#	@python3 scripts/verilog.py $(TOP_V)
	@touch $@  

run: $(BIN)
	@echo "$(CYAN)$(RUN) Launching [$(CPU)] simulation...$(RESET)"
	@$(BIN) $(ARGS) $(IMAGE)

# ==================== 测试目标 ====================

# 快速单测: make test T=add
test: $(BIN)
	@echo "$(CYAN)$(RUN) Running test [$(T)] on [$(CPU)]...$(RESET)"
	@$(BIN) $(ARGS) $(TEST_HOME)/cpu-tests/build/$(T)-riscv32-npc.bin

# 全量 softtest: make softtest
softtest: $(BIN)
	@echo "$(CYAN)🧪 Running ALL cpu-tests on [$(CPU)]...$(RESET)"
	@pass=0; fail=0; total=0; \
	for bin in $(TEST_HOME)/cpu-tests/build/*-riscv32-npc.bin; do \
		name=$$(basename "$$bin" -riscv32-npc.bin); \
		total=$$((total+1)); \
		if $(abspath $(BIN)) $(ARGS) "$$bin" 2>&1 | grep -q "hit ebreak"; then \
			printf "  $(GREEN)[PASS]$(RESET) %s\n" "$$name"; \
			pass=$$((pass+1)); \
		else \
			printf "  $(YELLOW)[FAIL]$(RESET) %s\n" "$$name"; \
			fail=$$((fail+1)); \
		fi; \
	done; \
	echo ""; \
	echo "$(BLUE)===== Results: $$pass/$$total passed, $$fail failed =====$(RESET)"

# AM 测试: make amtest  (需要先 cd cpu-tests && make ARCH=riscv32-npc 编译)
amtest: $(BIN)
	@echo "$(CYAN)🧪 Running riscv-tests-am on [$(CPU)]...$(RESET)"
	@cd $(CPU_HOME)/riscv-tests-am && make run ARCH=riscv32-npc

# ARCH 测试: make archtest
archtest: $(BIN)
	@echo "$(CYAN)🧪 Running riscv-arch-test-am on [$(CPU)]...$(RESET)"
	@cd $(CPU_HOME)/riscv-arch-test-am && make run ARCH=riscv32-npc

# CoreMark
coremark: $(BIN)
	@echo "$(CYAN)🔥 Running CoreMark on [$(CPU)]...$(RESET)"
	@$(BIN) $(ARGS) $(TEST_HOME)/coremark/build/coremark-riscv32-npc.bin

# 波形查看
sim:
	@echo "$(BLUE)🌊 Opening GTKWave...$(RESET)"
	@gtkwave $(WAVE_DIR)/waveform.fst $(WAVE_DIR)/waveform.view

# 显示当前配置
info:
	@echo "$(BLUE)CPU     = $(CPU)$(RESET)"
	@echo "$(BLUE)CPU_DIR = $(CPU_DIR)$(RESET)"
	@echo "$(BLUE)BIN     = $(BIN)$(RESET)"

clean:
	@echo "$(YELLOW)🧹 Cleaning [$(CPU)] build artifacts...$(RESET)"
	@rm -rf $(BUILD_DIR)
	@rm -f $(AUTOCONF_H)
	@rm -rf $(WAVE_DIR)/waveform.fst
	@echo "$(GREEN)$(CHECK) Clean done.$(RESET)"

cleanall:
	@echo "$(YELLOW)🧹 Cleaning ALL build artifacts...$(RESET)"
	@rm -rf $(SIM_HOME)/build
	@rm -f $(AUTOCONF_H)
	@rm -rf $(WAVE_DIR)/waveform.fst
	@echo "$(GREEN)$(CHECK) Clean all done.$(RESET)"

#menuconfig
-include $(SIM_HOME)/include/config/auto.conf
-include $(SIM_HOME)/include/config/auto.conf.cmd
include $(SIM_HOME)/scripts/config.mk

default: $(BIN)
.PHONY: default all clean cleanall run sim menuconfig syncconfig preprocess
.PHONY: test softtest amtest archtest coremark info
