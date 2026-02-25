# Y86-64 流水线CPU实现 (PIPE架构)

## 文件说明

### 核心模块
- `pipelined_y86_cpu.v` - 顶层CPU模块，集成所有流水线阶段
- `pipe_stage_fetch.v` - F阶段：指令取指
- `pipe_stage_decode.v` - D阶段：指令译码和寄存器读取
- `pipe_stage_execute.v` - E阶段：ALU运算、条件评估和数据转发
- `pipe_stage_memory.v` - M阶段：数据存储器访问
- `pipe_stage_writeback.v` - W阶段：寄存器写回

### 流水线寄存器
- `pipe_reg_fd.v` - F/D流水线寄存器
- `pipe_reg_de.v` - D/E流水线寄存器
- `pipe_reg_em.v` - E/M流水线寄存器
- `pipe_reg_mw.v` - M/W流水线寄存器

### 控制逻辑
- `pipe_pc_logic.v` - PC选择逻辑（处理跳转、分支预测、RET）
- `pipe_control.v` - 流水线控制逻辑（冒险检测、stall/bubble生成）

### 测试
- `pipelined_y86_comprehensive_tb.v` - 全指令类型覆盖测试
- `comprehensive_test` - 编译好的测试可执行文件

## 架构特性

### PIPE框架实现
- **5级流水线**: Fetch → Decode → Execute → Memory → WriteBack
- **简单分支预测器**: 总是预测顺序执行（不跳转）
- **数据转发**: E→M, W→E 避免数据冒险
- **冒险处理**:
  - Load-Use冒险: D阶段stall
  - 分支预测错误: D/E阶段插入bubble
  - RET冒险: F/D阶段stall直到返回地址可用

### 指令集支持
- **数据传送**: `nop`, `halt`, `rrmovq`, `irmovq`, `rmmovq`, `mrmovl`
- **条件传送**: `cmovle`, `cmovl`, `cmove`, `cmovne`, `cmovge`, `cmovg`
- **ALU运算**: `addq`, `subq`, `andq`, `xorq`
- **条件跳转**: `jmp`, `jle`, `jl`, `je`, `jne`, `jge`, `jg`
- **过程调用**: `call`, `ret`
- **栈操作**: `pushq`, `popq`

## 测试结果

综合测试全部通过 ✅:
- rrmovq, irmovq
- 所有CMOVxx变体（6种条件）
- 所有ALU操作（4种）
- 所有JXX跳转（7种条件）
- rmmovq/mrmovq存储器访问
- call/ret过程调用
- pushq/popq栈操作

## 编译和运行

### 使用Makefile（推荐）
```bash
# 查看帮助
make help

# 编译
make vcs

# 运行测试
make run

# 清理编译产物
make clean

# 完全清理
make cleanall
```

### 手动编译
```bash
# 使用VCS编译
vcs -full64 -debug_access+all -LDFLAGS -Wl,-no-pie -o comprehensive_test \
    pipelined_y86_cpu.v pipe_*.v pipelined_y86_comprehensive_tb.v

# 运行测试
./comprehensive_test
```

## 设计说明

本实现基于CS:APP第四章的PIPE处理器架构，做了以下增强：
1. **E/M寄存器支持bubble**: 防止分支预测错误时E阶段指令写回
2. **Execute阶段bubble控制**: 防止被取消指令更新条件码
3. **完整的数据转发逻辑**: M→E和W→E转发路径

模拟时序: ~7ns (70个时钟周期 @ 100ps周期)
