`timescale 1ps/1ps

// ============================================================================
// RISC-V 单周期 CPU - 顶层模块 (Top Level)
// RV32I 指令集 (40 条指令)
// ============================================================================

module CPU(
    // Clock and Reset
    input wire clk_i,
    input wire rst_n_i,
    
    // Status output
    output wire [1:0] stat_o,
    
    // Debug outputs
    output wire [31:0] PC_o,
    output wire [6:0]  opcode_o
);

    // ==================== 阶段间连接信号 ====================
    
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
    wire [31:0] valP;
    wire        instr_valid;
    wire        imem_error;
    
    // Decode stage outputs
    wire [31:0] rs1_data;
    wire [31:0] rs2_data;
    
    // Execute stage outputs
    wire [31:0] alu_result;
    wire        branch_taken;
    
    // Memory Access stage outputs
    wire [31:0] mem_data;
    wire        dmem_error;
    
    // Write Back stage outputs
    wire        reg_wr_en;
    wire [4:0]  wr_addr;
    wire [31:0] wr_data;
    
    // ==================== 各个阶段实例化 ====================
    
    // Fetch Stage
    fetch fetch_stage(
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .PC_i(PC),
        .instr_o(instr),
        .opcode_o(opcode),
        .rd_o(rd),
        .funct3_o(funct3),
        .rs1_o(rs1),
        .rs2_o(rs2),
        .funct7_o(funct7),
        .imm_o(imm),
        .valP_o(valP),
        .instr_valid_o(instr_valid),
        .imem_error_o(imem_error)
    );
    
    // Decode Stage (with register write-back)
    decode decode_stage(
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .opcode_i(opcode),
        .rs1_i(rs1),
        .rs2_i(rs2),
        .rd_i(rd),
        .reg_wr_en_i(reg_wr_en),
        .wr_addr_i(wr_addr),
        .wr_data_i(wr_data),
        .rs1_data_o(rs1_data),
        .rs2_data_o(rs2_data)
    );
    
    // Execute Stage
    execute execute_stage(
        .opcode_i(opcode),
        .funct3_i(funct3),
        .funct7_i(funct7),
        .rs1_data_i(rs1_data),
        .rs2_data_i(rs2_data),
        .imm_i(imm),
        .PC_i(PC),
        .alu_result_o(alu_result),
        .branch_taken_o(branch_taken)
    );
    
    // Memory Access Stage
    memory_access memory_stage(
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .opcode_i(opcode),
        .funct3_i(funct3),
        .alu_result_i(alu_result),
        .rs2_data_i(rs2_data),
        .mem_data_o(mem_data),
        .dmem_error_o(dmem_error)
    );
    
    // Write Back Stage
    write_back writeback_stage(
        .opcode_i(opcode),
        .rd_i(rd),
        .alu_result_i(alu_result),
        .mem_data_i(mem_data),
        .valP_i(valP),
        .instr_valid_i(instr_valid),
        .imem_error_i(imem_error),
        .dmem_error_i(dmem_error),
        .reg_wr_en_o(reg_wr_en),
        .wr_addr_o(wr_addr),
        .wr_data_o(wr_data),
        .stat_o(stat_o)
    );
    
    // PC Update Stage
    pc_update pc_update_stage(
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .opcode_i(opcode),
        .PC_i(PC),
        .imm_i(imm),
        .rs1_data_i(rs1_data),
        .valP_i(valP),
        .branch_taken_i(branch_taken),
        .stat_i(stat_o),
        .PC_o(PC)
    );
    
    // Debug outputs
    assign PC_o = PC;
    assign opcode_o = opcode;

endmodule
