`timescale 1ps/1ps

// 流水线Execute阶段
// 执行ALU操作，计算地址，评估条件码
module pipe_execute(
    input wire clk_i,
    input wire rst_n_i,
    
    // 来自ID/EX寄存器的输入
    input wire [3:0] icode_i,
    input wire [3:0] ifun_i,
    input wire [63:0] valA_i,
    input wire [63:0] valB_i,
    input wire [63:0] valC_i,
    input wire [3:0] dstE_i,
    
    // 来自转发单元的转发数据
    input wire [1:0] forwardA_i,
    input wire [1:0] forwardB_i,
    input wire [63:0] M_valE,
    input wire [63:0] W_valM,
    input wire [63:0] W_valE,
    
    // 输出
    output reg [63:0] valE_o,
    output wire Cnd_o,
    output wire [3:0] dstE_o
);

    // Y86操作码定义
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

    // ALU func码定义
    localparam ALU_ADDL = 4'h0;
    localparam ALU_SUBL = 4'h1;
    localparam ALU_ANDL = 4'h2;
    localparam ALU_XORL = 4'h3;
    
    // RRMOVL func码定义
    localparam RRMOV_RRMOVL = 4'h0;
    localparam RRMOV_CMOVLE = 4'h1;
    localparam RRMOV_CMOVL  = 4'h2;
    localparam RRMOV_CMOVE  = 4'h3;
    localparam RRMOV_CMOVNE = 4'h4;
    localparam RRMOV_CMOVGE = 4'h5;
    localparam RRMOV_CMOVG  = 4'h6;
    
    // JXX func码定义
    localparam JXX_JMP  = 4'h0;
    localparam JXX_JLE  = 4'h1;
    localparam JXX_JL   = 4'h2;
    localparam JXX_JE   = 4'h3;
    localparam JXX_JNE  = 4'h4;
    localparam JXX_JGE  = 4'h5;
    localparam JXX_JG   = 4'h6;

    // 条件码寄存器
    reg ZF, SF, OF;
    
    // 转发后的操作数
    wire [63:0] aluA, aluB;
    
    // 根据转发信号选择操作数A
    assign aluA = (forwardA_i == 2'b00) ? valA_i :
                  (forwardA_i == 2'b01) ? M_valE :
                  (forwardA_i == 2'b10) ? W_valM :
                  W_valE;
    
    // 根据转发信号选择操作数B
    assign aluB = (forwardB_i == 2'b00) ? valB_i :
                  (forwardB_i == 2'b01) ? M_valE :
                  (forwardB_i == 2'b10) ? W_valM :
                  W_valE;
    
    // ALU计算
    wire [63:0] alu_out;
    assign alu_out = (ifun_i == ALU_ADDL) ? (aluB + aluA) :
                     (ifun_i == ALU_SUBL) ? (aluB - aluA) :
                     (ifun_i == ALU_ANDL) ? (aluB & aluA) :
                     (ifun_i == ALU_XORL) ? (aluB ^ aluA) :
                     64'b0;
    
    // 条件码更新
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            ZF <= 1'b1;
            SF <= 1'b0;
            OF <= 1'b0;
        end else if (icode_i == ALU) begin
            ZF <= (alu_out == 64'b0);
            SF <= alu_out[63];
            
            if (ifun_i == ALU_ADDL) begin
                OF <= (~aluB[63] & ~aluA[63] & alu_out[63]) | 
                      (aluB[63] & aluA[63] & ~alu_out[63]);
            end else if (ifun_i == ALU_SUBL) begin
                OF <= (~aluB[63] & aluA[63] & alu_out[63]) |
                      (aluB[63] & ~aluA[63] & ~alu_out[63]);
            end else begin
                OF <= 1'b0;
            end
        end
    end
    
    // 条件评估
    wire cond;
    assign cond = (ifun_i == RRMOV_RRMOVL || ifun_i == JXX_JMP) ? 1'b1 :
                  (ifun_i == RRMOV_CMOVLE || ifun_i == JXX_JLE) ? ((SF ^ OF) | ZF) :
                  (ifun_i == RRMOV_CMOVL  || ifun_i == JXX_JL)  ? (SF ^ OF) :
                  (ifun_i == RRMOV_CMOVE  || ifun_i == JXX_JE)  ? ZF :
                  (ifun_i == RRMOV_CMOVNE || ifun_i == JXX_JNE) ? ~ZF :
                  (ifun_i == RRMOV_CMOVGE || ifun_i == JXX_JGE) ? ~(SF ^ OF) :
                  (ifun_i == RRMOV_CMOVG  || ifun_i == JXX_JG)  ? (~(SF ^ OF) & ~ZF) :
                  1'b0;
    
    assign Cnd_o = cond;
    
    // valE计算
    always @(*) begin
        case(icode_i)
            ALU: valE_o = alu_out;
            RRMOVL: valE_o = aluA;
            IRMOVL: valE_o = valC_i;
            RMMOVL, MRMOVL: valE_o = aluB + valC_i;
            PUSHL, CALL: valE_o = aluB - 64'h8;
            POPL, RET: valE_o = aluB + 64'h8;
            default: valE_o = 64'h0;
        endcase
    end
    
    // 条件移动的目标寄存器处理
    assign dstE_o = (icode_i == RRMOVL && !cond) ? 4'hF : dstE_i;

endmodule
