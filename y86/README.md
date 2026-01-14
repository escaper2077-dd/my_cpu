# Y86-64 Fetch Stage Testbench 使用指南

## 概述

本项目提供了用于VCS（Synopsys Verilog Compiler Simulator）兼容的Y86-64单周期CPU取指阶段测试框架。

## 文件说明

### 核心模块
- **fetch.v** - Y86-64取指阶段的Verilog实现（纯组合逻辑，无always块）
  - 模块名: `fetchC`
  - 输入: `PC_i` (64位地址)
  - 输出: `icode_o`, `ifun_o`, `rA_o`, `rB_o`, `valC_o`, `valP_o`, `instr_valid_o`, `imem_error_o`

### Testbench文件

#### 1. fetch_tb.v (基础testbench)
功能：
- 初始化各种指令（NOP, HALT, RRMOVQ, IRMOVQ, RMMOVQ, OPQ, 无效指令）
- 测试不同PC值下的指令解析
- 显示输出结果表格

用法：
```bash
# 使用iverilog编译和运行
iverilog -o fetch_test fetch.v fetch_tb.v
vvp fetch_test

# 或使用VCS编译（如果系统安装了VCS）
vcs -pp -sverilog fetch.v fetch_tb.v -o simv
./simv
```

#### 2. fetch_tb_enhanced.v (增强testbench)
功能：
- 包含11个自动化测试用例
- 自检功能 - 验证每个测试的结果
- 测试通过/失败统计
- 测试包括：
  - 基本指令（NOP, HALT, RRMOVQ, OPQ等）
  - 多字节指令（IRMOVQ, JXX）
  - 无效指令检测
  - 内存越界检测

用法：
```bash
# 编译并运行
iverilog -o fetch_test_enhanced fetch.v fetch_tb_enhanced.v
vvp fetch_test_enhanced
```

### 脚本文件
- **run_vcs.sh** - 自动化运行脚本，根据系统环境选择VCS或iverilog/vvp

## 指令编码

| icode | ifun | 指令名 | 字节长 | 需要regids | 需要valC | 说明 |
|-------|------|--------|--------|-----------|----------|------|
| 0x0   | 0x0  | NOP    | 1      | ❌        | ❌       | 空操作 |
| 0x1   | 0x0  | HALT   | 1      | ❌        | ❌       | 停止 |
| 0x2   | 0x0  | RRMOVQ | 2      | ✅        | ❌       | 寄存器间移动 |
| 0x3   | 0x0  | IRMOVQ | 10     | ✅        | ✅       | 立即数移动 |
| 0x4   | 0x0  | RMMOVQ | 10     | ✅        | ✅       | 寄存器到内存 |
| 0x5   | 0x0  | MRMOVQ | 10     | ✅        | ✅       | 内存到寄存器 |
| 0x6   | -    | OPQ    | 2      | ✅        | ❌       | 算术操作 |
| 0x7   | -    | JXX    | 5      | ❌        | ✅       | 条件跳转 |
| 0x8   | -    | CALL   | 5      | ❌        | ✅       | 函数调用 |
| 0x9   | 0x0  | RET    | 1      | ❌        | ❌       | 函数返回 |
| 0xA   | -    | PUSHQ  | 2      | ✅        | ❌       | 压栈 |
| 0xB   | -    | POPQ   | 2      | ✅        | ❌       | 出栈 |

## valP 计算公式

```
valP = PC + 1 + need_regids + (need_valC ? 8 : 0)
```

其中：
- `PC` 是当前指令地址
- `1` 是指令字节（icode + ifun）
- `need_regids` 为1表示有寄存器字节（1字节）
- `need_valC` 为1表示有立即数（8字节）

## 关键设计特性

### 1. 纯组合逻辑
- ✅ 无`always`块
- ✅ 全部使用`assign`语句
- ✅ 零延迟逻辑（除了访存延迟）

### 2. 条件字段提取
```verilog
// 寄存器字段 - 只在需要时提取
assign rA_o = need_regids ? instr_mem[PC_i + 1][7:4] : 4'hF;
assign rB_o = need_regids ? instr_mem[PC_i + 1][3:0] : 4'hF;

// 常数字段 - 位置取决于是否有regids字节
assign valC_o = need_regids ? {instr_mem[PC_i + 9], ..., instr_mem[PC_i + 2]} :
                              {instr_mem[PC_i + 8], ..., instr_mem[PC_i + 1]};
```

### 3. 错误检测
- 指令有效性检查：`icode < 0xC`
- 内存越界检查：`PC > 1023`

## 测试结果示例

```
╔════════════════════════════════════════════════════════════╗
║    Y86-64 Fetch Stage - Enhanced Testbench (VCS Compatible) ║
╚════════════════════════════════════════════════════════════╝

[Test 1] NOP Instruction at PC=0
✓ PASS

[Test 2] HALT Instruction at PC=1
✓ PASS

...

╔════════════════════════════════════════════════════════════╗
║                      Test Summary                           ║
╠════════════════════════════════════════════════════════════╣
║  PASS:  10                                                  ║
║  FAIL:   1                                                  ║
║  Total: 11                                                 ║
╚════════════════════════════════════════════════════════════╝
```

