`timescale 1ps/1ps

// ============================================================================
// RISC-V 五级流水线 CPU - 冒险检测与转发单元
// 功能：
//   1. 数据转发 (Forwarding/Bypassing)
//   2. Load-Use 冒险检测与暂停
//   3. 控制冒险处理 (分支/跳转)
// ============================================================================

module hazard_unit(
    // ID 阶段信号
    input wire [4:0]  id_rs1,
    input wire [4:0]  id_rs2,
    input wire [6:0]  id_opcode,
    
    // EX 阶段信号
    input wire [4:0]  ex_rd,
    input wire [6:0]  ex_opcode,
    input wire        ex_branch_taken,
    
    // MEM 阶段信号
    input wire [4:0]  mem_rd,
    input wire [6:0]  mem_opcode,
    
    // WB 阶段信号
    input wire [4:0]  wb_rd,
    input wire        wb_reg_wr_en,
    
    // 控制信号输出
    output wire [1:0] forward_a,      // rs1 转发控制: 00=无, 01=EX, 10=MEM, 11=WB
    output wire [1:0] forward_b,      // rs2 转发控制
    output wire       stall_if,       // IF 阶段暂停
    output wire       stall_id,       // ID 阶段暂停
    output wire       flush_if_id,    // IF/ID 寄存器冲刷
    output wire       flush_id_ex,    // ID/EX 寄存器冲刷
    output wire       flush_ex_mem    // EX/MEM 寄存器冲刷
);

    // 操作码定义
    localparam OP_LOAD   = 7'b0000011;
    localparam OP_STORE  = 7'b0100011;
    localparam OP_BRANCH = 7'b1100011;
    localparam OP_JAL    = 7'b1101111;
    localparam OP_JALR   = 7'b1100111;
    localparam OP_ALU    = 7'b0110011;
    localparam OP_ALUI   = 7'b0010011;
    localparam OP_LUI    = 7'b0110111;
    localparam OP_AUIPC  = 7'b0010111;

    // ==================== 数据转发逻辑 ====================
    // EX 阶段是否会写寄存器
    wire ex_will_write;
    assign ex_will_write = (ex_opcode == OP_ALU || ex_opcode == OP_ALUI || 
                           ex_opcode == OP_LUI || ex_opcode == OP_AUIPC ||
                           ex_opcode == OP_LOAD || ex_opcode == OP_JAL || 
                           ex_opcode == OP_JALR) && (ex_rd != 5'd0);
    
    // MEM 阶段是否会写寄存器
    wire mem_will_write;
    assign mem_will_write = (mem_opcode == OP_ALU || mem_opcode == OP_ALUI || 
                            mem_opcode == OP_LUI || mem_opcode == OP_AUIPC ||
                            mem_opcode == OP_LOAD || mem_opcode == OP_JAL || 
                            mem_opcode == OP_JALR) && (mem_rd != 5'd0);

    // rs1 转发控制
    reg [1:0] forward_a_reg;
    always @(*) begin
        if (ex_will_write && (ex_rd == id_rs1) && (id_rs1 != 5'd0))
            forward_a_reg = 2'b01;  // 从 EX 阶段转发
        else if (mem_will_write && (mem_rd == id_rs1) && (id_rs1 != 5'd0))
            forward_a_reg = 2'b10;  // 从 MEM 阶段转发
        else if (wb_reg_wr_en && (wb_rd == id_rs1) && (id_rs1 != 5'd0))
            forward_a_reg = 2'b11;  // 从 WB 阶段转发
        else
            forward_a_reg = 2'b00;  // 无需转发
    end
    assign forward_a = forward_a_reg;

    // rs2 转发控制
    reg [1:0] forward_b_reg;
    always @(*) begin
        if (ex_will_write && (ex_rd == id_rs2) && (id_rs2 != 5'd0))
            forward_b_reg = 2'b01;  // 从 EX 阶段转发
        else if (mem_will_write && (mem_rd == id_rs2) && (id_rs2 != 5'd0))
            forward_b_reg = 2'b10;  // 从 MEM 阶段转发
        else if (wb_reg_wr_en && (wb_rd == id_rs2) && (id_rs2 != 5'd0))
            forward_b_reg = 2'b11;  // 从 WB 阶段转发
        else
            forward_b_reg = 2'b00;  // 无需转发
    end
    assign forward_b = forward_b_reg;

    // ==================== Load-Use 冒险检测 ====================
    // 如果 EX 阶段是 LOAD 指令，且其 rd 是 ID 阶段的 rs1 或 rs2，需要暂停
    wire load_use_hazard;
    assign load_use_hazard = (ex_opcode == OP_LOAD) && (ex_rd != 5'd0) &&
                            ((ex_rd == id_rs1) || (ex_rd == id_rs2));

    // ==================== 控制冒险检测 ====================
    // 分支/跳转指令在 EX 阶段确定目标，需要冲刷 IF/ID 和 ID/EX
    wire control_hazard;
    assign control_hazard = (ex_opcode == OP_BRANCH && ex_branch_taken) || 
                           (ex_opcode == OP_JAL) || 
                           (ex_opcode == OP_JALR);

    // ==================== 暂停与冲刷控制 ====================
    assign stall_if    = load_use_hazard;
    assign stall_id    = load_use_hazard;
    assign flush_if_id = control_hazard;
    assign flush_id_ex = control_hazard || load_use_hazard;
    assign flush_ex_mem = 1'b0;  // 通常不需要冲刷 EX/MEM

endmodule
