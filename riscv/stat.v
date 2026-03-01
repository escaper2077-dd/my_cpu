`timescale 1ps/1ps

// ============================================================================
// RISC-V 单周期 CPU - 状态模块 (Status Module)
// 判定 CPU 运行状态
// ============================================================================

module stat(
    input wire [6:0] opcode_i,
    input wire [2:0] funct3_i,
    input wire       instr_valid_i,
    input wire       imem_error_i,
    input wire       dmem_error_i,
    
    output reg [1:0] stat_o
);

    localparam STAT_AOK = 2'b00;  // 正常运行
    localparam STAT_HLT = 2'b01;  // 停机
    localparam STAT_ADR = 2'b10;  // 地址错误
    localparam STAT_INS = 2'b11;  // 非法指令

    localparam OP_SYSTEM = 7'b1110011;

    always @(*) begin
        if (imem_error_i)
            stat_o = STAT_ADR;
        else if (!instr_valid_i)
            stat_o = STAT_INS;
        else if (dmem_error_i)
            stat_o = STAT_ADR;
        else if (opcode_i == OP_SYSTEM)
            stat_o = STAT_HLT;     // ECALL/EBREAK 当作停机
        else
            stat_o = STAT_AOK;
    end

endmodule
