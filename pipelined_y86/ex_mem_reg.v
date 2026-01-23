`timescale 1ps/1ps

// EX/MEM 流水线寄存器
module ex_mem_reg(
    input wire clk_i,
    input wire rst_n_i,
    input wire stall_i,      // 阻塞信号
    input wire bubble_i,     // 插入气泡
    
    // 来自EX阶段的输入
    input wire [63:0] PC_i,
    input wire [3:0] icode_i,
    input wire [63:0] valA_i,
    input wire [63:0] valE_i,
    input wire [63:0] valP_i,
    input wire [3:0] dstE_i,
    input wire [3:0] dstM_i,
    input wire Cnd_i,
    input wire instr_valid_i,
    input wire imem_error_i,
    
    // 传递到MEM阶段的输出
    output reg [63:0] PC_o,
    output reg [3:0] icode_o,
    output reg [63:0] valA_o,
    output reg [63:0] valE_o,
    output reg [63:0] valP_o,
    output reg [3:0] dstE_o,
    output reg [3:0] dstM_o,
    output reg Cnd_o,
    output reg instr_valid_o,
    output reg imem_error_o
);

    localparam NOP = 4'h0;

    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            PC_o <= 64'd0;
            icode_o <= NOP;
            valA_o <= 64'd0;
            valE_o <= 64'd0;
            valP_o <= 64'd0;
            dstE_o <= 4'hF;
            dstM_o <= 4'hF;
            Cnd_o <= 1'b0;
            instr_valid_o <= 1'b1;
            imem_error_o <= 1'b0;
        end else if (bubble_i) begin
            PC_o <= 64'd0;
            icode_o <= NOP;
            valA_o <= 64'd0;
            valE_o <= 64'd0;
            valP_o <= 64'd0;
            dstE_o <= 4'hF;
            dstM_o <= 4'hF;
            Cnd_o <= 1'b0;
            instr_valid_o <= 1'b1;
            imem_error_o <= 1'b0;
        end else if (!stall_i) begin
            PC_o <= PC_i;
            icode_o <= icode_i;
            valA_o <= valA_i;
            valE_o <= valE_i;
            valP_o <= valP_i;
            dstE_o <= dstE_i;
            dstM_o <= dstM_i;
            Cnd_o <= Cnd_i;
            instr_valid_o <= instr_valid_i;
            imem_error_o <= imem_error_i;
        end
    end

endmodule
