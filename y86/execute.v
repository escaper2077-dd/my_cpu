`timescale 1ps/1ps

module execute(
    // Clock and Reset
    input wire clk_i,
    input wire rst_n_i,
    
    // Input signals from Decode
    input wire [3:0] icode_i,
    input wire [3:0] ifun_i,
    input wire [63:0] valA_i,
    input wire [63:0] valB_i,
    input wire [63:0] valC_i,
    
    // Output signals
    output reg [63:0] valE_o,
    output wire Cnd_o
);

    // Y86操作码定义
    localparam NOP    = 4'h0;
    localparam HALT   = 4'h1;
    localparam RRMOVL = 4'h2;
    localparam IRMOVL = 4'h3;
    localparam RMMOVL = 4'h4;
    localparam MRMOVL = 4'h5;
    localparam ALU    = 4'h6;  // ADDL, SUBL, ANDL, XORL
    localparam JXX    = 4'h7;  // JMPL, JLE, JL, JE, JNE, JGE, JG
    localparam CALL   = 4'h8;
    localparam RET    = 4'h9;
    localparam PUSHL  = 4'hA;
    localparam POPL   = 4'hB;

    // RRMOVL func码定义（条件移动）
    localparam RRMOV_RRMOVL = 4'h0;  // 无条件移动
    localparam RRMOV_CMOVLE = 4'h1;  // 小于等于时移动
    localparam RRMOV_CMOVL  = 4'h2;  // 小于时移动
    localparam RRMOV_CMOVE  = 4'h3;  // 等于时移动
    localparam RRMOV_CMOVNE = 4'h4;  // 不等于时移动
    localparam RRMOV_CMOVGE = 4'h5;  // 大于等于时移动
    localparam RRMOV_CMOVG  = 4'h6;  // 大于时移动
    
    // ALU func码定义
    localparam ALU_ADDL = 4'h0;
    localparam ALU_SUBL = 4'h1;
    localparam ALU_ANDL = 4'h2;
    localparam ALU_XORL = 4'h3;
    
    // JXX func码定义
    localparam JXX_JMP  = 4'h0;
    localparam JXX_JLE  = 4'h1;
    localparam JXX_JL   = 4'h2;
    localparam JXX_JE   = 4'h3;
    localparam JXX_JNE  = 4'h4;
    localparam JXX_JGE  = 4'h5;
    localparam JXX_JG   = 4'h6;

    // Condition Code Register (CC) - 时序逻辑，在时钟上升沿更新
    // ZF (Zero Flag), SF (Sign Flag), OF (Overflow Flag)
    reg ZF, SF, OF;
    
    // ALU result
    wire [63:0] alu_out;
    
    // ==================== ALU实现 ====================
    // Y86-64 ALU指令语义：OPq rA, rB  =>  R[rB] = R[rB] OP R[rA]
    // 输入：valA = R[rA], valB = R[rB]
    // 运算：valB OP valA（注意操作数顺序！）
    assign alu_out = (ifun_i == ALU_ADDL) ? (valB_i + valA_i) :
                     (ifun_i == ALU_SUBL) ? (valB_i - valA_i) :
                     (ifun_i == ALU_ANDL) ? (valB_i & valA_i) :
                     (ifun_i == ALU_XORL) ? (valB_i ^ valA_i) :
                     64'b0;
    
    // ==================== 条件码更新 (时序逻辑) ====================
    // 在时钟上升沿时，根据当前ALU运算更新条件码
    always @(posedge clk_i or negedge rst_n_i) begin
        if (rst_n_i == 1'b0) begin
            ZF <= 1'b1;
            SF <= 1'b0;
            OF <= 1'b0;
        end
        else if (icode_i == ALU) begin
            // 对ALU操作设置条件码
            ZF <= (alu_out == 64'b0) ? 1'b1 : 1'b0;
            SF <= alu_out[63];
            
            // Overflow Flag - 检查加法或减法的溢出
            // 注意：运算是 valB OP valA
            if (ifun_i == ALU_ADDL) begin
                // 加法溢出：valB + valA，两个同号数相加，结果符号不同
                OF <= (~valB_i[63] & ~valA_i[63] & alu_out[63]) | 
                      (valB_i[63] & valA_i[63] & ~alu_out[63]);
            end
            else if (ifun_i == ALU_SUBL) begin
                // 减法溢出：valB - valA
                // B>0, A<0，结果<0（正减负溢出）；或 B<0, A>0，结果>0（负减正溢出）
                OF <= (~valB_i[63] & valA_i[63] & alu_out[63]) |
                      (valB_i[63] & ~valA_i[63] & ~alu_out[63]);
            end
            else begin
                OF <= 1'b0;  // ANDL和XORL不产生溢出
            end
        end
        // 非ALU指令时，条件码保持不变
    end
    
    // ==================== valE_o的选择 ====================
    // 不同指令的valE值由不同的计算方式得出
    always @(*) begin
        case(icode_i)
            // ALU指令：valE = ALU结果
            ALU: begin
                valE_o = alu_out;
            end
            // RRMOVL：valE = valA（用于寄存器移动）
            RRMOVL: begin
                valE_o = valA_i;
            end
            // IRMOVL：valE = valC（立即数）
            IRMOVL: begin
                valE_o = valC_i;
            end
            // RMMOVL：valE = valB + valC（存储地址计算）
            RMMOVL: begin
                valE_o = valB_i + valC_i;
            end
            // MRMOVL：valE = valB + valC（取内存地址）
            MRMOVL: begin
                valE_o = valB_i + valC_i;
            end
            // PUSHL：valE = valB - 8（%rsp -= 8）
            PUSHL: begin
                valE_o = valB_i - 64'h8;
            end
            // POPL：valE = valB + 8（%rsp += 8）
            POPL: begin
                valE_o = valB_i + 64'h8;
            end
            // CALL：valE = valB - 8（%rsp -= 8）
            CALL: begin
                valE_o = valB_i - 64'h8;
            end
            // RET：valE = valB + 8（%rsp += 8）
            RET: begin
                valE_o = valB_i + 64'h8;
            end
            // JXX、NOP、HALT：valE无意义，设为0
            default: begin
                valE_o = 64'b0;
            end
        endcase
    end
    
    // ==================== 条件码判断 ====================
    // 根据条件码和条件代码判断是否满足条件
    // 用于两种指令：
    // 1. RRMOVL: 条件为真时才执行移动
    // 2. JXX: 条件为真时才跳转
    // 返回1表示条件满足，0表示不满足
    assign Cnd_o = 
        // RRMOVL的条件码（icode=2, ifun=0-6）
        ((icode_i == RRMOVL) & (
            ((ifun_i == RRMOV_RRMOVL) & 1'b1) |                    // RRMOVL: 无条件
            ((ifun_i == RRMOV_CMOVLE) & (ZF | SF)) |               // CMOVLE: <=
            ((ifun_i == RRMOV_CMOVL) & SF) |                       // CMOVL: <
            ((ifun_i == RRMOV_CMOVE) & ZF) |                       // CMOVE: ==
            ((ifun_i == RRMOV_CMOVNE) & ~ZF) |                     // CMOVNE: !=
            ((ifun_i == RRMOV_CMOVGE) & ~SF) |                     // CMOVGE: >=
            ((ifun_i == RRMOV_CMOVG) & (~SF & ~ZF))                // CMOVG: >
        )) |
        // JXX的条件码（icode=7, ifun=0-6）
        ((icode_i == JXX) & (
            ((ifun_i == JXX_JMP) & 1'b1) |                         // JMP: 无条件
            ((ifun_i == JXX_JLE) & (ZF | SF)) |                    // JLE: <=
            ((ifun_i == JXX_JL) & SF) |                            // JL: <
            ((ifun_i == JXX_JE) & ZF) |                            // JE: ==
            ((ifun_i == JXX_JNE) & ~ZF) |                          // JNE: !=
            ((ifun_i == JXX_JGE) & ~SF) |                          // JGE: >=
            ((ifun_i == JXX_JG) & (~SF & ~ZF))                     // JG: >
        ));

endmodule
