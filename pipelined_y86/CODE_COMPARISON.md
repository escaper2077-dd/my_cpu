# Y86 vs Pipelined Y86 代码详细对比

## 一、架构设计根本差异

### 1. CPU架构类型
**Y86 (单周期)**
- 单周期设计：每条指令在一个时钟周期内完成所有阶段
- 顺序执行：一条指令完成后才能开始下一条
- CPI = 1（每条指令1个周期）
- 时钟周期必须适应最慢的指令

**Pipelined Y86 (五级流水线)**
- 五级流水线：F → D → E → M → W
- 并行执行：最多5条指令同时处于不同阶段
- 理想CPI接近0.2（考虑冒险后会更高）
- 时钟周期可以更短

---

## 二、模块组织差异

### 2. 文件结构对比

#### Y86 (6个核心模块)
```
y86_cpu.v (135行)           - 顶层模块，连接各阶段
├── fetch.v (121行)          - 取指阶段
├── decode.v (218行)         - 译码阶段（含寄存器文件）
├── execute.v (183行)        - 执行阶段（含ALU和CC）
├── memory_access.v (130行)  - 访存阶段
├── write_back.v (36行)      - 写回阶段
└── pc_update.v (77行)       - PC更新逻辑
```

#### Pipelined Y86 (12个核心模块)
```
pipelined_y86_cpu.v (301行)          - 顶层模块
├── pipe_stage_fetch.v (98行)         - F阶段
├── pipe_stage_decode.v (171行)       - D阶段（含寄存器文件）
├── pipe_stage_execute.v (191行)      - E阶段（含ALU、CC和转发）
├── pipe_stage_memory.v (117行)        - M阶段
├── pipe_stage_writeback.v (24行)      - W阶段
├── pipe_reg_fd.v (55行)               - F/D流水线寄存器
├── pipe_reg_de.v (69行)               - D/E流水线寄存器
├── pipe_reg_em.v (61行)               - E/M流水线寄存器
├── pipe_reg_mw.v (48行)               - M/W流水线寄存器
├── pipe_pc_logic.v (58行)             - PC选择逻辑
└── pipe_control.v (60行)              - 流水线控制（冒险检测）
```

**关键差异：**
- Y86：6个模块（5个阶段 + PC更新）
- Pipelined Y86：12个模块（5个阶段 + 4个流水线寄存器 + 2个控制逻辑）
- 流水线版本增加了 **4个流水线寄存器模块** 和 **独立的控制逻辑模块**

---

## 三、顶层模块差异

### 3. y86_cpu.v vs pipelined_y86_cpu.v

#### Y86 顶层 (135行)
```verilog
module y86_cpu(
    input wire clk_i,
    input wire rst_n_i,
    output wire [1:0] stat_o,
    output wire [63:0] PC_o,
    output wire [3:0] icode_o
);

// 简单的阶段间连接信号（10-15个）
wire [63:0] PC;           // PC
wire [3:0] icode, ifun;   // 指令字段
wire [63:0] valA, valB, valC, valE, valM;  // 数据
wire Cnd;                 // 条件码结果

// 直接实例化5个阶段模块 + 1个PC更新模块
fetch fetch_stage(...);
decode decode_stage(...);
execute execute_stage(...);
memory_access memory_stage(...);
write_back writeback_stage(...);
pc_update pc_update_stage(...);
```

