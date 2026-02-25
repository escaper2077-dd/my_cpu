`timescale 1ps/1ps

// WriteBack阶段 - 按照PIPE框架实现
// 主要功能：确定最终的CPU状态
module pipe_stage_writeback(
    // 来自W流水线寄存器的输入
    input wire [1:0] W_stat,
    input wire [3:0] W_icode,
    
    // 输出最终状态
    output wire [1:0] w_stat
);

    // Y86指令码
    localparam HALT = 4'h1;
    
    // 状态码
    localparam STAT_AOK = 2'b00;
    localparam STAT_HLT = 2'b01;
    
    // 计算最终状态
    assign w_stat = (W_icode == HALT) ? STAT_HLT : W_stat;

endmodule
