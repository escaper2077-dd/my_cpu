# Y86 五级流水线CPU 使用指南

## 快速开始

### 1. 进入项目目录

```bash
cd /home/escaper/my_cpu/pipelined_y86
```

### 2. 运行简单测试

```bash
# 编译并运行（使用默认程序）
make run
```

### 3. 查看结果

仿真结束后会显示：
- CPU最终状态（HALT/ERROR）
- 所有寄存器的值
- 流水线执行轨迹

## 修改测试程序

### 使用预定义的测试程序

项目提供了三个测试程序：

1. **program.hex** - 默认简单程序（3 + 5）
2. **program_simple.hex** - 基本算术运算
3. **program_comprehensive.hex** - 综合测试（包括转发、冒险、内存操作）

切换程序的方法：

```bash
# 备份当前程序
cp program.hex program_backup.hex

# 使用综合测试程序
cp program_comprehensive.hex program.hex

# 运行测试
make run
```

### 编写自定义程序

创建新的`.hex`文件，格式如下：

```
# 注释行以#开头
30 F0 0A 00 00 00 00 00 00 00   # irmovq $10, %rax
30 F3 14 00 00 00 00 00 00 00   # irmovq $20, %rbx
60 30                           # addq %rbx, %rax
10                              # halt
```

**重要规则：**
- 每行可以包含多个字节（用空格分隔）
- 注释以`#`开头
- 所有数值必须是十六进制
- 指令必须按正确的Y86格式编码

## Y86指令编码参考

### 基本格式

```
1字节指令：    icode:ifun
2字节指令：    icode:ifun rA:rB
10字节指令：   icode:ifun rA:rB + 8字节立即数/地址
```

### 常用指令示例

```verilog
// NOP
00

// HALT
10

// 立即数加载：irmovq $V, rB
30 F[rB] [V的8字节小端序]
示例：irmovq $10, %rax
30 F0 0A 00 00 00 00 00 00 00

// 寄存器移动：rrmovq rA, rB
20 [rA][rB]
示例：rrmovq %rax, %rbx
20 03

// ALU运算：OPq rA, rB （结果存到rB）
6[op] [rA][rB]
  op=0: addq
  op=1: subq  
  op=2: andq
  op=3: xorq
示例：addq %rbx, %rax
60 30

// 内存加载：mrmovq D(rB), rA
50 [rA][rB] [D的8字节小端序]
示例：mrmovq 0(%rsp), %rax
50 04 00 00 00 00 00 00 00 00

// 内存存储：rmmovq rA, D(rB)
40 [rA][rB] [D的8字节小端序]
示例：rmmovq %rax, 8(%rsp)
40 04 08 00 00 00 00 00 00 00

// 跳转：jXX Dest
7[cond] [Dest的8字节小端序]
  cond=0: jmp (无条件)
  cond=1: jle
  cond=2: jl
  cond=3: je
  cond=4: jne
  cond=5: jge
  cond=6: jg

// 调用：call Dest
80 [Dest的8字节小端序]

// 返回：ret
90

// 压栈：pushq rA
A0 [rA]F

// 出栈：popq rA
B0 [rA]F
```

### 寄存器编码

```
0 = %rax    8 = %r8
1 = %rcx    9 = %r9
2 = %rdx    A = %r10
3 = %rbx    B = %r11
4 = %rsp    C = %r12
5 = %rbp    D = %r13
6 = %rsi    E = %r14
7 = %rdi    F = 无寄存器
```

## 调试技巧

### 1. 查看流水线执行

测试平台会实时显示每个周期的流水线状态：

```
Time=10000 | PC=0x0 | F:3 D:0 E:0 M:0 W:0 | Stat=00
```

说明：
- `PC`: 当前取指地址
- `F/D/E/M/W`: 各阶段的指令码
- `Stat`: CPU状态（00=运行, 01=停机, 10=地址错误, 11=非法指令）

### 2. 检查寄存器值

仿真结束时会自动显示所有寄存器：

```
Register File Contents:
%rax (R0):  0x0000000000000008
%rcx (R1):  0x0000000000000000
...
```

### 3. 生成波形文件

```bash
make run
# 会生成 pipelined_y86_cpu.vcd

# 使用GTKWave查看（如果已安装）
gtkwave pipelined_y86_cpu.vcd
```

### 4. 添加调试输出

在`pipelined_y86_cpu_tb.v`中添加自定义监视信号：

```verilog
initial begin
    $monitor("Time=%0t | PC=0x%h | rax=%h | rbx=%h", 
             $time, PC, 
             cpu.decode_stage.regfile[0],
             cpu.decode_stage.regfile[3]);
end
```

## 常见问题

### Q: 程序没有正常HALT

**A:** 检查以下几点：
1. 确保程序最后有`10`（HALT指令）
2. 检查跳转地址是否正确
3. 查看是否有非法指令（Stat=11）

### Q: 寄存器值不正确

**A:** 可能的原因：
1. 指令编码错误
2. 立即数的字节序错误（应使用小端序）
3. 数据冒险未正确处理

### Q: 编译错误

**A:** 确保：
1. 所有.v文件都在目录中
2. filelist.f包含所有文件
3. VCS已正确安装

### Q: 如何测试特定的流水线特性？

**A:** 参考`program_comprehensive.hex`，它包含：
- 数据转发测试
- 加载使用冒险测试
- 分支预测测试
- 内存操作测试

## 性能分析

### 计算CPI（Cycles Per Instruction）

```
CPI = 总周期数 / 已执行指令数
```

从仿真输出中：
1. 记录从复位到HALT的时钟周期数
2. 计算程序中的指令总数
3. CPI = 周期数 / 指令数

理想情况下，CPI应接近1.0。

### 识别性能瓶颈

查看$monitor输出，统计：
- 气泡（bubble）插入次数
- 阻塞（stall）发生次数
- 分支预测错误次数

## 进阶使用

### 1. 修改流水线深度

当前是5级流水线，如果需要更深的流水线：
1. 添加更多流水线寄存器
2. 拆分现有阶段
3. 更新冒险检测逻辑

### 2. 实现分支预测

修改`pipe_pc_select.v`：
- 添加分支历史表
- 实现预测算法
- 更新PC选择逻辑

### 3. 添加缓存

在fetch和memory阶段：
- 实现简单的直接映射缓存
- 添加缓存命中/缺失逻辑
- 处理缓存一致性

### 4. 性能计数器

添加计数器来跟踪：
```verilog
reg [31:0] cycle_count;
reg [31:0] instr_count;
reg [31:0] stall_count;
reg [31:0] bubble_count;
```

## 资源

- [Y86指令集参考](http://csapp.cs.cmu.edu/3e/home.html)
- [Verilog教程](https://www.chipverify.com/verilog/verilog-tutorial)
- [流水线CPU设计](https://en.wikipedia.org/wiki/Instruction_pipelining)

## 获取帮助

如果遇到问题：
1. 检查README.md了解架构细节
2. 查看波形文件定位问题
3. 使用简单的测试程序逐步验证
4. 添加调试输出来跟踪信号变化