#### Pipelined Y86 顶层 (301行)
```verilog
module pipelined_y86_cpu(
    input wire clk_i,
    input wire rst_n_i,
    output wire [1:0] cpu_stat_o
);

// 复杂的流水线寄存器信号（60+个）
// F阶段输出 (7个)
wire [1:0] f_stat;
wire [3:0] f_icode, f_ifun, f_rA, f_rB;
wire [63:0] f_valC, f_valP;

// F/D寄存器 (7个)
wire [1:0] D_stat;
wire [3:0] D_icode, D_ifun, D_rA, D_rB;
wire [63:0] D_valC, D_valP;

// D阶段输出 (11个)
// D/E寄存器 (11个)
// E阶段输出 (10个)
// E/M寄存器 (10个)
// M阶段输出 (7个)
// M/W寄存器 (7个)
// W阶段输出 (1个)

// 控制信号 (4个)
wire F_stall, D_stall, D_bubble, E_bubble;

// CPU状态保持寄存器
reg [1:0] cpu_stat_reg;

// 实例化12个模块
pipe_pc_logic pc_logic(...);           // PC选择
pipe_stage_fetch fetch_stage(...);     // F阶段
pipe_reg_fd fd_reg(...);               // F/D寄存器
pipe_stage_decode decode_stage(...);   // D阶段
pipe_reg_de de_reg(...);               // D/E寄存器
pipe_stage_execute execute_stage(...); // E阶段
pipe_reg_em em_reg(...);               // E/M寄存器
pipe_stage_memory memory_stage(...);   // M阶段
pipe_reg_mw mw_reg(...);               // M/W寄存器
pipe_stage_writeback writeback_stage(...); // W阶段
pipe_control control(...);             // 控制逻辑
```

**主要差异：**
1. **信号数量**：Y86 约15个，Pipelined约60+个
2. **模块数量**：Y86 6个，Pipelined 12个
3. **状态保持**：Pipelined需要保持非AOK状态（避免被覆盖）
4. **控制复杂度**：Pipelined需要显式冒险控制

---

## 四、各阶段详细对比

### 4. Fetch 阶段

#### Y86 fetch.v (121行)
```verilog
module fetch(
    input wire clk_i,
    input wire rst_n_i,
    input wire [63:0] PC_i,
    
    output wire [3:0] icode_o, ifun_o, rA_o, rB_o,
    output wire [63:0] valC_o, valP_o,
    output wire instr_valid_o, imem_error_o
);

// 纯组合逻辑
// - 从PC读取指令内存
// - 解析指令字段
// - 计算valP（下一条指令地址）
// - 没有预测逻辑

assign instr = {instr_mem[PC_i+9], ..., instr_mem[PC_i]};
assign icode_o = instr[7:4];
assign ifun_o = instr[3:0];
// 根据指令类型解析rA, rB, valC
// 计算valP = PC + 1 + need_regids + need_valC*8
```

#### Pipelined pipe_stage_fetch.v (98行)
```verilog
module pipe_stage_fetch(
    input wire [63:0] f_pc,  // 来自PC选择逻辑
    
    output wire [1:0] f_stat,
    output wire [3:0] f_icode, f_ifun, f_rA, f_rB,
    output wire [63:0] f_valC, f_valP,
    output wire [63:0] f_predPC  // 预测的下一个PC
);

// 纯组合逻辑
// - 从f_pc读取指令
// - 解析指令字段
// - 计算valP
// - **新增**：简单分支预测（总是预测不跳转）

assign f_predPC = f_valP;  // 简单预测器：预测顺序执行
```

**差异：**
1. **输入**：Y86从外部接收PC，Pipelined从PC选择逻辑接收
2. **预测**：Pipelined增加了f_predPC输出（分支预测）
3. **时序**：两者都是组合逻辑，但Pipelined的输出会被流水线寄存器锁存

---

### 5. Decode 阶段

#### Y86 decode.v (218行)
```verilog
module decode(
    input wire clk_i, rst_n_i,
    input wire [3:0] icode_i, rA_i, rB_i,
    
    // 来自Write-back的写回信号（同周期）
    input wire [63:0] valE_i, valM_i,
    input wire cnd_i,
    
    output wire [63:0] valA_o, valB_o
);

// 寄存器文件
reg [63:0] regfile[14:0];

// 读寄存器（组合逻辑）
always @(*) begin
    case (icode_i)
        RRMOVL: srcA = rA_i; srcB = rB_i;
        // ...
    endcase
end

assign valA_o = (srcA == 4'hF) ? 64'd0 : regfile[srcA];
assign valB_o = (srcB == 4'hF) ? 64'd0 : regfile[srcB];

// 写寄存器（时序逻辑，同周期写回）
reg [3:0] dstE, dstM;
always @(*) begin
    case (icode_i)
        RRMOVL: dstE = (cnd_i) ? rB_i : 4'hF;
        // ...
    endcase
end

always @(posedge clk_i or negedge rst_n_i) begin
    if (!rst_n_i) begin
        // reset
    end else begin
        if (dstE != 4'hF) regfile[dstE] <= valE_i;
        if (dstM != 4'hF) regfile[dstM] <= valM_i;
    end
end
```

