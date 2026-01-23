`timescale 1ps/1ps

// 冒险检测和控制单元
// 负责检测数据冒险、控制冒险，生成转发信号、阻塞信号和气泡信号
module hazard_control(
    // 来自各阶段的信号
    // IF/ID 寄存器
    input wire [3:0] D_icode,
    
    // ID/EX 寄存器
    input wire [3:0] E_icode,
    input wire [3:0] E_dstE,
    input wire [3:0] E_dstM,
    input wire [3:0] E_srcA,
    input wire [3:0] E_srcB,
    
    // EX/MEM 寄存器
    input wire [3:0] M_icode,
    input wire [3:0] M_dstE,
    input wire [3:0] M_dstM,
    input wire M_Cnd,
    
    // MEM/WB 寄存器
    input wire [3:0] W_icode,
    input wire [3:0] W_dstE,
    input wire [3:0] W_dstM,
    
    // ID阶段的源寄存器
    input wire [3:0] d_srcA,
    input wire [3:0] d_srcB,
    
    // 控制信号输出
    output wire F_stall,      // 阻塞PC更新
    output wire F_bubble,     // 清空IF阶段
    output wire D_stall,      // 阻塞IF/ID寄存器
    output wire D_bubble,     // 清空IF/ID寄存器
    output wire E_bubble,     // 清空ID/EX寄存器
    output wire M_bubble,     // 清空EX/MEM寄存器
    output wire W_stall       // 阻塞WB（通常不用）
);

    // Y86指令码定义
    localparam NOP    = 4'h0;
    localparam HALT   = 4'h1;
    localparam RRMOVL = 4'h2;
    localparam IRMOVL = 4'h3;
    localparam RMMOVL = 4'h4;
    localparam MRMOVL = 4'h5;
    localparam ALU    = 4'h6;
    localparam JXX    = 4'h7;
    localparam CALL   = 4'h8;
    localparam RET    = 4'h9;
    localparam PUSHL  = 4'hA;
    localparam POPL   = 4'hB;

    // 加载使用冒险检测（Load-Use Hazard）
    // 当前一条指令是MRMOVL且其目标寄存器是当前指令的源寄存器时
    wire load_use_hazard;
    assign load_use_hazard = (E_icode == MRMOVL || E_icode == POPL) && 
                             (E_dstM == d_srcA || E_dstM == d_srcB) &&
                             (E_dstM != 4'hF);
    
    // 预测错误的分支（Mispredicted Branch）
    // JXX指令在MEM阶段发现分支预测错误
    wire mispredicted_branch;
    assign mispredicted_branch = (M_icode == JXX) && !M_Cnd;
    
    // RET指令处理（需要阻塞直到RET完成）
    wire ret_hazard;
    assign ret_hazard = (D_icode == RET || E_icode == RET || M_icode == RET);
    
    // 控制信号生成
    // F_stall: 阻塞PC更新（加载使用冒险或RET）
    assign F_stall = load_use_hazard || ret_hazard;
    
    // F_bubble: 清空IF阶段（通常不用）
    assign F_bubble = 1'b0;
    
    // D_stall: 阻塞IF/ID寄存器（加载使用冒险或RET）
    assign D_stall = load_use_hazard || ret_hazard;
    
    // D_bubble: 清空IF/ID寄存器（分支预测错误）
    assign D_bubble = mispredicted_branch;
    
    // E_bubble: 清空ID/EX寄存器（加载使用冒险或分支预测错误）
    assign E_bubble = load_use_hazard || mispredicted_branch;
    
    // M_bubble: 清空EX/MEM寄存器（通常不用）
    assign M_bubble = 1'b0;
    
    // W_stall: 阻塞WB（通常不用）
    assign W_stall = 1'b0;

endmodule


// 转发单元
// 负责在数据冒险时从后续阶段转发数据到前面阶段
module forwarding_unit(
    // ID/EX 寄存器
    input wire [3:0] E_srcA,
    input wire [3:0] E_srcB,
    
    // EX/MEM 寄存器
    input wire [3:0] M_dstE,
    input wire [3:0] M_dstM,
    
    // MEM/WB 寄存器
    input wire [3:0] W_dstE,
    input wire [3:0] W_dstM,
    
    // 转发选择信号
    output reg [1:0] forwardA,  // 00: 使用valA, 01: 从M转发valE, 10: 从W转发valM, 11: 从W转发valE
    output reg [1:0] forwardB   // 00: 使用valB, 01: 从M转发valE, 10: 从W转发valM, 11: 从W转发valE
);

    // 转发valA的逻辑
    always @(*) begin
        if (E_srcA != 4'hF) begin
            // 从MEM阶段转发valE
            if (M_dstE == E_srcA && M_dstE != 4'hF)
                forwardA = 2'b01;
            // 从WB阶段转发valM
            else if (W_dstM == E_srcA && W_dstM != 4'hF)
                forwardA = 2'b10;
            // 从WB阶段转发valE
            else if (W_dstE == E_srcA && W_dstE != 4'hF)
                forwardA = 2'b11;
            // 不转发
            else
                forwardA = 2'b00;
        end else begin
            forwardA = 2'b00;
        end
    end
    
    // 转发valB的逻辑
    always @(*) begin
        if (E_srcB != 4'hF) begin
            // 从MEM阶段转发valE
            if (M_dstE == E_srcB && M_dstE != 4'hF)
                forwardB = 2'b01;
            // 从WB阶段转发valM
            else if (W_dstM == E_srcB && W_dstM != 4'hF)
                forwardB = 2'b10;
            // 从WB阶段转发valE
            else if (W_dstE == E_srcB && W_dstE != 4'hF)
                forwardB = 2'b11;
            // 不转发
            else
                forwardB = 2'b00;
        end else begin
            forwardB = 2'b00;
        end
    end

endmodule
