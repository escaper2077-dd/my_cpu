`timescale 1ps/1ps

// ============================================================================
// RISC-V 单周期 CPU - 顶层模块
// 符合测试框架要求：
//   - 模块名 top_cpu
//   - clk 上升沿触发，rst 高电平复位
//   - PC 复位值 32'h80000000
//   - 通过 DPI-C 进行取指和访存
//   - 通过 DPI-C 暴露 regfile 给测试框架
//   - 输出 commit 相关信号供测试框架对比
// ============================================================================

module top_cpu(
    input  wire        clk,
    input  wire        rst,

    output wire [31:0] cur_pc,           // 当前 PC 寄存器的实时值
    output wire        commit,           // 单周期处理器恒为 1
    output wire [31:0] commit_pc,        // 刚执行指令的 PC（单周期与 cur_pc 相同）
    output wire [31:0] commit_instr,     // 刚执行的指令
    output wire [31:0] commit_next_pc,   // 执行完当前指令后的下一条 PC
    output wire [31:0] commit_mem_addr,  // 固定 32'd0（单周期不使用）
    output wire [31:0] commit_mem_wdata, // 固定 32'd0（单周期不使用）
    output wire [31:0] commit_mem_rdata  // 固定 32'd0（单周期不使用）
);

    // ==================== 内部连接信号 ====================

    // PC
    wire [31:0] PC;

    // Fetch stage outputs
    wire [31:0] instr;
    wire [6:0]  opcode;
    wire [4:0]  rd;
    wire [2:0]  funct3;
    wire [4:0]  rs1;
    wire [4:0]  rs2;
    wire [6:0]  funct7;
    wire [31:0] imm;
    wire [31:0] valP;        // PC + 4

    // Decode stage outputs
    wire [31:0] rs1_data;
    wire [31:0] rs2_data;

    // Execute stage outputs
    wire [31:0] alu_result;
    wire        branch_taken;

    // Memory Access stage outputs
    wire [31:0] mem_data;

    // Write Back stage outputs
    wire        reg_wr_en;
    wire [4:0]  wr_addr;
    wire [31:0] wr_data;

    // Next PC（由 pc_update 计算的组合逻辑结果，供 commit_next_pc 使用）
    wire [31:0] next_pc;

    // ==================== 各阶段实例化 ====================

    // Fetch Stage（DPI-C 取指）
    fetch u_fetch(
        .PC_i      (PC),
        .instr_o   (instr),
        .opcode_o  (opcode),
        .rd_o      (rd),
        .funct3_o  (funct3),
        .rs1_o     (rs1),
        .rs2_o     (rs2),
        .funct7_o  (funct7),
        .imm_o     (imm),
        .valP_o    (valP)
    );

    // Decode Stage（含寄存器文件 + DPI-C 暴露）
    decode u_decode(
        .clk       (clk),
        .rst       (rst),
        .rs1_i     (rs1),
        .rs2_i     (rs2),
        .reg_wr_en_i (reg_wr_en),
        .wr_addr_i (wr_addr),
        .wr_data_i (wr_data),
        .rs1_data_o(rs1_data),
        .rs2_data_o(rs2_data)
    );

    // Execute Stage（ALU + 分支判断）
    execute u_execute(
        .opcode_i      (opcode),
        .funct3_i      (funct3),
        .funct7_i      (funct7),
        .rs1_data_i    (rs1_data),
        .rs2_data_i    (rs2_data),
        .imm_i         (imm),
        .PC_i          (PC),
        .alu_result_o  (alu_result),
        .branch_taken_o(branch_taken)
    );

    // Memory Access Stage（DPI-C 访存）
    memory_access u_memory(
        .clk         (clk),
        .opcode_i    (opcode),
        .funct3_i    (funct3),
        .alu_result_i(alu_result),
        .rs2_data_i  (rs2_data),
        .PC_i        (PC),
        .mem_data_o  (mem_data)
    );

    // Write Back Stage（写回数据选择 + 写使能）
    write_back u_writeback(
        .opcode_i    (opcode),
        .rd_i        (rd),
        .alu_result_i(alu_result),
        .mem_data_i  (mem_data),
        .valP_i      (valP),
        .reg_wr_en_o (reg_wr_en),
        .wr_addr_o   (wr_addr),
        .wr_data_o   (wr_data)
    );

    // PC Update Stage（计算下一 PC）
    pc_update u_pc_update(
        .clk           (clk),
        .rst           (rst),
        .opcode_i      (opcode),
        .PC_i          (PC),
        .imm_i         (imm),
        .rs1_data_i    (rs1_data),
        .valP_i        (valP),
        .branch_taken_i(branch_taken),
        .PC_o          (PC),
        .next_pc_o     (next_pc)
    );

    // ==================== commit 信号 ====================
    assign cur_pc            = PC;
    assign commit            = 1'b1;       // 单周期：每个时钟周期都提交
    assign commit_pc         = PC;
    assign commit_instr      = instr;
    assign commit_next_pc    = next_pc;
    assign commit_mem_addr   = 32'd0;
    assign commit_mem_wdata  = 32'd0;
    assign commit_mem_rdata  = 32'd0;

endmodule