#### Pipelined pipe_stage_decode.v (171行)
```verilog
module pipe_stage_decode(
    input wire clk_i, rst_n_i,
    
    // 来自D流水线寄存器
    input wire [1:0] D_stat,
    input wire [3:0] D_icode, D_ifun, D_rA, D_rB,
    input wire [63:0] D_valC, D_valP,
    
    // 来自W阶段的写回（3个周期后）
    input wire [3:0] W_dstE, W_dstM,
    input wire [63:0] W_valE, W_valM,
    
    output wire [1:0] d_stat,
    output wire [3:0] d_icode, d_ifun,
    output wire [63:0] d_valC, d_valP, d_valA, d_valB,
    output wire [3:0] d_dstE, d_dstM,  // 传递目的寄存器
    output wire [3:0] d_srcA, d_srcB   // 传递源寄存器（用于转发）
);

// 寄存器文件
reg [63:0] reg_file[0:14];

// 源寄存器选择（组合逻辑）
always @(*) begin
    case (D_icode)
        RRMOVL, IRMOVL, RMMOVL, ALU: 
            srcA = D_rA; srcB = D_rB;
        // ...
    endcase
end

// 读寄存器（组合逻辑）
assign d_valA = (srcA == 4'hF) ? 64'd0 : reg_file[srcA];
assign d_valB = (srcB == 4'hF) ? 64'd0 : reg_file[srcB];

// 目的寄存器选择（组合逻辑，传递给E阶段）
always @(*) begin
    case (D_icode)
        RRMOVL: dstE = D_rB; dstM = 4'hF;
        IRMOVL: dstE = D_rB; dstM = 4'hF;
        // ...
    endcase
end

// 写寄存器（时序逻辑，从W阶段写回）
always @(posedge clk_i or negedge rst_n_i) begin
    if (!rst_n_i) begin
        // reset
    end else begin
        if (W_dstE != 4'hF) reg_file[W_dstE] <= W_valE;
        if (W_dstM != 4'hF) reg_file[W_dstM] <= W_valM;
    end
end
```

**关键差异：**
1. **写回时机**：
   - Y86：同周期写回（valE_i和valM_i来自当前周期的execute/memory）
   - Pipelined：3周期后写回（W_valE和W_valM来自3个周期前的指令）

2. **目的寄存器传递**：
   - Y86：在decode内部计算dstE/dstM，用于当前写回
   - Pipelined：输出d_dstE/d_dstM，传递给后续阶段用于转发检测

3. **源寄存器传递**：
   - Y86：不需要传递srcA/srcB
   - Pipelined：输出d_srcA/d_srcB，用于E阶段的转发逻辑

---

### 6. Execute 阶段

#### Y86 execute.v (183行)
```verilog
module execute(
    input wire clk_i, rst_n_i,
    input wire [3:0] icode_i, ifun_i,
    input wire [63:0] valA_i, valB_i, valC_i,
    
    output reg [63:0] valE_o,
    output wire Cnd_o
);

// 条件码寄存器
reg ZF, SF, OF;

// ALU（组合逻辑）
assign alu_out = (ifun_i == ALU_ADDL) ? (valB_i + valA_i) :
                 (ifun_i == ALU_SUBL) ? (valB_i - valA_i) :
                 // ...

// 条件码更新（时序逻辑）
always @(posedge clk_i or negedge rst_n_i) begin
    if (!rst_n_i) begin
        ZF <= 1'b1; SF <= 1'b0; OF <= 1'b0;
    end else if (icode_i == ALU) begin
        ZF <= (alu_out == 64'b0);
        SF <= alu_out[63];
        OF <= /* overflow logic */;
    end
end

// 条件评估（组合逻辑）
always @(*) begin
    case (ifun_i)
        RRMOV_RRMOVL: cond = 1'b1;
        RRMOV_CMOVLE: cond = (SF ^ OF) | ZF;
        // ...
    endcase
end

// valE计算（组合逻辑）
always @(*) begin
    case (icode_i)
        ALU: valE_o = alu_out;
        RRMOVL: valE_o = valA_i;
        IRMOVL: valE_o = valC_i;
        // ...
    endcase
end
```

