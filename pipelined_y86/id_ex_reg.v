`timescale 1ps/1ps

// ID/EX 流水线寄存器
module id_ex_reg(
    input wire clk_i,
    input wire rst_n_i,
    input wire stall_i,      // 阻塞信号
    input wire bubble_i,     // 插入气泡
    
    // 来自ID阶段的输入
    input wire [63:0] PC_i,
    input wire [3:0] icode_i,
    input wire [3:0] ifun_i,
    input wire [63:0] valA_i,
    input wire [63:0] valB_i,
    input wire [63:0] valC_i,
    input wire [63:0] valP_i,
    input wire [3:0] dstE_i,      // 目标寄存器E
    input wire [3:0] dstM_i,      // 目标寄存器M
    input wire [3:0] srcA_i,      // 源寄存器A
    input wire [3:0] srcB_i,      // 源寄存器B
    input wire instr_valid_i,
    input wire imem_error_i,
    
    // 传递到EX阶段的输出
    output reg [63:0] PC_o,
    output reg [3:0] icode_o,
    output reg [3:0] ifun_o,
    output reg [63:0] valA_o,
    output reg [63:0] valB_o,
    output reg [63:0] valC_o,
    output reg [63:0] valP_o,
    output reg [3:0] dstE_o,
    output reg [3:0] dstM_o,
    output reg [3:0] srcA_o,
    output reg [3:0] srcB_o,
    output reg instr_valid_o,
    output reg imem_error_o
);

    localparam NOP = 4'h0;

    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            PC_o <= 64'd0;
            icode_o <= NOP;
            ifun_o <= 4'd0;
            valA_o <= 64'd0;
            valB_o <= 64'd0;
            valC_o <= 64'd0;
            valP_o <= 64'd0;
            dstE_o <= 4'hF;
            dstM_o <= 4'hF;
            srcA_o <= 4'hF;
            srcB_o <= 4'hF;
            instr_valid_o <= 1'b1;
            imem_error_o <= 1'b0;
        end else if (bubble_i) begin
            PC_o <= 64'd0;
            icode_o <= NOP;
            ifun_o <= 4'd0;
            valA_o <= 64'd0;
            valB_o <= 64'd0;
            valC_o <= 64'd0;
            valP_o <= 64'd0;
            dstE_o <= 4'hF;
            dstM_o <= 4'hF;
            srcA_o <= 4'hF;
            srcB_o <= 4'hF;
            instr_valid_o <= 1'b1;
            imem_error_o <= 1'b0;
        end else if (!stall_i) begin
            PC_o <= PC_i;
            icode_o <= icode_i;
            ifun_o <= ifun_i;
            valA_o <= valA_i;
            valB_o <= valB_i;
            valC_o <= valC_i;
            valP_o <= valP_i;
            dstE_o <= dstE_i;
            dstM_o <= dstM_i;
            srcA_o <= srcA_i;
            srcB_o <= srcB_i;
            instr_valid_o <= instr_valid_i;
            imem_error_o <= imem_error_i;
        end
    end

endmodule
