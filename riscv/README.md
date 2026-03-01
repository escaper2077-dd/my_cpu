# RISC-V 单周期 CPU (RV32I)

## 概述

基于 RV32I 指令集的单周期 CPU 实现，参照 Y86 单周期架构设计，支持全部 **40 条指令**。

## 支持的指令 (RV32I - 40 条)

| 类型 | 指令 | 数量 |
|------|------|------|
| R-type | ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND | 10 |
| I-type ALU | ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI | 9 |
| Load | LB, LH, LW, LBU, LHU | 5 |
| Store | SB, SH, SW | 3 |
| Branch | BEQ, BNE, BLT, BGE, BLTU, BGEU | 6 |
| U-type | LUI, AUIPC | 2 |
| Jump | JAL, JALR | 2 |
| System | FENCE, ECALL, EBREAK | 3 |

## 模块结构

```
riscv_cpu (顶层)
├── fetch          - 取指阶段 (指令内存 4096B, 立即数生成, 指令解码)
├── decode         - 译码/寄存器文件 (32×32-bit, 组合读 + 时序写回)
├── execute        - 执行阶段 (ALU, 分支条件判断)
├── memory_access  - 访存阶段 (实例化 data_memory)
│   └── data_memory  - 数据内存 (4096B, 支持字节/半字/字访问)
├── write_back     - 写回阶段 (写回数据选择, 状态判断)
│   └── stat         - CPU 状态模块
└── pc_update      - PC 更新 (PC+4 / 分支 / JAL / JALR)
```

## 文件列表

| 文件 | 说明 |
|------|------|
| `fetch.v` | 取指阶段：指令内存、指令字段拆分、立即数生成 |
| `decode.v` | 译码阶段：32个32位寄存器(x0恒为0)、组合读+时序写回 |
| `execute.v` | 执行阶段：ALU运算(纯组合逻辑)、分支条件判断 |
| `memory_access.v` | 访存阶段：控制数据内存读写 |
| `data_memory.v` | 数据内存：4096字节，支持LB/LH/LW/LBU/LHU/SB/SH/SW |
| `write_back.v` | 写回阶段：选择ALU结果/内存数据/PC+4写回寄存器 |
| `stat.v` | 状态模块：AOK/HLT/ADR/INS |
| `pc_update.v` | PC更新：顺序/分支/JAL/JALR |
| `riscv_cpu.v` | 顶层CPU模块 |
| `riscv_cpu_tb.v` | 综合测试平台(覆盖全部40条指令) |
| `filelist.f` | VCS文件列表 |
| `Makefile` | 构建脚本 |

## 构建与运行

```bash
# Icarus Verilog 编译
make iverilog

# 运行仿真
make sim

# VCS 编译 (如有)
make vcs

# VCS 运行
make run

# 清理
make clean
```

## 架构特点

- **32位数据通路**：32位指令、32位地址、32位数据
- **小端序**：指令和数据均为小端序存储
- **寄存器文件**：32个32位通用寄存器，x0硬连线为0
- **单周期执行**：每条指令在一个时钟周期内完成
- **ECALL/EBREAK 停机**：系统指令触发 CPU 停机