#### Pipelined pipe_stage_execute.v (191行)
```verilog
module pipe_stage_execute(
    input wire clk_i, rst_n_i,
    input wire E_bubble,  // 控制信号：禁止CC更新
    
    // 来自E流水线寄存器
    input wire [1:0] E_stat,
    input wire [3:0] E_icode, E_ifun,
    input wire [63:0] E_valC, E_valP, E_valA, E_valB,
    input wire [3:0] E_dstE, E_dstM, E_srcA, E_srcB,
    
    // 数据转发输入（从M和W阶段）
    input wire [63:0] M_valE,
    input wire [3:0] M_dstE, M_dstM,
    input wire [63:0] W_valE, W_valM,
    input wire [3:0] W_dstE, W_dstM,
    
    output wire [1:0] e_stat,
    output wire [3:0] e_icode,
    output wire [63:0] e_valA, e_valE, e_valC, e_valP,
    output wire [3:0] e_dstE, e_dstM,
    output wire e_Cnd
);

// 条件码寄存器
reg ZF, SF, OF;

// **新增**：数据转发逻辑（Select A/B）
assign aluA = (E_srcA != 4'hF && E_srcA == M_dstE) ? M_valE :
              (E_srcA != 4'hF && E_srcA == W_dstM) ? W_valM :
              (E_srcA != 4'hF && E_srcA == W_dstE) ? W_valE :
              E_valA;

assign aluB = (E_srcB != 4'hF && E_srcB == M_dstE) ? M_valE :
              (E_srcB != 4'hF && E_srcB == W_dstM) ? W_valM :
              (E_srcB != 4'hF && E_srcB == W_dstE) ? W_valE :
              E_valB;

// ALU（使用转发后的操作数）
assign alu_out = (E_ifun == ALU_ADDL) ? (aluB + aluA) :
                 // ...

// **修改**：条件码更新（考虑E_bubble）
wire set_cc;
assign set_cc = (E_icode == ALU) && !E_bubble;

always @(posedge clk_i or negedge rst_n_i) begin
    if (!rst_n_i) begin
        ZF <= 1'b0; SF <= 1'b0; OF <= 1'b0;
    end else if (set_cc) begin
        ZF <= (alu_out == 64'h0);
        SF <= alu_out[63];
        OF <= /* overflow logic */;
    end
end

// 条件评估（同Y86）
// valE计算（同Y86）

// **新增**：dstE条件取消（RRMOVL条件不满足时）
assign e_dstE = (E_icode == RRMOVL && !cond) ? 4'hF : E_dstE;

// 传递信号
assign e_valA = aluA;  // 转发后的valA
```

**关键差异：**
1. **数据转发**：
   - Y86：无（直接使用decode的输出）
   - Pipelined：Select A/B逻辑，从M和W阶段转发数据

2. **条件码更新控制**：
   - Y86：只要是ALU指令就更新
   - Pipelined：ALU指令且不是bubble时才更新（避免被取消的指令更新CC）

3. **dstE条件取消**：
   - Y86：在decode阶段根据Cnd决定是否写回
   - Pipelined：在execute阶段根据cond决定，取消时设dstE=0xF

4. **转发valA**：
   - Y86：不需要
   - Pipelined：e_valA输出转发后的值（用于M阶段的JXX分支地址）

---

### 7. Memory 阶段

#### Y86 memory_access.v (130行)
```verilog
module memory_access(
    input wire clk_i, rst_n_i,
    input wire [3:0] icode_i,
    input wire [63:0] valE_i, valA_i, valP_i,
    
    output wire [63:0] valM_o,
    output wire dmem_error_o
);

// 数据内存
reg [7:0] data_mem[0:1023];

// 内存地址计算
assign mem_addr = (icode_i == RMMOVL || icode_i == PUSHL) ? valE_i :
                  (icode_i == MRMOVL || icode_i == POPL) ? valA_i :
                  (icode_i == CALL) ? valE_i :
                  (icode_i == RET) ? valA_i :
                  64'd0;

// 内存读写控制
assign mem_read = (icode_i == MRMOVL || icode_i == POPL || 
                   icode_i == RET);
assign mem_write = (icode_i == RMMOVL || icode_i == PUSHL || 
                    icode_i == CALL);

// 内存操作（时序逻辑）
always @(posedge clk_i or negedge rst_n_i) begin
    if (!rst_n_i) begin
        // reset
    end else begin
        if (mem_write) begin
            // 写8字节
            data_mem[mem_addr] <= valA_i[7:0];
            data_mem[mem_addr+1] <= valA_i[15:8];
            // ...
        end
    end
end

// 内存读取（组合逻辑）
assign valM_o = mem_read ? 
    {data_mem[mem_addr+7], ..., data_mem[mem_addr]} : 64'd0;
```

