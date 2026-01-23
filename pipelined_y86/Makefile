# Makefile for Pipelined Y86 CPU Simulation

# VCS编译器
VCS = vcs
VCSFLAGS = -full64 -sverilog -debug_access+all -timescale=1ps/1ps -LDFLAGS -Wl,-no-pie

# Verilog源文件
SOURCES = pipelined_y86_cpu.v \
          pipe_fetch.v \
          pipe_decode.v \
          pipe_execute.v \
          pipe_memory.v \
          pipe_writeback.v \
          pipe_pc_select.v \
          if_id_reg.v \
          id_ex_reg.v \
          ex_mem_reg.v \
          mem_wb_reg.v \
          hazard_control.v \
          pipelined_y86_cpu_tb.v

# 编译目标
SIMV = simv

# 默认目标
all: compile

# 编译
compile: $(SOURCES)
	$(VCS) $(VCSFLAGS) $(SOURCES) -o $(SIMV)

# VCS编译（别名）
vcs: compile

# 运行仿真
run: compile
	./$(SIMV)

# 使用DVE查看波形
dve:
	dve -vpd vcdplus.vpd &

# 清理
clean:
	rm -rf $(SIMV) csrc simv.daidir ucli.key *.vcd *.vpd DVEfiles

# 帮助
help:
	@echo "Makefile for Pipelined Y86 CPU"
	@echo ""
	@echo "Targets:"
	@echo "  make           - 编译仿真"
	@echo "  make compile   - 编译仿真"
	@echo "  make vcs       - 编译仿真（同compile）"
	@echo "  make run       - 编译并运行仿真"
	@echo "  make dve       - 使用DVE查看波形"
	@echo "  make clean     - 清理生成的文件"
	@echo "  make help      - 显示此帮助信息"

.PHONY: all compile vcs run dve clean help
