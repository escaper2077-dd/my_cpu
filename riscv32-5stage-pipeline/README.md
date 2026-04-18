# RISC-V RV32I 五级流水线 CPU

## 项目概述

这是一个基于 RISC-V RV32I 指令集的五级流水线 CPU 实现，由单周期 CPU 改进而来。

## 流水线架构

### 五个流水线阶段

1. **IF (Instruction Fetch)** - 取指阶段
   - 从内存读取指令
   - PC 管理和更新
   - 模块：`fetch_pipe.v`

2. **ID (Instruction Decode)** - 译码阶段
   - 指令解码
   - 寄存器文件读取
   - 立即数生成
   - 模块：`decode_pipe.v`

3. **EX (Execute)** - 执行阶段
   - ALU 运算
   - 分支条件判断
   - 分支目标计算
   - 数据转发处理
   - 模块：`execute_pipe.v`

4. **MEM (Memory Access)** - 访存阶段
   - 内存读写操作
   - 模块：`memory_access_pipe.v`

5. **WB (Write Back)** - 写回阶段
   - 寄存器写回
   - 写回数据选择
   - 模块：`write_back_pipe.v`

### 流水线寄存器

- **IF/ID** - IF 和 ID 阶段之间
- **ID/EX** - ID 和 EX 阶段之间
- **EX/MEM** - EX 和 MEM 阶段之间
- **MEM/WB** - MEM 和 WB 阶段之间

所有流水线寄存器定义在 `pipeline_regs.v` 中。

## 冒险处理

### 1. 数据冒险 (Data Hazards)

**数据转发 (Forwarding/Bypassing)**
- EX 阶段转发：从 EX/MEM 寄存器转发到 EX 阶段
- MEM 阶段转发：从 MEM/WB 寄存器转发到 EX 阶段
- WB 阶段转发：从 WB 阶段转发到 EX 阶段

**Load-Use 冒险**
- 检测：当 EX 阶段是 LOAD 指令，且其目标寄存器是 ID 阶段的源寄存器
- 处理：暂停流水线一个周期 (stall)

### 2. 控制冒险 (Control Hazards)

**分支/跳转处理**
- 分支在 EX 阶段确定
- 分支预测：默认预测不跳转 (predict not taken)
- 分支错误：冲刷 IF/ID 和 ID/EX 寄存器

**支持的控制指令**
- JAL, JALR：无条件跳转
- BEQ, BNE, BLT, BGE, BLTU, BGEU：条件分支

### 冒险检测单元

模块 `hazard_unit.v` 负责：
- 检测数据冒险和控制冒险
- 生成转发控制信号
- 生成暂停和冲刷信号

## 文件结构

```
riscv32-5stage-pipeline/
├── top_cpu.v              # 顶层模块
├── pipeline_regs.v        # 流水线寄存器 (IF/ID, ID/EX, EX/MEM, MEM/WB)
├── hazard_unit.v          # 冒险检测与转发单元
├── fetch_pipe.v           # IF 阶段
├── decode_pipe.v          # ID 阶段
├── execute_pipe.v         # EX 阶段
├── memory_access_pipe.v   # MEM 阶段
├── write_back_pipe.v      # WB 阶段
├── filelist.f             # 文件列表
├── Makefile               # 编译脚本
└── README.md              # 本文档
```

## 编译与运行

### 使用 VCS

```bash
# 编译
make vcs

# 运行仿真
make run

# 查看波形
make verdi

# 清理
make clean
make cleanall
```

## 设计特点

1. **完整的 RV32I 支持**
   - 所有算术/逻辑指令
   - 所有分支/跳转指令
   - 所有 Load/Store 指令

2. **高效的冒险处理**
   - 数据转发减少暂停
   - Load-Use 冒险自动检测
   - 控制冒险快速恢复

3. **符合测试框架**
   - DPI-C 接口兼容
   - commit 信号正确输出
   - 寄存器文件可访问

4. **可扩展性**
   - 模块化设计
   - 清晰的接口定义
   - 易于添加新功能

## 性能分析

### CPI (Cycles Per Instruction)

理想情况：CPI = 1.0

实际 CPI 受以下因素影响：
- Load-Use 冒险：+1 cycle per hazard
- 分支预测错误：+2 cycles per misprediction

### 相比单周期 CPU

**优势**
- 更高的时钟频率（每个阶段逻辑更简单）
- 更高的吞吐量（理想情况下每周期完成一条指令）

**劣势**
- 更复杂的控制逻辑
- 需要处理各种冒险
- 分支延迟增加

## 测试

使用与单周期 CPU 相同的测试框架：
- DPI-C 接口进行取指和访存
- 寄存器文件通过 DPI-C 暴露
- commit 信号用于验证

## 作者

escaper - RISC-V 五级流水线 CPU 实现

基于单周期 CPU 改进而来。

## 参考资料

- RISC-V Instruction Set Manual
- Computer Organization and Design (Patterson & Hennessy)
- 原单周期 CPU 实现
