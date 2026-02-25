`timescale 1ps/1ps

// PC选择和更新逻辑 - 按照PIPE框架实现  
// 包含Select PC逻辑，处理正常流、跳转和分支预测
module pipe_pc_logic(
    input wire clk_i,
    input wire rst_n_i,
    
    // 来自F阶段的predPC
    input wire [63:0] f_predPC,
    
    // 来自M阶段的分支信息
    input wire [3:0] M_icode,
    input wire M_Cnd,
    input wire [63:0] M_valC,  // JXX跳转目标地址
    input wire [63:0] M_valA,  // 顺序执行地址（valP）
    
    // 来自W阶段的返回地址
    input wire [3:0] W_icode,
    input wire [63:0] W_valM,  // RET指令的返回地址
    
    // 流水线控制信号
    input wire F_stall,
    
    // 输出：新的PC
    output reg [63:0] f_pc
);

    // Y86指令码
    localparam JXX = 4'h7;
    localparam RET = 4'h9;
    
    // ============ Select PC逻辑 ============
    // 优先级：
    // 1. JXX分支预测错误 (M阶段)：简单预测器预测顺序执行，如果M_Cnd=1则预测错误
    // 2. RET指令 (W阶段)
    // 3. 正常预测PC (F阶段)
    
    wire [63:0] new_pc;
    
    assign new_pc = // JXX预测错误：应该跳转但预测为顺序执行，使用跳转目标M_valC
                    (M_icode == JXX && M_Cnd) ? M_valC :
                    // RET指令：使用返回地址
                    (W_icode == RET) ? W_valM :
                    // 正常：使用预测的PC（对于JXX不跳转的情况，predPC已经是正确的）
                    f_predPC;
    
    // ============ PC更新 ============
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            f_pc <= 64'h0;
        end else if (!F_stall) begin
            f_pc <= new_pc;
        end
        // 如果F_stall，保持当前PC
    end

endmodule
