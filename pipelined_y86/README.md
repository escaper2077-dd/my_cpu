# Y86 五级流水线CPU

这是一个基于Y86指令集的五级流水线处理器实现。

## 架构概述

### 流水线阶段

1. **IF (Instruction Fetch)** - 取指阶段
   - 从指令内存读取指令
   - 解析指令格式（icode, ifun, rA, rB, valC）
   - 计算下一条指令地址（valP）

2. **ID (Instruction Decode)** - 译码阶段
   - 读取寄存器文件
   - 确定源寄存器（srcA, srcB）和目标寄存器（dstE, dstM）
   - 支持寄存器写回

3. **EX (Execute)** - 执行阶段
   - ALU运算
   - 地址计算
   - 条件码评估
   - 支持数据转发

4. **MEM (Memory Access)** - 访存阶段
   - 读/写数据内存
   - 支持加载/存储指令

5. **WB (Write Back)** - 写回阶段
   - 确定CPU状态（AOK, HLT, ADR, INS）
   - 数据写回到寄存器文件（通过ID阶段）

### 流水线寄存器

- **IF/ID寄存器** (`if_id_reg.v`)
  - 保存取指阶段的输出
  - 支持阻塞（stall）和气泡（bubble）

- **ID/EX寄存器** (`id_ex_reg.v`)
  - 保存译码阶段的输出
  - 传递源/目标寄存器信息

- **EX/MEM寄存器** (`ex_mem_reg.v`)
  - 保存执行阶段的输出
  - 传递条件码和计算结果

- **MEM/WB寄存器** (`mem_wb_reg.v`)
  - 保存访存阶段的输出
  - 传递最终写回数据

### 冒险处理

#### 数据冒险（Data Hazards）

1. **转发（Forwarding）**
   - EX/MEM → EX：从MEM阶段转发valE
   - MEM/WB → EX：从WB阶段转发valE或valM
   - 转发单元自动选择最新的数据

2. **阻塞（Stalling）**
   - 加载使用冒险（Load-Use Hazard）
   - 当MRMOVL/POPL的目标寄存器是下一条指令的源寄存器时
   - 阻塞PC和IF/ID寄存器，插入气泡到ID/EX寄存器

#### 控制冒险（Control Hazards）

1. **分支预测**
   - 简单预测策略：总是预测顺序执行
   - JXX指令在MEM阶段检查条件

2. **预测错误处理**
   - 清空IF/ID和ID/EX寄存器（插入气泡）
   - 使用正确的PC值重新取指

3. **RET指令处理**
   - 阻塞流水线直到RET完成
   - 使用从内存读取的返回地址更新PC

## 文件结构

```
pipelined_y86/
├── pipelined_y86_cpu.v       # 顶层模块
├── pipe_fetch.v               # 取指阶段
├── pipe_decode.v              # 译码阶段
├── pipe_execute.v             # 执行阶段
├── pipe_memory.v              # 访存阶段
├── pipe_writeback.v           # 写回阶段
├── pipe_pc_select.v           # PC选择逻辑
├── if_id_reg.v                # IF/ID流水线寄存器
├── id_ex_reg.v                # ID/EX流水线寄存器
├── ex_mem_reg.v               # EX/MEM流水线寄存器
├── mem_wb_reg.v               # MEM/WB流水线寄存器
├── hazard_control.v           # 冒险检测和控制单元
├── pipelined_y86_cpu_tb.v    # 测试平台
├── program.hex                # 示例程序
├── Makefile                   # 编译脚本
├── filelist.f                 # 文件列表
└── README.md                  # 本文件
```

## 编译和运行

### 使用Makefile

```bash
# 编译
make compile

# 编译并运行
make run

# 查看波形（需要DVE）
make dve

# 清理
make clean
```

### 手动编译（使用VCS）

```bash
vcs -full64 -sverilog -debug_access+all -timescale=1ps/1ps -f filelist.f -o simv
./simv
```

### 使用Icarus Verilog（开源工具）

