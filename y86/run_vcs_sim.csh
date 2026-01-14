#!/bin/csh
# VCS 编译和仿真脚本
# 适用于 Synopsys VCS 环境

set DESIGN_DIR = `pwd`
set BUILD_DIR = ${DESIGN_DIR}/build_vcs
set SIM_DIR = ${DESIGN_DIR}/sim_results

# 创建目录
mkdir -p ${BUILD_DIR}
mkdir -p ${SIM_DIR}

echo "=========================================="
echo "Y86-64 Fetch Stage - VCS Simulation"
echo "=========================================="
echo "Design directory: ${DESIGN_DIR}"
echo "Build directory: ${BUILD_DIR}"
echo ""

# 检查VCS是否可用
if (! `which vcs >& /dev/null`) then
    echo "ERROR: VCS not found in PATH"
    echo "Please source VCS environment setup script"
    exit 1
endif

echo "Using VCS version:"
vcs -version | head -1
echo ""

# VCS 编译选项
set VCS_COMPILE_FLAGS = "-pp -sverilog +v2k"
set WAVE_FLAGS = "+access+r +define+DUMP_WAVE"

# 编译
echo "Compiling with VCS..."
cd ${BUILD_DIR}
vcs ${VCS_COMPILE_FLAGS} \
    -o simv \
    ${DESIGN_DIR}/fetch.v \
    ${DESIGN_DIR}/fetch_tb_enhanced.v

if ($status != 0) then
    echo "ERROR: VCS compilation failed"
    exit 1
endif

echo "✓ Compilation successful"
echo ""

# 运行仿真
echo "Running simulation..."
./simv

# 运行后处理
echo ""
echo "=========================================="
echo "Simulation complete"
echo "Build artifacts in: ${BUILD_DIR}"

# 可选：生成波形
# echo ""
# echo "Generating waveforms..."
# dve -vpd ${SIM_DIR}/dump.vpd &

cd ${DESIGN_DIR}
