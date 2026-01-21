`timescale 1ps/1ps

module stat(
    input wire instr_valid_i,
    input wire imem_error_i,
    input wire dmem_error_i,
    
    output reg [1:0] stat_o
);

    // Y86 CPU 状态码定义
    localparam STAT_AOK = 2'b00;  // 正常运行
    localparam STAT_HLT = 2'b01;  // 遇到 halt 指令
    localparam STAT_ADR = 2'b10;  // 地址错误（内存访问错误）
    localparam STAT_INS = 2'b11;  // 非法指令

    // 确定 CPU 状态
    always @(*) begin
        if (imem_error_i) begin
            // 指令内存错误
            stat_o = STAT_ADR;
        end else if (!instr_valid_i) begin
            // 非法指令
            stat_o = STAT_INS;
        end else if (dmem_error_i) begin
            // 数据内存错误
            stat_o = STAT_ADR;
        end else begin
            // 正常状态
            stat_o = STAT_AOK;
        end
    end

endmodule
