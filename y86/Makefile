.PHONY: all vcs iverilog clean run help

# VCS编译选项
VCS_FLAGS = -full64 -cpp g++-4.8 -cc gcc-4.8 -LDFLAGS -Wl,--no-as-needed \
	-sverilog \
	-debug_access+all \
	-kdb \
	-timescale=1ns/1ps

# 其他VCS编译选项（可选）
VCS_FLAGS_ALT = -pp -sverilog +v2k

# iverilog编译选项
IVERILOG_FLAGS = -g2009

# 文件定义
FETCH_RTL = fetch.v
FETCH_TB = fetch_tb.v
FETCH_TB_ENH = fetch_tb_enhanced.v

# 输出目录
SIM_DIR = ./sim
BUILD_DIR = ./build

# 编译目标
VCS_SIMV = $(BUILD_DIR)/simv
IVERILOG_EXE = $(BUILD_DIR)/fetch_test
IVERILOG_EXE_ENH = $(BUILD_DIR)/fetch_test_enhanced

# 主目标
all: help

help:
	@echo "Y86-64 Fetch Stage Testbench - Makefile"
	@echo "========================================"
	@echo "Targets:"
	@echo "  vcs              - Compile with VCS (if available)"
	@echo "  iverilog         - Compile with iverilog"
	@echo "  run-vcs          - Run VCS simulation"
	@echo "  run-iverilog     - Run iverilog simulation"
	@echo "  run-enhanced     - Run enhanced testbench (iverilog)"
	@echo "  clean            - Clean build artifacts"
	@echo "  cleanall         - Clean all generated files"

# VCS编译目标 - 标准配置
vcs: $(VCS_SIMV)

$(VCS_SIMV): filelist.f $(FETCH_RTL) $(FETCH_TB)
	@mkdir -p $(BUILD_DIR)
	@echo "Compiling with VCS (full configuration)..."
	vcs -full64 -cpp g++-4.8 -cc gcc-4.8 -LDFLAGS -Wl,--no-as-needed \
		-f filelist.f \
		-sverilog \
		-debug_access+all \
		-kdb \
		-timescale=1ns/1ps \
		-l $(BUILD_DIR)/com.log
	@echo "VCS compilation successful"

# VCS编译目标 - 简化配置
vcs-simple: $(VCS_SIMV)
	@mkdir -p $(BUILD_DIR)
	@echo "Compiling with VCS (simple)..."
	vcs $(VCS_FLAGS_ALT) -o $(VCS_SIMV) $(FETCH_RTL) $(FETCH_TB)
	@echo "VCS compilation successful: $(VCS_SIMV)"

# iverilog编译目标（基础testbench）
iverilog: $(IVERILOG_EXE)

$(IVERILOG_EXE): $(FETCH_RTL) $(FETCH_TB)
	@mkdir -p $(BUILD_DIR)
	@echo "Compiling with iverilog..."
	iverilog $(IVERILOG_FLAGS) -o $(IVERILOG_EXE) $(FETCH_RTL) $(FETCH_TB)
	@echo "iverilog compilation successful: $(IVERILOG_EXE)"

# iverilog编译目标（增强testbench）
iverilog-enhanced: $(IVERILOG_EXE_ENH)

$(IVERILOG_EXE_ENH): $(FETCH_RTL) $(FETCH_TB_ENH)
	@mkdir -p $(BUILD_DIR)
	@echo "Compiling enhanced testbench with iverilog..."
	iverilog $(IVERILOG_FLAGS) -o $(IVERILOG_EXE_ENH) $(FETCH_RTL) $(FETCH_TB_ENH)
	@echo "iverilog enhanced compilation successful: $(IVERILOG_EXE_ENH)"

# 运行VCS模拟
run-vcs: vcs
	@echo "Running VCS simulation..."
	@cd $(BUILD_DIR) && ./simv

# 运行iverilog模拟（基础）
run-iverilog: iverilog
	@echo "Running iverilog simulation..."
	vvp $(IVERILOG_EXE)

# 运行增强testbench（推荐）
run-enhanced: iverilog-enhanced
	@echo "Running enhanced testbench..."
	vvp $(IVERILOG_EXE_ENH)

# 快速编译和运行命令
compile: iverilog-enhanced
	@echo "Compilation complete"

simulate: run-enhanced
	@echo "Simulation complete"

# 清理编译文件（保留源代码）
clean:
	@echo "Cleaning build artifacts..."
	rm -rf csrc simv* *.lib *.lib++ nLint*
	rm -rf *.log *.vpd *.fsdb* *.key *log rtl.fsdb*
	rm -f $(BUILD_DIR)/*.o
	rm -f $(BUILD_DIR)/*.so
	@echo "Clean complete"

# 完全清理（包括编译输出）
cleanall: clean
	@echo "Removing all generated files..."
	rm -rf $(BUILD_DIR)
	rm -f *.vcd
	rm -f *.vpd
	rm -f *.shm
	@echo "Cleanall complete"

# Verdi波形查看
verdi:
	verdi -ssf rtl.fsdb

# 调试目标 - 生成VCD波形文件
debug-vcs: vcs
	@echo "Running VCS with waveform generation..."
	cd $(BUILD_DIR) && ./simv -gui

debug-iverilog: iverilog-enhanced
	@echo "Running iverilog with VCD output..."
	vvp $(IVERILOG_EXE_ENH) -vcd

# 快速运行（默认使用增强testbench）
quick:
	@iverilog -o /tmp/fetch_test fetch.v fetch_tb_enhanced.v && vvp /tmp/fetch_test

# 所有测试
test: run-enhanced
	@echo "All tests completed"

.PHONY: all help vcs iverilog iverilog-enhanced run-vcs run-iverilog run-enhanced clean cleanall debug-vcs debug-iverilog quick test compile simulate
