# Y86 CPU 项目总结

## 项目概述

本项目包含两个Y86处理器实现：

1. **单周期CPU** (`y86/`) - 原始实现
2. **五级流水线CPU** (`pipelined_y86/`) - 新实现

## 目录结构

```
my_cpu/
├── y86/                          # 单周期Y86 CPU
│   ├── y86_cpu.v                 # 顶层模块
│   ├── fetch.v                   # 取指
│   ├── decode.v                  # 译码
│   ├── execute.v                 # 执行
│   ├── memory_access.v           # 访存
│   ├── write_back.v              # 写回
│   ├── pc_update.v               # PC更新
│   ├── stat.v                    # 状态
│   └── ...                       # 测试文件
│
└── pipelined_y86/                # 五级流水线Y86 CPU
    ├── pipelined_y86_cpu.v       # 顶层模块
    ├── pipe_fetch.v              # 取指阶段
    ├── pipe_decode.v             # 译码阶段
    ├── pipe_execute.v            # 执行阶段
    ├── pipe_memory.v             # 访存阶段
    ├── pipe_writeback.v          # 写回阶段
    ├── pipe_pc_select.v          # PC选择逻辑
    ├── if_id_reg.v               # IF/ID流水线寄存器
    ├── id_ex_reg.v               # ID/EX流水线寄存器
    ├── ex_mem_reg.v              # EX/MEM流水线寄存器
    ├── mem_wb_reg.v              # MEM/WB流水线寄存器
    ├── hazard_control.v          # 冒险检测和控制
    ├── pipelined_y86_cpu_tb.v   # 测试平台
    ├── program.hex               # 默认测试程序
    ├── program_simple.hex        # 简单测试
    ├── program_comprehensive.hex # 综合测试
    ├── Makefile                  # 编译脚本
    ├── filelist.f                # 文件列表
    ├── README.md                 # 架构文档
    └── USAGE.md                  # 使用指南
```

## 两种实现的对比

| 特性 | 单周期CPU | 五级流水线CPU |
|------|-----------|---------------|
| **时钟周期/指令** | 1个长周期 | 1个短周期（理想） |
| **CPI** | 1.0 | ~1.0-1.5（含冒险） |
| **时钟频率** | 低（受最慢指令限制） | 高（只受最慢阶段限制） |
| **吞吐量** | 低 | 高（约5倍） |
| **复杂度** | 简单 | 复杂 |
| **冒险处理** | 不需要 | 需要（转发、阻塞） |
| **面积** | 小 | 大（流水线寄存器） |
| **适用场景** | 教学、简单系统 | 高性能系统 |

## 流水线CPU的关键特性

### 1. 流水线阶段

```
IF → ID → EX → MEM → WB
```

每个阶段并行执行不同指令，最多可同时处理5条指令。

### 2. 冒险处理机制

#### 数据冒险（RAW - Read After Write）
- **转发（Forwarding）**: 从后续阶段提前获取数据
  - EX/MEM → EX
  - MEM/WB → EX
- **阻塞（Stalling）**: 加载使用冒险时插入气泡

#### 控制冒险（分支）
- **预测策略**: 总是预测不跳转
- **错误处理**: 清空错误路径上的指令
- **RET处理**: 阻塞直到返回地址可用

### 3. 性能优化

- 数据转发减少阻塞
- 简单的分支预测
- 流水线寄存器最小化延迟

## 快速使用指南

### 运行流水线CPU

```bash
cd /home/escaper/my_cpu/pipelined_y86
make run
```

### 切换测试程序

```bash
# 使用简单测试
cp program_simple.hex program.hex

# 使用综合测试
cp program_comprehensive.hex program.hex

# 运行
make run
```

### 查看结果

仿真会输出：
1. 流水线执行轨迹
2. 最终CPU状态
3. 所有寄存器值

## 测试程序说明

### program.hex（默认）
- 简单加法：3 + 5 = 8
- 验证基本流水线功能

### program_simple.hex
- 基本算术运算
- 适合快速验证

### program_comprehensive.hex
- 测试数据转发
- 测试加载使用冒险
- 测试条件移动
- 测试内存操作
- 测试栈操作

## 技术亮点

### 1. 完整的流水线实现
- 5个独立的流水线阶段
- 4个流水线寄存器
- 支持阻塞和气泡插入

### 2. 冒险检测和解决
- 自动数据转发
- 智能阻塞决策
- 分支预测失败恢复

### 3. 模块化设计
- 各阶段独立模块
- 易于修改和扩展
- 清晰的接口定义

### 4. 完整的测试环境
- 自动化测试平台
- 多个测试程序
- 详细的调试输出

## 性能指标

### 理论性能
- **最大吞吐量**: 1条指令/周期
- **流水线加速比**: 约5倍（相比单周期）
- **时钟频率提升**: 约5倍

### 实际性能（含冒险）
- **平均CPI**: 1.0-1.5
- **分支预测开销**: 2个气泡/错误预测
- **加载使用开销**: 1个气泡/冒险

## 扩展建议

### 短期改进
1. 实现动态分支预测
2. 添加性能计数器
3. 优化转发路径

### 长期扩展
1. 实现指令缓存
2. 实现数据缓存
3. 超标量执行（多发射）
4. 乱序执行

## 学习路径

1. **理解单周期CPU** - 从`y86/`开始
2. **学习流水线概念** - 阅读`pipelined_y86/README.md`
3. **分析冒险处理** - 研究`hazard_control.v`
4. **运行测试** - 使用提供的测试程序
5. **修改和扩展** - 尝试优化或添加新特性

## 参考资料

### 教材
- Bryant & O'Hallaron, "Computer Systems: A Programmer's Perspective"
- Hennessy & Patterson, "Computer Architecture: A Quantitative Approach"

### 在线资源
- [CMU CSAPP课程](http://csapp.cs.cmu.edu/)
- [Y86-64指令集](http://csapp.cs.cmu.edu/3e/simguide.pdf)

## 致谢

本项目基于CMU的Y86指令集架构，用于教学和学习计算机组成原理。

## 许可

仅供学习使用。

---

**最后更新**: 2026年1月23日
