`timescale 1ps/1ps

// ============================================================================
// RISC-V 单周期 CPU - 访存阶段 (Memory Access Stage)
// 实例化 data_memory，根据 opcode 控制读写
// ============================================================================

module memory_access(
    // Clock and Reset
    input wire clk_i,
    input wire rst_n_i,
    
    // Input signals from Execute stage
    input wire [6:0]  opcode_i,
    input wire [2:0]  funct3_i,
    input wire [31:0] alu_result_i,   // 地址 (rs1 + imm)
    input wire [31:0] rs2_data_i,     // 写入数据 (Store)
    
    // Output signals
    output wire [31:0] mem_data_o,    // 从内存读出的数据
    output wire        dmem_error_o
);

    // 操作码定义
    localparam OP_LOAD  = 7'b0000011;
    localparam OP_STORE = 7'b0100011;

    // 内部信号
    wire mem_read;
    wire mem_write;
    
    assign mem_read  = (opcode_i == OP_LOAD);
    assign mem_write = (opcode_i == OP_STORE);

    // 数据内存实例
    data_memory dmem_inst(
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .r_en_i(mem_read),
        .r_addr_i(alu_result_i),
        .r_funct3_i(funct3_i),
        .r_data_o(mem_data_o),
        .w_en_i(mem_write),
        .w_addr_i(alu_result_i),
        .w_funct3_i(funct3_i),
        .w_data_i(rs2_data_i),
        .error_o(dmem_error_o)
    );

endmodule
