`timescale 1ps/1ps

// F/D流水线寄存器
module pipe_reg_fd(
    input wire clk_i,
    input wire rst_n_i,
    input wire stall,
    input wire bubble,
    
    // 输入 (来自F阶段)
    input wire [1:0] f_stat,
    input wire [3:0] f_icode,
    input wire [3:0] f_ifun,
    input wire [3:0] f_rA,
    input wire [3:0] f_rB,
    input wire [63:0] f_valC,
    input wire [63:0] f_valP,
    
    // 输出 (到D阶段)
    output reg [1:0] D_stat,
    output reg [3:0] D_icode,
    output reg [3:0] D_ifun,
    output reg [3:0] D_rA,
    output reg [3:0] D_rB,
    output reg [63:0] D_valC,
    output reg [63:0] D_valP
);

    localparam STAT_AOK = 2'b00;
    localparam NOP = 4'h0;
    
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i || bubble) begin
            // 复位或气泡：插入NOP
            D_stat <= STAT_AOK;
            D_icode <= NOP;
            D_ifun <= 4'h0;
            D_rA <= 4'hF;
            D_rB <= 4'hF;
            D_valC <= 64'h0;
            D_valP <= 64'h0;
        end else if (!stall) begin
            // 正常更新
            D_stat <= f_stat;
            D_icode <= f_icode;
            D_ifun <= f_ifun;
            D_rA <= f_rA;
            D_rB <= f_rB;
            D_valC <= f_valC;
            D_valP <= f_valP;
        end
        // stall时保持原值
    end

endmodule
