.PHONY: all vcs clean cleanall verdi help

# VCS编译选项
VCS_FLAGS = -full64 -cpp g++-4.8 -cc gcc-4.8 -LDFLAGS -Wl,--no-as-needed \
	-sverilog \
	-debug_access+all \
	-kdb \
	-timescale=1ns/1ps

# 文件定义
FETCH_RTL = fetch.v
FETCH_TB = fetch_tb.v

# 输出目录
BUILD_DIR = ./build

# 编译目标
VCS_SIMV = $(BUILD_DIR)/simv

# 主目标
all: help

help:
	@echo "Y86-64 Fetch Stage Testbench - Makefile"
	@echo "========================================"
	@echo "Targets:"
	@echo "  vcs       - Compile with VCS"
	@echo "  run       - Run VCS simulation"
	@echo "  verdi     - Open Verdi waveform viewer"
	@echo "  clean     - Clean build artifacts"
	@echo "  cleanall  - Clean all generated files"

# VCS编译目标
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

# 运行VCS模拟
run: vcs
	@echo "Running VCS simulation..."
	@cd $(BUILD_DIR) && ./simv

# Verdi波形查看
verdi:
	verdi -ssf rtl.fsdb

# 清理编译文件
clean:
	@echo "Cleaning build artifacts..."
	rm -rf csrc simv* *.lib *.lib++ nLint*
	rm -rf *.log *.vpd *.fsdb* *.key *log rtl.fsdb*
	rm -f $(BUILD_DIR)/*.o
	rm -f $(BUILD_DIR)/*.so
	@echo "Clean complete"

# 完全清理
cleanall: clean
	@echo "Removing all generated files..."
	rm -rf $(BUILD_DIR)
	rm -f *.vcd
	rm -f *.vpd
	rm -f *.shm
	@echo "Cleanall complete"
