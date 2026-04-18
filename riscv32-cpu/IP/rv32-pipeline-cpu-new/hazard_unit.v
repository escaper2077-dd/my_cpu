`timescale 1ps/1ps

// ============================================================================
// RISC-V 五级流水线 CPU - 冒险检测与转发单元
//
// 转发逻辑（在 EX 阶段检测，组合逻辑直接生效）：
//   比较 EX 阶段的 rs1/rs2 与 MEM 阶段的 rd、WB 阶段的 rd
//   forward = 01: 从 MEM 阶段转发 (EX/MEM 寄存器输出)
//   forward = 10: 从 WB  阶段转发 (MEM/WB 寄存器输出)
//   forward = 00: 不转发，使用寄存器文件读出的值
//
// Load-Use 暂停（在 ID 阶段检测）：
//   EX 阶段是 LOAD 且其 rd 是 ID 阶段的 rs1 或 rs2 → 暂停 1 周期
//
// 控制冒险（在 EX 阶段检测）：
//   JAL / JALR / Branch-taken → 冲刷 IF/ID 和 ID/EX
// ============================================================================

module hazard_unit(
    // EX 阶段的源寄存器（用于转发检测）
    input wire [4:0]  ex_rs1,
    input wire [4:0]  ex_rs2,

    // MEM 阶段（用于转发检测）
    input wire [4:0]  mem_rd,
    input wire [6:0]  mem_opcode,
    input wire        mem_reg_wr_en,

    // WB 阶段（用于转发检测）
    input wire [4:0]  wb_rd,
    input wire        wb_reg_wr_en,

    // ID 阶段的源寄存器（用于 load-use 检测）
    input wire [4:0]  id_rs1,
    input wire [4:0]  id_rs2,

    // EX 阶段的目标寄存器和操作码（用于 load-use 检测）
    input wire [4:0]  ex_rd,
    input wire [6:0]  ex_opcode,

    // EX 阶段的跳转信号（用于控制冒险）
    input wire        ex_branch_taken,

    // 转发控制输出（组合逻辑，直接送到 EX 阶段的转发 MUX）
    output reg [1:0]  forward_a,      // rs1 转发
    output reg [1:0]  forward_b,      // rs2 转发

    // 暂停与冲刷
    output wire       stall_if,
    output wire       stall_id,
    output wire       flush_id_ex,
    output wire       flush_if_id
);

    localparam OP_LOAD = 7'b0000011;

    // ==================== 转发逻辑 ====================
    // MEM 优先级高于 WB（更新的数据优先）
    always @(*) begin
        if (mem_reg_wr_en && (mem_rd != 5'd0) && (mem_rd == ex_rs1))
            forward_a = 2'b01;  // 从 MEM 转发
        else if (wb_reg_wr_en && (wb_rd != 5'd0) && (wb_rd == ex_rs1))
            forward_a = 2'b10;  // 从 WB 转发
        else
            forward_a = 2'b00;  // 不转发
    end

    always @(*) begin
        if (mem_reg_wr_en && (mem_rd != 5'd0) && (mem_rd == ex_rs2))
            forward_b = 2'b01;
        else if (wb_reg_wr_en && (wb_rd != 5'd0) && (wb_rd == ex_rs2))
            forward_b = 2'b10;
        else
            forward_b = 2'b00;
    end

    // ==================== Load-Use 暂停 ====================
    wire load_use;
    assign load_use = (ex_opcode == OP_LOAD) && (ex_rd != 5'd0) &&
                      ((ex_rd == id_rs1) || (ex_rd == id_rs2));

    // ==================== 控制冒险 ====================
    wire control_hazard;
    assign control_hazard = ex_branch_taken;

    // ==================== 输出 ====================
    assign stall_if   = load_use;
    assign stall_id   = load_use;
    assign flush_if_id = control_hazard;
    assign flush_id_ex = control_hazard || load_use;

endmodule
