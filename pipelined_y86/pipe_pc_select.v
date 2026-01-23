`timescale 1ps/1ps

// PC选择和更新逻辑
module pipe_pc_select(
    input wire clk_i,
    input wire rst_n_i,
    
    // 来自各阶段的信号
    input wire [3:0] M_icode,
    input wire M_Cnd,
    input wire [63:0] M_valA,
    input wire [63:0] M_valP,
    input wire [63:0] W_valM,
    
    input wire [63:0] F_predPC,  // 预测的PC（通常是valP）
    
    // 来自冒险控制单元
    input wire F_stall,
    
    // 当前状态
    input wire [1:0] stat_i,
    
    // 输出新的PC
    output reg [63:0] PC_o
);

    // Y86操作码定义
    localparam JXX  = 4'h7;
    localparam CALL = 4'h8;
    localparam RET  = 4'h9;
    
    // 状态码定义
    localparam STAT_AOK = 2'b00;

    // PC选择逻辑
    reg [63:0] new_PC;
    
    always @(*) begin
        // 分支预测错误
        if (M_icode == JXX && !M_Cnd) begin
            new_PC = M_valA;  // 使用未跳转的地址（valA保存了valP）
        end
        // 正常情况：使用预测的PC
        else begin
            new_PC = F_predPC;
        end
    end

    // PC更新
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            PC_o <= 64'h0;
        end else if (stat_i != STAT_AOK) begin
            // CPU停止时不更新PC
            PC_o <= PC_o;
        end else if (!F_stall) begin
            PC_o <= new_PC;
        end
        // F_stall时保持当前PC
    end

endmodule