```bash
iverilog -o pipelined_y86_cpu -f filelist.f
vvp pipelined_y86_cpu
gtkwave pipelined_y86_cpu.vcd
```

## 程序格式

程序以十六进制格式存储在`program.hex`文件中。示例：

```
# 初始化 %rax = 3
30 F0 03 00 00 00 00 00 00 00   # irmovq $3, %rax

# 初始化 %rbx = 5  
30 F3 05 00 00 00 00 00 00 00   # irmovq $5, %rbx

# %rax = %rax + %rbx
60 30                           # addq %rbx, %rax

# HALT
10                              # halt
```

### Y86指令格式

| 指令 | icode | ifun | 格式 |
|------|-------|------|------|
| halt | 0x1 | 0x0 | `10` |
| nop | 0x0 | 0x0 | `00` |
| rrmovq | 0x2 | 0x0-0x6 | `2x rA rB` |
| irmovq | 0x3 | 0x0 | `30 F rB V(8)` |
| rmmovq | 0x4 | 0x0 | `40 rA rB D(8)` |
| mrmovq | 0x5 | 0x0 | `50 rA rB D(8)` |
| addq | 0x6 | 0x0 | `60 rA rB` |
| subq | 0x6 | 0x1 | `61 rA rB` |
| andq | 0x6 | 0x2 | `62 rA rB` |
| xorq | 0x6 | 0x3 | `63 rA rB` |
| jmp | 0x7 | 0x0 | `70 Dest(8)` |
| call | 0x8 | 0x0 | `80 Dest(8)` |
| ret | 0x9 | 0x0 | `90` |
| pushq | 0xA | 0x0 | `A0 rA F` |
| popq | 0xB | 0x0 | `B0 rA F` |

### 寄存器编码

| 编号 | 寄存器 | 编号 | 寄存器 |
|------|--------|------|--------|
| 0x0 | %rax | 0x8 | %r8 |
| 0x1 | %rcx | 0x9 | %r9 |
| 0x2 | %rdx | 0xA | %r10 |
| 0x3 | %rbx | 0xB | %r11 |
| 0x4 | %rsp | 0xC | %r12 |
| 0x5 | %rbp | 0xD | %r13 |
| 0x6 | %rsi | 0xE | %r14 |
| 0x7 | %rdi | 0xF | 无寄存器 |

## 性能特性

### 理想CPI（Cycles Per Instruction）

- 无冒险情况：CPI = 1.0
- 有数据冒险（转发）：CPI = 1.0
- 加载使用冒险：CPI = 2.0（1个气泡）
- 分支预测错误：CPI = 3.0（2个气泡）
- RET指令：CPI取决于阻塞周期数

### 流水线效率

五级流水线理论上可以提供5倍的吞吐量提升（相比非流水线）。
实际性能受以下因素影响：
- 数据冒险频率
- 分支指令频率
- 分支预测准确率

## 调试

### 监视流水线状态

测试平台会显示每个周期的流水线状态：

```
Time=X | PC=0xY | F:icode D:icode E:icode M:icode W:icode | Stat=XX
```

### 寄存器内容

仿真结束时会自动显示所有寄存器的最终值。

### 波形查看

使用DVE或GTKWave查看详细的信号波形，帮助调试时序问题。

## 扩展和改进

可能的改进方向：

1. **分支预测**
   - 实现动态分支预测（如2-bit饱和计数器）
   - 分支目标缓冲（BTB）

2. **超标量**
   - 多发射流水线
   - 乱序执行

3. **缓存**
   - 指令缓存
   - 数据缓存

4. **性能计数器**
   - 周期计数
   - 指令计数
   - 冒险统计

## 参考资料

- Randal E. Bryant and David R. O'Hallaron, "Computer Systems: A Programmer's Perspective"
- John L. Hennessy and David A. Patterson, "Computer Architecture: A Quantitative Approach"

## 许可

本项目基于教学目的开发，仅供学习使用。
