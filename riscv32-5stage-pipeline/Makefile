.PHONY: all vcs run clean cleanall verdi help

VCS_FLAGS = -full64 -cpp g++-4.8 -cc gcc-4.8 -LDFLAGS -Wl,--no-as-needed \
	-sverilog \
	-debug_access+all \
	-kdb \
	-timescale=1ns/1ps

BUILD_DIR = ./build

FILELIST_SRCS := $(shell awk '!/^[[:space:]]*($|#|\/\/)/{print}' filelist.f)

VCS_SIMV = simv

all: help

help:
	@echo "RISC-V RV32I 5-Stage Pipeline CPU - Makefile"
	@echo "============================================="
	@echo "Targets:"
	@echo "  vcs       - Compile with VCS"
	@echo "  run       - Run VCS simulation"
	@echo "  verdi     - Open Verdi waveform viewer"
	@echo "  clean     - Clean build artifacts"
	@echo "  cleanall  - Clean all generated files"

vcs: $(VCS_SIMV)

$(VCS_SIMV): filelist.f $(FILELIST_SRCS)
	@echo "Compiling 5-stage pipeline CPU with VCS..."
	vcs -full64 -cpp g++-4.8 -cc gcc-4.8 -LDFLAGS -Wl,--no-as-needed \
		-f filelist.f \
		-sverilog \
		-debug_access+all \
		-kdb \
		-timescale=1ns/1ps \
		-l com.log
	@echo "VCS compilation successful"

run: vcs
	@echo "Running VCS simulation..."
	./simv -l simv.log

verdi:
	verdi -ssf rtl.fsdb

clean:
	@echo "Cleaning build artifacts..."
	rm -rf csrc simv* *.lib *.lib++ nLint*
	rm -rf *.log *.vpd *.fsdb* *.key *log rtl.fsdb*
	rm -f $(BUILD_DIR)/*.o
	rm -f $(BUILD_DIR)/*.so
	@echo "Clean complete"

cleanall: clean
	@echo "Removing all generated files..."
	rm -rf $(BUILD_DIR)
	rm -f *.vcd
	rm -f *.vpd
	rm -f *.shm
	@echo "Cleanall complete"