#### Pipelined pipe_stage_memory.v (117行)
```verilog
module pipe_stage_memory(
    input wire clk_i, rst_n_i,
    
    // 来自M流水线寄存器
    input wire [1:0] M_stat,
    input wire [3:0] M_icode,
    input wire [63:0] M_valE, M_valA,
    input wire [3:0] M_dstE, M_dstM,
    
    output wire [1:0] m_stat,
    output wire [3:0] m_icode,
    output wire [63:0] m_valE, m_valM,
    output wire [3:0] m_dstE, m_dstM
);

// 数据内存（同Y86）
reg [7:0] dmem[0:255];

// 内存地址、读写控制（同Y86逻辑）
wire [63:0] mem_addr;
wire mem_read, mem_write;

// 内存操作（时序逻辑，同Y86）
// 内存读取（组合逻辑，同Y86）

// **直通信号**
assign m_stat = M_stat;
assign m_icode = M_icode;
assign m_valE = M_valE;  // 传递valE
assign m_valM = valM;    // 内存读取结果
assign m_dstE = M_dstE;  // 传递目的寄存器
assign m_dstM = M_dstM;
```

**差异较小：**
1. **输入输出**：Pipelined需要传递更多信号给下一阶段
2. **内存大小**：Y86 1KB (0:1023)，Pipelined 256B (0:255)
3. **核心逻辑**：内存访问逻辑基本相同

---

### 8. Write Back 阶段

#### Y86 write_back.v (36行)
```verilog
module write_back(
    input wire clk_i, rst_n_i,
    input wire [3:0] icode_i,
    input wire [63:0] valE_i, valM_i,
    input wire instr_valid_i, imem_error_i, dmem_error_i,
    
    output wire [63:0] valE_o, valM_o,
    output reg [1:0] stat_o
);

// 状态码定义
localparam STAT_AOK = 2'b00;
localparam STAT_HLT = 2'b01;
localparam STAT_ADR = 2'b10;
localparam STAT_INS = 2'b11;

// valE和valM直通（用于decode写回）
assign valE_o = valE_i;
assign valM_o = valM_i;

// 状态计算（时序逻辑）
always @(posedge clk_i or negedge rst_n_i) begin
    if (!rst_n_i) begin
        stat_o <= STAT_AOK;
    end else begin
        if (!instr_valid_i) stat_o <= STAT_INS;
        else if (imem_error_i || dmem_error_i) stat_o <= STAT_ADR;
        else if (icode_i == HALT) stat_o <= STAT_HLT;
        else stat_o <= STAT_AOK;
    end
end
```

#### Pipelined pipe_stage_writeback.v (24行)
```verilog
module pipe_stage_writeback(
    // 来自W流水线寄存器
    input wire [1:0] W_stat,
    input wire [3:0] W_icode,
    
    output wire [1:0] w_stat
);

// 状态码定义
localparam HALT = 4'h1;
localparam STAT_HLT = 2'b01;

// 状态计算（纯组合逻辑）
assign w_stat = (W_icode == HALT) ? STAT_HLT : W_stat;
```

**关键差异：**
1. **复杂度**：
   - Y86：36行，处理所有错误状态
   - Pipelined：24行，只处理HALT

2. **时序**：
   - Y86：时序逻辑（寄存器）
   - Pipelined：组合逻辑

3. **错误处理**：
   - Y86：在writeback统一处理所有错误
   - Pipelined：错误状态在各阶段产生并传递

4. **数据传递**：
   - Y86：输出valE_o和valM_o用于decode写回
   - Pipelined：valE和valM由D阶段直接从W信号获取

