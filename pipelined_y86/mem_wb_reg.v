`timescale 1ps/1ps

// MEM/WB 流水线寄存器
module mem_wb_reg(
    input wire clk_i,
    input wire rst_n_i,
    input wire stall_i,      // 阻塞信号
    input wire bubble_i,     // 插入气泡
    
    // 来自MEM阶段的输入
    input wire [63:0] PC_i,
    input wire [3:0] icode_i,
    input wire [63:0] valE_i,
    input wire [63:0] valM_i,
    input wire [3:0] dstE_i,
    input wire [3:0] dstM_i,
    input wire instr_valid_i,
    input wire imem_error_i,
    input wire dmem_error_i,
    
    // 传递到WB阶段的输出
    output reg [63:0] PC_o,
    output reg [3:0] icode_o,
    output reg [63:0] valE_o,
    output reg [63:0] valM_o,
    output reg [3:0] dstE_o,
    output reg [3:0] dstM_o,
    output reg instr_valid_o,
    output reg imem_error_o,
    output reg dmem_error_o
);

    localparam NOP = 4'h0;

    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            PC_o <= 64'd0;
            icode_o <= NOP;
            valE_o <= 64'd0;
            valM_o <= 64'd0;
            dstE_o <= 4'hF;
            dstM_o <= 4'hF;
            instr_valid_o <= 1'b1;
            imem_error_o <= 1'b0;
            dmem_error_o <= 1'b0;
        end else if (bubble_i) begin
            PC_o <= 64'd0;
            icode_o <= NOP;
            valE_o <= 64'd0;
            valM_o <= 64'd0;
            dstE_o <= 4'hF;
            dstM_o <= 4'hF;
            instr_valid_o <= 1'b1;
            imem_error_o <= 1'b0;
            dmem_error_o <= 1'b0;
        end else if (!stall_i) begin
            PC_o <= PC_i;
            icode_o <= icode_i;
            valE_o <= valE_i;
            valM_o <= valM_i;
            dstE_o <= dstE_i;
            dstM_o <= dstM_i;
            instr_valid_o <= instr_valid_i;
            imem_error_o <= imem_error_i;
            dmem_error_o <= dmem_error_i;
        end
    end

endmodule
