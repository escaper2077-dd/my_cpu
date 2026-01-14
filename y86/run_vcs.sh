#!/bin/bash

# Y86-64 Fetch Stage - VCS/iverilog 运行脚本

set -e  # 任何错误就退出

DESIGN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${DESIGN_DIR}/build"
SIM_DIR="${DESIGN_DIR}/sim_results"

# 创建必要的目录
mkdir -p "${BUILD_DIR}"
mkdir -p "${SIM_DIR}"

echo "=========================================="
echo "Y86-64 Fetch Stage Simulation"
echo "=========================================="
echo "Design directory: ${DESIGN_DIR}"
echo "Build directory: ${BUILD_DIR}"
echo ""

# 检查命令行参数
TOOL="${1:-auto}"
TESTBENCH="${2:-enhanced}"

case "${TOOL}" in
    vcs|VCS)
        # VCS编译和仿真
        if ! command -v vcs &> /dev/null; then
            echo "ERROR: VCS not found in PATH"
            echo "Please source VCS environment setup"
            exit 1
        fi
        
        echo "Using Synopsys VCS"
        echo "$(vcs -version | head -1)"
        echo ""
        
        echo "Compiling with VCS..."
        cd "${BUILD_DIR}"
        
        if [ "${TESTBENCH}" = "basic" ]; then
            vcs -pp -sverilog +v2k \
                -o simv \
                "${DESIGN_DIR}/fetch.v" \
                "${DESIGN_DIR}/fetch_tb.v"
            SIMV_ARGS=""
        else
            vcs -pp -sverilog +v2k \
                -o simv \
                "${DESIGN_DIR}/fetch.v" \
                "${DESIGN_DIR}/fetch_tb_enhanced.v"
            SIMV_ARGS=""
        fi
        
        if [ $? -ne 0 ]; then
            echo "ERROR: VCS compilation failed"
            exit 1
        fi
        
        echo "✓ Compilation successful"
        echo ""
        echo "Running simulation..."
        ./simv ${SIMV_ARGS}
        ;;
        
    iverilog|ivl)
        # iverilog编译和仿真
        if ! command -v iverilog &> /dev/null; then
            echo "ERROR: iverilog not found"
            exit 1
        fi
        
        echo "Using iverilog/vvp"
        echo ""
        
        echo "Compiling with iverilog..."
        
        if [ "${TESTBENCH}" = "basic" ]; then
            iverilog -g2009 \
                -o "${BUILD_DIR}/fetch_test" \
                "${DESIGN_DIR}/fetch.v" \
                "${DESIGN_DIR}/fetch_tb.v"
            EXECUTABLE="${BUILD_DIR}/fetch_test"
        else
            iverilog -g2009 \
                -o "${BUILD_DIR}/fetch_test_enhanced" \
                "${DESIGN_DIR}/fetch.v" \
                "${DESIGN_DIR}/fetch_tb_enhanced.v"
            EXECUTABLE="${BUILD_DIR}/fetch_test_enhanced"
        fi
        
        if [ $? -ne 0 ]; then
            echo "ERROR: iverilog compilation failed"
            exit 1
        fi
        
        echo "✓ Compilation successful"
        echo ""
        echo "Running simulation..."
        vvp "${EXECUTABLE}"
        ;;
        
    auto)
        # 自动选择可用的工具
        if command -v vcs &> /dev/null; then
            echo "VCS found, using VCS"
            "$0" vcs "${TESTBENCH}"
        elif command -v iverilog &> /dev/null; then
            echo "VCS not found, using iverilog"
            "$0" iverilog "${TESTBENCH}"
        else
            echo "ERROR: Neither VCS nor iverilog found"
            exit 1
        fi
        ;;
        
    *)
        echo "Usage: $0 [vcs|iverilog|auto] [basic|enhanced]"
        echo ""
        echo "Examples:"
        echo "  $0 vcs basic           # VCS + 基础testbench"
        echo "  $0 vcs enhanced        # VCS + 增强testbench (默认)"
        echo "  $0 iverilog enhanced   # iverilog + 增强testbench"
        echo "  $0 auto                # 自动选择工具"
        exit 1
        ;;
esac

echo ""
echo "=========================================="
echo "Simulation complete"
cd "${DESIGN_DIR}"
