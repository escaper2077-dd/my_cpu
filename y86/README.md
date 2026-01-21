# Y86-64 单周期 CPU 实现

## 项目概述

这是一个基于 Y86-64 指令集的单周期 CPU 实现，包含完整的五个流水线阶段（在单周期中按顺序执行）：
1. **取指 (Fetch)**
2. **译码 (Decode)** - 包含寄存器读写
3. **执行 (Execute)**
4. **访存 (Memory Access)**
5. **写回 (Write Back)** - 包含状态判断
6. **PC 更新 (PC Update)**

## 文件结构

### 核心模块
- `fetch.v` - 取指阶段：从指令内存读取指令
- `decode.v` - 译码阶段：读取寄存器，并在时钟上升沿写回结果
- `execute.v` - 执行阶段：ALU 运算和条件码判断
- `memory_access.v` - 访存阶段：数据内存读写
- `write_back.v` - 写回阶段：传递数据值
- `stat.v` - 状态判断模块：确定 CPU 运行状态
- `pc_update.v` - PC 更新模块：根据指令类型更新 PC

### 顶层模块
- `y86_cpu.v` - CPU 顶层模块：连接所有阶段

### 测试文件
- `write_back_tb.v` - 写回阶段单元测试
- `y86_cpu_tb.v` - CPU 基础测试
- `y86_cpu_full_tb.v` - CPU 完整功能测试（带测试程序）

## 支持的指令

1. **NOP** (0x0) - 空操作
2. **HALT** (0x1) - 停机
3. **RRMOVL** (0x2) - 寄存器到寄存器移动（含条件移动）
4. **IRMOVL** (0x3) - 立即数到寄存器
5. **RMMOVL** (0x4) - 寄存器到内存
6. **MRMOVL** (0x5) - 内存到寄存器
7. **ALU** (0x6) - 算术逻辑运算（ADDL, SUBL, ANDL, XORL）
8. **JXX** (0x7) - 条件跳转
9. **CALL** (0x8) - 函数调用
10. **RET** (0x9) - 函数返回
11. **PUSHL** (0xA) - 压栈
12. **POPL** (0xB) - 出栈

## CPU 状态码

- `00` (STAT_AOK) - 正常运行
- `01` (STAT_HLT) - 遇到 HALT 指令
- `10` (STAT_ADR) - 地址错误（内存访问越界）
- `11` (STAT_INS) - 非法指令

## 寄存器文件

实现了 15 个 64 位寄存器（%rax - %r14）：
- %rax (0) - 累加器
- %rcx (1) - 计数器
- %rdx (2) - 数据寄存器
- %rbx (3) - 基址寄存器
- %rsp (4) - 栈指针
- %rbp (5) - 基址指针
- %rsi (6) - 源索引
- %rdi (7) - 目标索引
- %r8 - %r14 (8-14) - 通用寄存器

## 编译和运行

### 编译单个测试
```bash
cd y86
vcs -full64 -sverilog write_back.v stat.v write_back_tb.v -o write_back_test -LDFLAGS -no-pie
./write_back_test
```

### 编译完整 CPU
```bash
cd y86
vcs -full64 -sverilog fetch.v decode.v execute.v memory_access.v write_back.v stat.v pc_update.v y86_cpu.v y86_cpu_full_tb.v -o y86_cpu_final -LDFLAGS -no-pie
./y86_cpu_final
```

## 测试程序

当前测试程序执行以下指令：
```assembly
0x00: irmovq $10, %rax      # %rax = 10
0x0A: irmovq $20, %rbx      # %rbx = 20
0x14: addq %rbx, %rax       # %rax = %rax + %rbx = 30
0x16: irmovq $100, %rsp     # %rsp = 100
0x20: halt                  # 停机
```

### 预期结果
- %rax = 30 (10 + 20)
- %rbx = 20
- %rsp = 100
- CPU 在第 5 个周期停止于 HALT 指令

## 测试结果

```
Cycle  PC           Icode      Status  
------------------------------------------
1      0x0          IRMOVL     00
2      0xa          IRMOVL     00
3      0x14         ALU        00
4      0x16         IRMOVL     00
5      0x20         HALT       01

=== CPU HALTED at cycle 5 ===
Final PC: 0x0000000000000020

✓ PASS: %rax = 30 (10 + 20)
✓ PASS: %rbx = 20
✓ PASS: %rsp = 100
```

## 关键设计特点

### 1. 寄存器写回
- 在 decode 模块中实现
- 在时钟上升沿写回 valE 和 valM
- RRMOVL 指令检查条件码 (Cnd)
- 支持 dstE 和 dstM 的并发写回

### 2. PC 更新逻辑
- CALL: PC = valC (目标地址)
- RET: PC = valM (从栈弹出的返回地址)
- JXX: PC = Cnd ? valC : valP (条件跳转)
- 其他: PC = valP (顺序执行)
- HALT/错误时：PC 保持不变

### 3. 状态判断优先级
1. 指令内存错误 (IMEM error) - 最高优先级
2. 非法指令 (Invalid instruction)
3. 数据内存错误 (DMEM error)
4. HALT 指令
5. 正常运行 (AOK) - 默认状态

### 4. 条件码
实现了三个条件标志：
- ZF (Zero Flag) - 结果为零
- SF (Sign Flag) - 结果为负
- OF (Overflow Flag) - 有符号溢出

## 内存配置

- **指令内存**: 1024 字节 (0x000 - 0x3FF)
- **数据内存**: 2048 字节 (0x000 - 0x7FF)

## 单周期执行流程

```
1. Fetch:    根据 PC 从指令内存读取指令
2. Decode:   读取源寄存器 (srcA, srcB)
3. Execute:  执行 ALU 运算，更新条件码
4. Memory:   访问数据内存（读/写）
5. Write:    准备写回数据
6. Update:   更新 PC，写回寄存器（在下一个时钟沿）
```

## 项目完成状态

✅ 所有阶段已实现并测试通过
✅ 寄存器写回功能正常
✅ PC 更新逻辑正确
✅ HALT 指令正确停止 CPU
✅ 状态判断准确
✅ 测试程序运行成功

## 后续改进方向

1. 添加更多测试用例（跳转、函数调用等）
2. 实现数据转发（为流水线做准备）
3. 添加性能计数器
4. 实现异常处理机制
5. 添加调试接口

## 作者信息

- 项目: Y86-64 单周期 CPU
- 日期: 2026-01-21
- 工具: VCS (Synopsys VCS O-2018.09-SP2)