---

### 9. PC更新逻辑

#### Y86 pc_update.v (77行)
```verilog
module pc_update(
    input wire clk_i, rst_n_i,
    input wire [3:0] icode_i,
    input wire cnd_i,
    input wire [63:0] valC_i, valM_i, valP_i,
    input wire [1:0] stat_i,
    
    output reg [63:0] PC_o
);

// PC更新逻辑（时序逻辑）
always @(posedge clk_i or negedge rst_n_i) begin
    if (!rst_n_i) begin
        PC_o <= 64'd0;
    end else if (stat_i == STAT_AOK) begin
        case (icode_i)
            CALL: PC_o <= valC_i;     // 跳转到子程序
            RET: PC_o <= valM_i;      // 返回地址
            JXX: PC_o <= cnd_i ? valC_i : valP_i;  // 条件跳转
            default: PC_o <= valP_i;  // 顺序执行
        endcase
    end
    // 非AOK状态不更新PC
end
```

#### Pipelined pipe_pc_logic.v (58行)
```verilog
module pipe_pc_logic(
    input wire clk_i, rst_n_i,
    
    // 来自F阶段的预测PC
    input wire [63:0] f_predPC,
    
    // 来自M阶段的分支信息
    input wire [3:0] M_icode,
    input wire M_Cnd,
    input wire [63:0] M_valC,  // JXX跳转目标
    input wire [63:0] M_valA,  // JXX顺序地址
    
    // 来自W阶段的返回地址
    input wire [3:0] W_icode,
    input wire [63:0] W_valM,  // RET返回地址
    
    // 流水线控制信号
    input wire F_stall,
    
    output reg [63:0] f_pc
);

// **Select PC逻辑**（组合逻辑，分支预测处理）
wire [63:0] new_pc;

assign new_pc = 
    // 分支预测错误：需要跳转但预测为不跳转
    (M_icode == JXX && M_Cnd) ? M_valC :
    // RET指令
    (W_icode == RET) ? W_valM :
    // 正常：使用预测PC（对于不跳转的JXX，predPC已经正确）
    f_predPC;

// PC更新（时序逻辑）
always @(posedge clk_i or negedge rst_n_i) begin
    if (!rst_n_i) begin
        f_pc <= 64'h0;
    end else if (!F_stall) begin
        f_pc <= new_pc;
    end
    // F_stall时保持PC
end
```

**关键差异：**
1. **预测机制**：
   - Y86：无预测，根据当前指令直接计算下一PC
   - Pipelined：简单预测器 + 错误修正机制

2. **输入来源**：
   - Y86：来自当前周期的所有阶段
   - Pipelined：来自M阶段（JXX）、W阶段（RET）、F阶段（预测）

3. **分支处理**：
   - Y86：在同一周期根据Cnd选择PC
   - Pipelined：
     - 预测不跳转（使用valP）
     - M阶段发现应该跳转（M_Cnd=1）时修正为valC
     - 需要取消D和E阶段的指令（插入bubble）

4. **RET处理**：
   - Y86：从当前周期的memory_stage获取返回地址
   - Pipelined：从W阶段获取返回地址（3个周期后）

5. **Stall支持**：
   - Y86：无stall机制
   - Pipelined：F_stall信号控制是否更新PC

---

## 五、流水线专有模块

### 10. 流水线寄存器（Y86无此模块）

#### pipe_reg_fd.v (55行)
```verilog
module pipe_reg_fd(
    input wire clk_i, rst_n_i,
    input wire stall,   // 阻塞信号
    input wire bubble,  // 气泡信号
    
    // F阶段输出
    input wire [1:0] f_stat,
    input wire [3:0] f_icode, f_ifun, f_rA, f_rB,
    input wire [63:0] f_valC, f_valP,
    
    // D阶段输入
    output reg [1:0] D_stat,
    output reg [3:0] D_icode, D_ifun, D_rA, D_rB,
    output reg [63:0] D_valC, D_valP
);

always @(posedge clk_i or negedge rst_n_i) begin
    if (!rst_n_i || bubble) begin
        // 插入NOP
        D_stat <= STAT_AOK;
        D_icode <= NOP;
        // ...
    end else if (!stall) begin
        // 正常更新
        D_stat <= f_stat;
        D_icode <= f_icode;
        // ...
    end
    // stall时保持原值
end
```

