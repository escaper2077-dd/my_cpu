`timescale 1ps/1ps

// D/E流水线寄存器
module pipe_reg_de(
    input wire clk_i,
    input wire rst_n_i,
    input wire bubble,
    
    // 输入 (来自D阶段)
    input wire [1:0] d_stat,
    input wire [3:0] d_icode,
    input wire [3:0] d_ifun,
    input wire [63:0] d_valC,
    input wire [63:0] d_valP,
    input wire [63:0] d_valA,
    input wire [63:0] d_valB,
    input wire [3:0] d_dstE,
    input wire [3:0] d_dstM,
    input wire [3:0] d_srcA,
    input wire [3:0] d_srcB,
    
    // 输出 (到E阶段)
    output reg [1:0] E_stat,
    output reg [3:0] E_icode,
    output reg [3:0] E_ifun,
    output reg [63:0] E_valC,
    output reg [63:0] E_valP,
    output reg [63:0] E_valA,
    output reg [63:0] E_valB,
    output reg [3:0] E_dstE,
    output reg [3:0] E_dstM,
    output reg [3:0] E_srcA,
    output reg [3:0] E_srcB
);

    localparam STAT_AOK = 2'b00;
    localparam NOP = 4'h0;
    
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i || bubble) begin
            // 复位或气泡：插入NOP
            E_stat <= STAT_AOK;
            E_icode <= NOP;
            E_ifun <= 4'h0;
            E_valC <= 64'h0;
            E_valP <= 64'h0;
            E_valA <= 64'h0;
            E_valB <= 64'h0;
            E_dstE <= 4'hF;
            E_dstM <= 4'hF;
            E_srcA <= 4'hF;
            E_srcB <= 4'hF;
        end else begin
            // 正常更新
            E_stat <= d_stat;
            E_icode <= d_icode;
            E_ifun <= d_ifun;
            E_valC <= d_valC;
            E_valP <= d_valP;
            E_valA <= d_valA;
            E_valB <= d_valB;
            E_dstE <= d_dstE;
            E_dstM <= d_dstM;
            E_srcA <= d_srcA;
            E_srcB <= d_srcB;
        end
    end

endmodule
