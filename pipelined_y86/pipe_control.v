`timescale 1ps/1ps

// 流水线控制逻辑 - 按照PIPE框架实现
// 包含冒险检测和流水线控制信号生成
module pipe_control(
    // 来自各阶段的信号
    input wire [3:0] D_icode,
    input wire [3:0] E_icode,
    input wire [3:0] M_icode,
    input wire [3:0] E_dstM,
    input wire [3:0] d_srcA,
    input wire [3:0] d_srcB,
    input wire M_Cnd,
    
    // 输出控制信号
    output wire F_stall,
    output wire D_stall,
    output wire D_bubble,
    output wire E_bubble
);

    // Y86指令码
    localparam MRMOVL = 4'h5;
    localparam JXX    = 4'h7;
    localparam RET    = 4'h9;
    localparam POPL   = 4'hB;
    
    // ============ 加载使用冒险检测 ============  
    // 当E阶段是MRMOVL/POPL，且其dstM是D阶段的srcA或srcB时
    wire load_use_hazard;
    assign load_use_hazard = ((E_icode == MRMOVL || E_icode == POPL) &&
                              (E_dstM == d_srcA || E_dstM == d_srcB) &&
                              (E_dstM != 4'hF));
    
    // ============ 分支预测错误检测 ============
    // 简单预测器总是预测顺序执行（不跳转）
    // 所以当JXX指令在M阶段发现条件满足（M_Cnd=1，应该跳转）时，预测错误
    wire mispredicted;
    assign mispredicted = (M_icode == JXX && M_Cnd);
    
    // ============ RET冒险检测 ============
    // RET指令需要阻塞直到返回地址可用
    wire ret_hazard;
    assign ret_hazard = (D_icode == RET || E_icode == RET || M_icode == RET);
    
    // ============ 控制信号生成 ============
    
    // F_stall: 阻塞PC更新和Fetch
    assign F_stall = load_use_hazard || ret_hazard;
    
    // D_stall: 阻塞D寄存器
    assign D_stall = load_use_hazard;
    
    // D_bubble: 清空D寄存器（插入气泡）
    assign D_bubble = mispredicted || (!D_stall && ret_hazard);
    
    // E_bubble: 清空E寄存器（插入气泡）
    assign E_bubble = mispredicted || load_use_hazard;

endmodule
