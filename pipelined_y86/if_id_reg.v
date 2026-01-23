`timescale 1ps/1ps

// IF/ID 流水线寄存器
module if_id_reg(
    input wire clk_i,
    input wire rst_n_i,
    input wire stall_i,      // 阻塞信号
    input wire bubble_i,     // 插入气泡（清空寄存器）
    
    // 来自IF阶段的输入
    input wire [63:0] PC_i,
    input wire [3:0] icode_i,
    input wire [3:0] ifun_i,
    input wire [3:0] rA_i,
    input wire [3:0] rB_i,
    input wire [63:0] valC_i,
    input wire [63:0] valP_i,
    input wire instr_valid_i,
    input wire imem_error_i,
    
    // 传递到ID阶段的输出
    output reg [63:0] PC_o,
    output reg [3:0] icode_o,
    output reg [3:0] ifun_o,
    output reg [3:0] rA_o,
    output reg [3:0] rB_o,
    output reg [63:0] valC_o,
    output reg [63:0] valP_o,
    output reg instr_valid_o,
    output reg imem_error_o
);

    localparam NOP = 4'h0;

    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            // 复位时插入NOP
            PC_o <= 64'd0;
            icode_o <= NOP;
            ifun_o <= 4'd0;
            rA_o <= 4'hF;
            rB_o <= 4'hF;
            valC_o <= 64'd0;
            valP_o <= 64'd0;
            instr_valid_o <= 1'b1;
            imem_error_o <= 1'b0;
        end else if (bubble_i) begin
            // 插入气泡（NOP）
            PC_o <= 64'd0;
            icode_o <= NOP;
            ifun_o <= 4'd0;
            rA_o <= 4'hF;
            rB_o <= 4'hF;
            valC_o <= 64'd0;
            valP_o <= 64'd0;
            instr_valid_o <= 1'b1;
            imem_error_o <= 1'b0;
        end else if (!stall_i) begin
            // 正常更新
            PC_o <= PC_i;
            icode_o <= icode_i;
            ifun_o <= ifun_i;
            rA_o <= rA_i;
            rB_o <= rB_i;
            valC_o <= valC_i;
            valP_o <= valP_i;
            instr_valid_o <= instr_valid_i;
            imem_error_o <= imem_error_i;
        end
        // stall_i为1时保持当前值不变
    end

endmodule
