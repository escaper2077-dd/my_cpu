.PHONY: all vcs clean cleanall verdi run help

# VCS编译选项
VCS_FLAGS = -full64 \
	-sverilog \
	-debug_access+all \
	-LDFLAGS -Wl,-no-pie \
	-timescale=1ps/1ps

# 文件定义
DATA_MEM = data_memory.v
CPU_RTL = pipelined_y86_cpu.v
PIPE_RTL = pipe_stage_fetch.v pipe_stage_decode.v pipe_stage_execute.v \
           pipe_stage_memory.v pipe_stage_writeback.v
PIPE_REG = pipe_reg_fd.v pipe_reg_de.v pipe_reg_em.v pipe_reg_mw.v
PIPE_CTRL = pipe_pc_logic.v pipe_control.v
TESTBENCH = pipelined_y86_comprehensive_tb.v

ALL_SRCS = $(DATA_MEM) $(CPU_RTL) $(PIPE_RTL) $(PIPE_REG) $(PIPE_CTRL) $(TESTBENCH)

# 输出目录和可执行文件
BUILD_DIR = ./build
SIMV = simv

# 主目标
all: help

help:
	@echo "Y86-64 Pipelined CPU - Makefile"
	@echo "========================================"
	@echo "Targets:"
	@echo "  vcs       - Compile with VCS"
	@echo "  run       - Run VCS simulation"
	@echo "  verdi     - Open Verdi waveform viewer"
	@echo "  clean     - Clean build artifacts"
	@echo "  cleanall  - Clean all generated files"

# VCS编译目标
vcs: $(SIMV)

$(SIMV): $(ALL_SRCS)
	@echo "Compiling pipelined Y86-64 CPU with VCS..."
	vcs $(VCS_FLAGS) -o $(SIMV) $(ALL_SRCS)
	@echo "VCS compilation successful: $(SIMV)"

# 运行仿真
run: vcs
	@echo "Running VCS simulation..."
	./$(SIMV)

# 运行并生成波形
run-wave: $(SIMV)
	@echo "Running simulation with waveform dump..."
	./$(SIMV) -vpd_file=pipeline.vpd

# Verdi波形查看
verdi:
	@if [ -f pipeline.vpd ]; then \
		verdi -vpd pipeline.vpd &; \
	elif [ -f rtl.fsdb ]; then \
		verdi -ssf rtl.fsdb &; \
	else \
		echo "No waveform file found. Run 'make run-wave' first."; \
	fi

# 清理编译文件
clean:
	@echo "Cleaning build artifacts..."
	rm -rf csrc *.daidir
	rm -rf *.log *.vpd *.fsdb* *.key ucli.key
	@echo "Clean complete"

# 完全清理
cleanall: clean
	@echo "Removing all generated files..."
	rm -rf $(BUILD_DIR)
	rm -f $(SIMV)
	rm -f *.vcd *.shm
	@echo "Cleanall complete"