**功能：**
- 在时钟上升沿锁存F阶段的输出
- 支持stall（保持）和bubble（插入NOP）
- 类似的还有 pipe_reg_de, pipe_reg_em, pipe_reg_mw

---

### 11. 流水线控制逻辑（Y86无此模块）

#### pipe_control.v (60行)
```verilog
module pipe_control(
    // 来自各阶段的信号
    input wire [3:0] D_icode, E_icode, M_icode,
    input wire [3:0] E_dstM,
    input wire [3:0] d_srcA, d_srcB,
    input wire M_Cnd,
    
    // 输出控制信号
    output wire F_stall,   // F阶段stall
    output wire D_stall,   // D阶段stall
    output wire D_bubble,  // D阶段bubble
    output wire E_bubble   // E阶段bubble
);

// **Load-Use冒险检测**
wire load_use_hazard;
assign load_use_hazard = 
    ((E_icode == MRMOVL || E_icode == POPL) &&
     (E_dstM == d_srcA || E_dstM == d_srcB) &&
     (E_dstM != 4'hF));

// **分支预测错误检测**
wire mispredicted;
assign mispredicted = (M_icode == JXX && M_Cnd);

// **RET冒险检测**
wire ret_hazard;
assign ret_hazard = (D_icode == RET || E_icode == RET || 
                     M_icode == RET);

// **控制信号生成**
assign F_stall = load_use_hazard || ret_hazard;
assign D_stall = load_use_hazard;
assign D_bubble = mispredicted || (!D_stall && ret_hazard);
assign E_bubble = mispredicted || load_use_hazard;
```

**功能：**
1. **Load-Use冒险**：E阶段的load指令，D阶段的指令需要该数据
   - 解决：F/D阶段stall 1周期，E阶段插入bubble
   
2. **分支预测错误**：M阶段JXX需要跳转但预测为不跳转
   - 解决：D/E阶段插入bubble（取消2条指令）

3. **RET冒险**：返回地址未就绪
   - 解决：F/D阶段stall直到RET到达W阶段

---

## 六、关键技术差异总结

### 12. 数据通路差异

#### Y86 数据通路
```
PC → Fetch → Decode → Execute → Memory → WriteBack
              ↑                              ↓
              └──────── valE, valM ──────────┘
              └──────── Cnd ─────────────────┘
```
- 单向数据流
- 写回信号直接反馈到decode
- 所有操作在一个时钟周期内完成

#### Pipelined Y86 数据通路
```
           ┌─ F_stall
           ↓
PC → F ═══→ D ═══→ E ═══→ M ═══→ W
     │      │      ↑      │      │
     │      │      │      │      │
     │      │      └──M_valE────┘└─W_valE
     │      │      └──M_dstE      └─W_valM
     │      │                      └─W_dstM
     │      └─ D_stall, D_bubble
     │
     └─ f_predPC
        ↑
        └─ Select PC (M_valC, W_valM)
```
- 多级数据流，带流水线寄存器
- 数据转发路径（M→E, W→E）
- 控制冒险和数据冒险处理
- PC选择逻辑独立

---

### 13. 性能分析

#### Y86 (单周期)
- **CPI**: 1（每条指令1个周期）
- **时钟周期**：必须容纳最慢的指令路径（~100-150ps模拟）
- **吞吐量**：1 指令/周期
- **延迟**：1 周期/指令

#### Pipelined Y86 (五级流水线)
- **理想CPI**: 1（稳定状态下每周期完成1条指令）
- **实际CPI**: ~1.2-1.5（考虑冒险）
  - Load-Use冒险：stall 1周期
  - 分支预测错误：损失2周期
  - RET冒险：stall直到完成
- **时钟周期**：只需容纳最慢的单个阶段（~50ps模拟）
- **吞吐量**：理论上2倍于Y86（时钟周期更短）
- **延迟**：5个周期/指令（但吞吐量高）

**测试结果对比**：
- Y86 comprehensive test：未记录，估计~200-300 cycles
- Pipelined comprehensive test：~70 cycles @ 100ps = 7050ps
  - 包含289字节指令
  - 有多次分支、CALL/RET和load-use情况

