`timescale 1ps/1ps

// E/M流水线寄存器
module pipe_reg_em(
    input wire clk_i,
    input wire rst_n_i,
    input wire bubble,  // 气泡控制：取消E阶段指令进入M
    
    // 输入 (来自E阶段)
    input wire [1:0] e_stat,
    input wire [3:0] e_icode,
    input wire [63:0] e_valA,
    input wire [63:0] e_valE,
    input wire [63:0] e_valC,
    input wire [63:0] e_valP,
    input wire [3:0] e_dstE,
    input wire [3:0] e_dstM,
    input wire e_Cnd,
    
    // 输出 (到M阶段)
    output reg [1:0] M_stat,
    output reg [3:0] M_icode,
    output reg [63:0] M_valA,
    output reg [63:0] M_valE,
    output reg [63:0] M_valC,
    output reg [63:0] M_valP,
    output reg [3:0] M_dstE,
    output reg [3:0] M_dstM,
    output reg M_Cnd
);

    localparam STAT_AOK = 2'b00;
    localparam NOP = 4'h0;
    
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i || bubble) begin
            // 复位或气泡：插入NOP
            M_stat <= STAT_AOK;
            M_icode <= NOP;
            M_valA <= 64'h0;
            M_valE <= 64'h0;
            M_valC <= 64'h0;
            M_valP <= 64'h0;
            M_dstE <= 4'hF;
            M_dstM <= 4'hF;
            M_Cnd <= 1'b0;
        end else begin
            // 正常更新
            M_stat <= e_stat;
            M_icode <= e_icode;
            M_valA <= e_valA;
            M_valE <= e_valE;
            M_valC <= e_valC;
            M_valP <= e_valP;
            M_dstE <= e_dstE;
            M_dstM <= e_dstM;
            M_Cnd <= e_Cnd;
        end
    end

endmodule
