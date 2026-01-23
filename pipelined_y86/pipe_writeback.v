`timescale 1ps/1ps

// 流水线WriteBack阶段
// 确定CPU状态
module pipe_writeback(
    // 来自MEM/WB寄存器的输入
    input wire [3:0] icode_i,
    input wire instr_valid_i,
    input wire imem_error_i,
    input wire dmem_error_i,
    
    // 输出CPU状态
    output reg [1:0] stat_o
);

    // Y86操作码定义
    localparam HALT = 4'h1;
    
    // 状态码定义
    localparam STAT_AOK = 2'b00;  // 正常运行
    localparam STAT_HLT = 2'b01;  // 遇到halt指令
    localparam STAT_ADR = 2'b10;  // 地址错误
    localparam STAT_INS = 2'b11;  // 非法指令

    // 确定状态
    always @(*) begin
        if (!instr_valid_i) begin
            stat_o = STAT_INS;
        end else if (imem_error_i || dmem_error_i) begin
            stat_o = STAT_ADR;
        end else if (icode_i == HALT) begin
            stat_o = STAT_HLT;
        end else begin
            stat_o = STAT_AOK;
        end
    end

endmodule