---

### 14. 复杂度对比

| 项目 | Y86 | Pipelined Y86 | 增加量 |
|------|-----|---------------|--------|
| 模块数量 | 6 | 12 | +100% |
| 流水线寄存器 | 0 | 4 | +4 |
| 控制逻辑模块 | 1 (pc_update) | 2 (pc_logic + control) | +1 |
| 顶层信号 | ~15 | ~60 | +300% |
| 总代码行数 | ~900 | ~1,250 | +39% |
| 寄存器个数 | ~25 | ~120 | +380% |

---

### 15. 测试差异

#### Y86测试文件
- `y86_cpu_tb.v` → 基本测试
- `y86_cpu_comprehensive_tb_v6.v` (765行) → 完整测试
  - 详细打印每条指令
  - 289字节程序

#### Pipelined Y86测试文件
- `pipelined_y86_comprehensive_tb.v` (660行) → 完整测试
  - 基于v6改写
  - 相同的289字节程序
  - 简化的输出（指令摘要）
  - 增加了bubble和控制信号监控

---

## 七、设计理念差异

### 16. Y86设计理念
**教学导向的单周期设计**
- 简单直观：一条指令的执行路径清晰可见
- 易于理解：所有操作在一个时钟周期完成
- 调试友好：信号直接连接，因果关系明确
- 性能较低：时钟周期长，无并行性

### 17. Pipelined Y86设计理念
**实用导向的流水线设计**
- 高性能：指令级并行，提高吞吐量
- 复杂控制：需要处理三种冒险
- 数据转发：减少stall开销
- 预测机制：简单分支预测
- 更接近现代CPU：多数现代CPU都是流水线架构

---

## 八、不同点分类汇总

### A. 架构差异（最根本）
1. 单周期 vs 五级流水线
2. 顺序执行 vs 指令级并行
3. 无冒险 vs 三种冒险（数据、控制、结构）

### B. 模块差异
1. 6个模块 vs 12个模块
2. 无流水线寄存器 vs 4个流水线寄存器
3. 简单PC更新 vs 复杂PC选择 + 预测
4. 无冒险控制 vs 专门的control模块

### C. 数据通路差异
1. 直接反馈 vs 多级传递
2. 无转发 vs M→E, W→E转发
3. 同周期写回 vs 延迟3周期写回

### D. 控制逻辑差异
1. 无stall vs F_stall, D_stall
2. 无bubble vs D_bubble, E_bubble
3. 直接PC计算 vs 预测+修正机制

### E. 时序差异
1. 所有操作同周期 vs 跨多周期
2. 组合逻辑为主 vs 时序逻辑为主
3. 无流水线寄存器 vs 多个流水线寄存器

### F. 实现细节差异
1. Decode写回逻辑不同（当前周期 vs W阶段）
2. Execute的CC更新控制（始终更新 vs 考虑bubble）
3. Execute的dstE取消逻辑位置不同
4. Memory阶段基本相同，但信号传递不同
5. WriteBack简单化（24行 vs 36行）

### G. 性能差异
1. CPI: 1 vs ~1.2-1.5
2. 时钟周期: 长 vs 短（约2倍）
3. 总体性能: 流水线约1.3-1.5倍单周期

### H. 代码量差异
1. 总行数: 900行 vs 1250行 (+39%)
2. 代码复杂度: 简单 vs 中等
3. 调试难度: 低 vs 中

---

## 九、总结

**Y86**是一个**教学用单周期CPU**，设计简洁，易于理解，适合学习计算机组成原理的基本概念。

**Pipelined Y86**是一个**实用的流水线CPU**，引入了现代CPU的核心技术（流水线、数据转发、分支预测、冒险处理），性能更高，但复杂度也显著增加。

两者最大的区别在于：
1. **架构级别**：单周期 vs 流水线
2. **并行性**：无 vs 5条指令并行
3. **冒险处理**：无 vs 完整的冒险检测和处理
4. **数据转发**：无 vs M→E, W→E转发
5. **性能**：低 vs 高（约1.5倍）

这种对比清晰地展示了从简单到复杂、从教学到实用的CPU设计演进过程。
