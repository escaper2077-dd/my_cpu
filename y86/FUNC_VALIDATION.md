# Y86 Fetch Stage Func Validation Implementation

## 总结

已为 `fetch.v` 实现了对不同指令码 (icode) 下的功能码 (func) 的验证处理。

## 实现内容

### 1. 指令码和功能码定义
在 fetch.v 中添加了：
- **ALU 功能码** (icode=0x6): 
  - 0x0: ADDL (加法)
  - 0x1: SUBL (减法)
  - 0x2: ANDL (逻辑与)
  - 0x3: XORL (逻辑异或)

- **JXX 功能码** (icode=0x7):
  - 0x0: JMP  (无条件跳转)
  - 0x1: JLE  (小于等于)
  - 0x2: JL   (小于)
  - 0x3: JE   (等于)
  - 0x4: JNE  (不等于)
  - 0x5: JGE  (大于等于)
  - 0x6: JG   (大于)

### 2. 功能码验证逻辑
```verilog
valid_ifun = ((icode_o == ALU) && (ifun_o >= 4'h0 && ifun_o <= 4'h3)) ||  // ALU: func 0-3
             ((icode_o == JXX) && (ifun_o >= 4'h0 && ifun_o <= 4'h6)) ||  // JXX: func 0-6
             ((icode_o != ALU) && (icode_o != JXX) && (ifun_o == 4'h0));  // 其他指令: func=0

instr_valid_o = (icode_o < 4'hC) && valid_ifun;
```

### 3. 验证规则
- **ALU指令** (icode=0x6): func 必须在 0-3 范围内
- **JXX指令** (icode=0x7): func 必须在 0-6 范围内
- **其他指令** (NOP, HALT, RRMOVL等): func 必须为 0

若指令违反这些规则，`instr_valid_o` 会置为 0（无效指令）

## 测试验证

创建了 `fetch_func_tb.v` 测试模块，验证所有情况：
- ✓ 有效的ALU功能码 (0-3)
- ✓ 无效的ALU功能码 (4-15)
- ✓ 有效的JXX功能码 (0-6)
- ✓ 无效的JXX功能码 (7-15)
- ✓ 其他指令的func=0 (有效)
- ✓ 其他指令的func≠0 (无效)

所有测试**全部通过**。

## 文件修改
- **fetch.v**: 添加func码定义和验证逻辑
- **fetch_func_tb.v**: 新增测试文件 (共18个测试用例)

## 后续集成
修改后的 fetch.v 与现有的 decode.v 和 cpu_tb.v **完全兼容**，所有之前的测试仍能正常通过。
