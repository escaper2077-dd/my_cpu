`timescale 1ps/1ps

// Execute阶段 - 按照PIPE框架实现
// 包含ALU、条件码(CC)、条件评估(Cnd)和数据转发选择(Select A/B)
module pipe_stage_execute(
    input wire clk_i,
    input wire rst_n_i,
    input wire E_bubble,  // 控制信号：E阶段气泡，禁止CC更新
    
    // 来自E流水线寄存器的输入
    input wire [1:0] E_stat,
    input wire [3:0] E_icode,
    input wire [3:0] E_ifun,
    input wire [63:0] E_valC,
    input wire [63:0] E_valP,
    input wire [63:0] E_valA,
    input wire [63:0] E_valB,
    input wire [3:0] E_dstE,
    input wire [3:0] E_dstM,
    input wire [3:0] E_srcA,
    input wire [3:0] E_srcB,
    
    // 来自M阶段的转发数据
    input wire [63:0] M_valE,
    input wire [3:0] M_dstE,
    input wire [3:0] M_dstM,
    
    // 来自W阶段的转发数据
    input wire [63:0] W_valE,
    input wire [63:0] W_valM,
    input wire [3:0] W_dstE,
    input wire [3:0] W_dstM,
    
    // 输出到M流水线寄存器
    output wire [1:0] e_stat,
    output wire [3:0] e_icode,
    output wire [63:0] e_valA,
    output wire [63:0] e_valE,
    output wire [63:0] e_valC,
    output wire [63:0] e_valP,
    output wire [3:0] e_dstE,
    output wire [3:0] e_dstM,
    output wire e_Cnd
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
    
    // ALU func码
    localparam ALU_ADDL = 4'h0;
    localparam ALU_SUBL = 4'h1;
    localparam ALU_ANDL = 4'h2;
    localparam ALU_XORL = 4'h3;
    
    // 条件码定义
    localparam RRMOV_RRMOVL = 4'h0;
    localparam RRMOV_CMOVLE = 4'h1;
    localparam RRMOV_CMOVL  = 4'h2;
    localparam RRMOV_CMOVE  = 4'h3;
    localparam RRMOV_CMOVNE = 4'h4;
    localparam RRMOV_CMOVGE = 4'h5;
    localparam RRMOV_CMOVG  = 4'h6;
    
    localparam JXX_JMP = 4'h0;
    localparam JXX_JLE = 4'h1;
    localparam JXX_JL  = 4'h2;
    localparam JXX_JE  = 4'h3;
    localparam JXX_JNE = 4'h4;
    localparam JXX_JGE = 4'h5;
    localparam JXX_JG  = 4'h6;
    
    // ============ 条件码寄存器 (CC) ============
    reg ZF, SF, OF;
    
    initial begin
        ZF = 1'b0;
        SF = 1'b0;
        OF = 1'b0;
    end
    
    // ============ Select A/B - 数据转发逻辑 ============
    wire [63:0] aluA, aluB;
    
    // Select A：选择ALU的第一个操作数
    // 优先级：M阶段 > W阶段 > E阶段原始值
    assign aluA = (E_srcA != 4'hF && E_srcA == M_dstE) ? M_valE :
                  (E_srcA != 4'hF && E_srcA == W_dstM) ? W_valM :
                  (E_srcA != 4'hF && E_srcA == W_dstE) ? W_valE :
                  E_valA;
    
    // Select B：选择ALU的第二个操作数  
    assign aluB = (E_srcB != 4'hF && E_srcB == M_dstE) ? M_valE :
                  (E_srcB != 4'hF && E_srcB == W_dstM) ? W_valM :
                  (E_srcB != 4'hF && E_srcB == W_dstE) ? W_valE :
                  E_valB;
    
    // ============ ALU 运算 ============
    wire [63:0] alu_out;
    
    assign alu_out = (E_ifun == ALU_ADDL) ? (aluB + aluA) :
                     (E_ifun == ALU_SUBL) ? (aluB - aluA) :
                     (E_ifun == ALU_ANDL) ? (aluB & aluA) :
                     (E_ifun == ALU_XORL) ? (aluB ^ aluA) :
                     64'h0;
    
    // ============ 条件码更新 ============
    // 只有当E阶段是ALU指令且不是bubble时才更新CC
    wire set_cc;
    assign set_cc = (E_icode == ALU) && !E_bubble;
    
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            ZF <= 1'b0;
            SF <= 1'b0;
            OF <= 1'b0;
        end else if (set_cc) begin
            ZF <= (alu_out == 64'h0);
            SF <= alu_out[63];
            
            // Overflow检测
            if (E_ifun == ALU_ADDL) begin
                OF <= (~aluB[63] & ~aluA[63] & alu_out[63]) |
                      (aluB[63] & aluA[63] & ~alu_out[63]);
            end else if (E_ifun == ALU_SUBL) begin
                OF <= (~aluB[63] & aluA[63] & alu_out[63]) |
                      (aluB[63] & ~aluA[63] & ~alu_out[63]);
            end else begin
                OF <= 1'b0;
            end
        end
    end
    
    // ============ 条件评估 (Cnd) ============
    reg cond;
    
    always @(*) begin
        case (E_ifun)
            RRMOV_RRMOVL, JXX_JMP: cond = 1'b1;
            RRMOV_CMOVLE, JXX_JLE: cond = (SF ^ OF) | ZF;
            RRMOV_CMOVL,  JXX_JL:  cond = SF ^ OF;
            RRMOV_CMOVE,  JXX_JE:  cond = ZF;
            RRMOV_CMOVNE, JXX_JNE: cond = ~ZF;
            RRMOV_CMOVGE, JXX_JGE: cond = ~(SF ^ OF);
            RRMOV_CMOVG,  JXX_JG:  cond = ~(SF ^ OF) & ~ZF;
            default: cond = 1'b0;
        endcase
    end
    
    assign e_Cnd = cond;
    
    // ============ valE计算 ============
    reg [63:0] valE;
    
    always @(*) begin
        case (E_icode)
            ALU:                valE = alu_out;
            RRMOVL:             valE = aluA;
            IRMOVL:             valE = E_valC;
            RMMOVL, MRMOVL:     valE = aluB + E_valC;
            PUSHL, CALL:        valE = aluB - 64'd8;
            POPL, RET:          valE = aluB + 64'd8;
            default:            valE = 64'h0;
        endcase
    end
    
    assign e_valE = valE;
    
    // ============ dstE的条件处理 ============
    // 对于RRMOVL，如果条件不满足，取消写回
    assign e_dstE = (E_icode == RRMOVL && !cond) ? 4'hF : E_dstE;
    
    // ============ 直通信号 ============
    assign e_stat = E_stat;
    assign e_icode = E_icode;
    assign e_valA = aluA;  // 转发后的valA
    assign e_valC = E_valC;  // JXX跳转目标地址
    assign e_valP = E_valP;
    assign e_dstM = E_dstM;

endmodule