## VCS 编译命令

⚠️ **注意**: VCS 2018版本在现代Linux内核（5.x+）上可能出现链接错误。建议使用iverilog代替。

```bash
# 基础编译（可能失败，见下方解决方案）
vcs -sverilog fetch.v fetch_tb.v -o simv

# 不使用-pp选项的编译
vcs -sverilog fetch.v fetch_tb.v -o simv

# 加入调试信息
vcs -sverilog -debug_all fetch.v fetch_tb.v -o simv

# 生成波形文件
vcs -sverilog +access+r fetch.v fetch_tb.v -o simv
./simv -gui
```

### VCS编译失败的解决方案

**错误信息**:
```
relocation R_X86_64_32S against symbol '_sigintr' can not be used when making a PIE object
```

**原因**: VCS 2018与Linux kernel 5.x+的兼容性问题

**解决方案**:

1. **方案1：使用iverilog（✅推荐）**
   ```bash
   iverilog -g2009 -o fetch_test_enhanced fetch.v fetch_tb_enhanced.v
   vvp fetch_test_enhanced
   ```

2. **方案2：禁用PIE（不推荐，安全风险）**
   ```bash
   export LDFLAGS="-no-pie"
   vcs -sverilog fetch.v fetch_tb_enhanced.v -o simv
   ./simv
   ```

3. **方案3：升级VCS**
   - VCS 2019及以上版本完全兼容现代Linux

## iverilog 编译命令 (✅推荐)

```bash
# 编译基础testbench
iverilog -g2009 -o fetch_test fetch.v fetch_tb.v

# 编译增强testbench（推荐）
iverilog -g2009 -o fetch_test_enhanced fetch.v fetch_tb_enhanced.v

# 运行
vvp fetch_test
vvp fetch_test_enhanced

# 生成波形
vvp -vcd fetch_test_enhanced

# 一行命令（推荐用于快速测试）
iverilog -g2009 -o fetch_test_enhanced fetch.v fetch_tb_enhanced.v && vvp fetch_test_enhanced
```

**优势**:
- ✅ 完全兼容现代Linux内核
- ✅ 开源，无许可证限制
- ✅ 编译速度快
- ✅ 本项目完全支持

## 常见问题

### Q: VCS编译失败，显示PIE相关错误
**A:** 这是VCS 2018与现代Linux内核的兼容性问题。
- **最佳方案**：使用iverilog - `iverilog -g2009 -o test fetch.v fetch_tb_enhanced.v && vvp test`
- **替代方案**：升级VCS到2019或更新版本
- **临时方案**：`export LDFLAGS="-no-pie"` 后重新编译（不安全）

### Q: 为什么valC的值看起来不对?
**A:** valC采用小端法存储。位置PC+2到PC+9的8个字节组成64位数值。

### Q: 如何修改指令内存?
**A:** 在testbench中修改`fetch_inst.instr_mem[]`数组：
```verilog
fetch_inst.instr_mem[0] = 8'h00;  // 字节0
fetch_inst.instr_mem[1] = 8'hFF;  // 字节1
...
```

### Q: 模块支持的最大内存地址是多少?
**A:** 1023（1024字节）。地址超过此值会触发`imem_error_o`信号。

### Q: iverilog和VCS哪个更好？
**A:** 
- **iverilog**: 开源、免费、完全兼容现代Linux、编译快 ✅ **推荐**
- **VCS**: 商业、功能强大、需要解决兼容性问题

## 集成到其他项目

### VCS工作流程
```bash
# 1. 编译
vcs -pp -sverilog fetch.v fetch_tb.v decode.v execute.v memory.v writeback.v -o cpu_sim

# 2. 运行
./cpu_sim

# 3. 查看波形（如果生成了VCD文件）
dve -vpd cpu.vpd
```

### 与其他阶段的接口
- 输出接口可直接连接到Decode阶段
- valP作为下一周期PC值的候选
- instr_valid用于流水线控制

## 文件列表

```
y86/
├── fetch.v                    # 核心模块
├── fetch_tb.v                 # 基础testbench
├── fetch_tb_enhanced.v        # 增强testbench (推荐)
├── run_vcs.sh                 # 运行脚本
└── README.md                  # 本文件
```

## 版本信息

- **模块名**: fetchC
- **Verilog版本**: IEEE 1364-2001及以上
- **VCS兼容**: ⚠️ VCS 2018需要解决PIE问题；VCS 2019+完全兼容
- **Vivado兼容**: ✅ 是
- **iverilog兼容**: ✅ 是（✅推荐）
- **推荐工具**: iverilog/vvp（最稳定、最兼容）

## 许可证

此项目为教学示例代码。可自由使用和修改。
