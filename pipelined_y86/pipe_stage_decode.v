`timescale 1ps/1ps

// Decode阶段 - 按照PIPE框架实现
// 包含Register File和srcA/srcB/dstE/dstM选择逻辑
module pipe_stage_decode(
    input wire clk_i,
    input wire rst_n_i,
    
    // 来自D流水线寄存器的输入
    input wire [1:0] D_stat,
    input wire [3:0] D_icode,
    input wire [3:0] D_ifun,
    input wire [3:0] D_rA,
    input wire [3:0] D_rB,
    input wire [63:0] D_valC,
    input wire [63:0] D_valP,
    
    // 来自E阶段的转发数据
    input wire [3:0] e_dstE,
    input wire [63:0] e_valE,
    
    // 来自M阶段的转发数据
    input wire [3:0] M_dstE,
    input wire [3:0] m_dstM,    // 注意：M阶段输出，不是M/W寄存器
    input wire [63:0] M_valE,
    input wire [63:0] m_valM,    // 注意：M阶段输出，不是M/W寄存器
    
    // 来自W阶段的写回信号
    input wire [3:0] W_dstE,
    input wire [3:0] W_dstM,
    input wire [63:0] W_valE,
    input wire [63:0] W_valM,
    
    // 输出到E流水线寄存器
    output wire [1:0] d_stat,
    output wire [3:0] d_icode,
    output wire [3:0] d_ifun,
    output wire [63:0] d_valC,
    output wire [63:0] d_valP,
    output wire [63:0] d_valA,
    output wire [63:0] d_valB,
    output wire [3:0] d_dstE,
    output wire [3:0] d_dstM,
    output wire [3:0] d_srcA,
    output wire [3:0] d_srcB
);

    // Y86指令码
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
    
    // 寄存器文件 (15个通用寄存器，0-14)
    reg [63:0] reg_file[0:14];
    
    // 初始化寄存器文件
    integer i;
    initial begin
        for (i = 0; i < 15; i = i + 1)
            reg_file[i] = 64'd0;
    end
    
    // ============ 源寄存器选择逻辑 (srcA, srcB) ============
    reg [3:0] srcA, srcB;
    
    always @(*) begin
        case (D_icode)
            RRMOVL, IRMOVL, RMMOVL, ALU: begin
                srcA = D_rA;
                srcB = D_rB;
            end
            MRMOVL: begin
                srcA = 4'hF;  // 不需要srcA
                srcB = D_rB;  // 需要基址寄存器
            end
            PUSHL: begin
                srcA = D_rA;  // 要压栈的值
                srcB = 4'h4;  // %rsp
            end
            POPL: begin
                srcA = 4'h4;  // %rsp (读取地址)
                srcB = 4'h4;  // %rsp (更新栈指针)
            end
            CALL: begin
                srcA = 4'hF;
                srcB = 4'h4;  // %rsp
            end
            RET: begin
                srcA = 4'h4;  // %rsp (读取返回地址)
                srcB = 4'h4;  // %rsp (更新栈指针)
            end
            default: begin
                srcA = 4'hF;
                srcB = 4'hF;
            end
        endcase
    end
    
    assign d_srcA = srcA;
    assign d_srcB = srcB;
    
    // ============ 目标寄存器选择逻辑 (dstE, dstM) ============
    reg [3:0] dstE, dstM;
    
    always @(*) begin
        case (D_icode)
            RRMOVL: begin
                dstE = D_rB;  // 条件移动的目标
                dstM = 4'hF;
            end
            IRMOVL: begin
                dstE = D_rB;  // 立即数的目标
                dstM = 4'hF;
            end
            ALU: begin
                dstE = D_rB;  // ALU结果的目标
                dstM = 4'hF;
            end
            MRMOVL: begin
                dstE = 4'hF;
                dstM = D_rA;  // 从内存加载到的目标
            end
            PUSHL, CALL, RET: begin
                dstE = 4'h4;  // 更新%rsp
                dstM = 4'hF;
            end
            POPL: begin
                dstE = 4'h4;  // 更新%rsp
                dstM = D_rA;  // 从栈弹出到的目标
            end
            default: begin
                dstE = 4'hF;
                dstM = 4'hF;
            end
        endcase
    end
    
    assign d_dstE = dstE;
    assign d_dstM = dstM;
    
    // ============ 寄存器读取 ============
    wire [63:0] rvalA, rvalB;
    assign rvalA = (srcA == 4'hF) ? 64'h0 : reg_file[srcA];
    assign rvalB = (srcB == 4'hF) ? 64'h0 : reg_file[srcB];
    
    // ============ Sel+Fwd - D阶段数据转发逻辑 ============
    // 转发优先级：e_valE > M_valE > m_valM > W_valE > W_valM > 寄存器文件
    
    // d_valA 转发选择
    wire [63:0] fwd_valA;
    assign fwd_valA = (srcA != 4'hF && srcA == e_dstE) ? e_valE :
                      (srcA != 4'hF && srcA == M_dstE) ? M_valE :
                      (srcA != 4'hF && srcA == m_dstM) ? m_valM :
                      (srcA != 4'hF && srcA == W_dstE) ? W_valE :
                      (srcA != 4'hF && srcA == W_dstM) ? W_valM :
                      rvalA;
    
    // d_valB 转发选择
    wire [63:0] fwd_valB;
    assign fwd_valB = (srcB != 4'hF && srcB == e_dstE) ? e_valE :
                      (srcB != 4'hF && srcB == M_dstE) ? M_valE :
                      (srcB != 4'hF && srcB == m_dstM) ? m_valM :
                      (srcB != 4'hF && srcB == W_dstE) ? W_valE :
                      (srcB != 4'hF && srcB == W_dstM) ? W_valM :
                      rvalB;
    
    // 最终的 valA 选择：CALL 和 JXX 指令需要 valP
    // - CALL: valP 是返回地址，需要压栈
    // - JXX: valP 是顺序地址（不跳转时的下一条指令地址）
    assign d_valA = (D_icode == CALL || D_icode == JXX) ? D_valP : fwd_valA;
    
    // 最终的 valB 选择（目前直接使用转发后的值）
    assign d_valB = fwd_valB;
    
    // ============ 寄存器写回 ============
    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            for (i = 0; i < 15; i = i + 1)
                reg_file[i] <= 64'd0;
        end else begin
            // 写回valE到dstE
            if (W_dstE != 4'hF && W_dstE < 15)
                reg_file[W_dstE] <= W_valE;
            
            // 写回valM到dstM
            if (W_dstM != 4'hF && W_dstM < 15)
                reg_file[W_dstM] <= W_valM;
        end
    end
    
    // ============ 直通信号 ============
    assign d_stat = D_stat;
    assign d_icode = D_icode;
    assign d_ifun = D_ifun;
    assign d_valC = D_valC;
    assign d_valP = D_valP;

endmodule
