`timescale 1ps/1ps

// M/W流水线寄存器
module pipe_reg_mw(
    input wire clk_i,
    input wire rst_n_i,
    
    // 输入 (来自M阶段)
    input wire [1:0] m_stat,
    input wire [3:0] m_icode,
    input wire [63:0] m_valE,
    input wire [63:0] m_valM,
    input wire [3:0] m_dstE,
    input wire [3:0] m_dstM,
    
    // 输出 (到W阶段)
    output reg [1:0] W_stat,
    output reg [3:0] W_icode,
    output reg [63:0] W_valE,
    output reg [63:0] W_valM,
    output reg [3:0] W_dstE,
    output reg [3:0] W_dstM
);

    localparam STAT_AOK = 2'b00;
    localparam NOP = 4'h0;
    
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            // 复位：插入NOP
            W_stat <= STAT_AOK;
            W_icode <= NOP;
            W_valE <= 64'h0;
            W_valM <= 64'h0;
            W_dstE <= 4'hF;
            W_dstM <= 4'hF;
        end else begin
            // 正常更新
            W_stat <= m_stat;
            W_icode <= m_icode;
            W_valE <= m_valE;
            W_valM <= m_valM;
            W_dstE <= m_dstE;
            W_dstM <= m_dstM;
        end
    end

endmodule
