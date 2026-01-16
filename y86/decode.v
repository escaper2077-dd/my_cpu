`timescale 1ps/1ps

module decode(
    // Input signals
    input wire [3:0] icode_i,
    input wire [3:0] rA_i,
    input wire [3:0] rB_i,
    
    // Output signals
    output wire [63:0] valA_o,
    output wire [63:0] valB_o
);

    // Y86操作码定义 (icode - 指令码的高4位)
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

    // 寄存器文件
    reg [63:0] regfile[14:0];  // 15个寄存器 (RAX-R14, %r15不存储)

    // 寄存器初始化
    initial begin
        regfile[0]  = 64'd0;     // %rax
        regfile[1]  = 64'd1;     // %rcx
        regfile[2]  = 64'd2;     // %rdx
        regfile[3]  = 64'd3;     // %rbx
        regfile[4]  = 64'd4;     // %rsp
        regfile[5]  = 64'd5;     // %rbp
        regfile[6]  = 64'd6;     // %rsi
        regfile[7]  = 64'd7;     // %rdi
        regfile[8]  = 64'd8;     // %r8
        regfile[9]  = 64'd9;     // %r9
        regfile[10] = 64'd10;    // %r10
        regfile[11] = 64'd11;    // %r11
        regfile[12] = 64'd12;    // %r12
        regfile[13] = 64'd13;    // %r13
        regfile[14] = 64'd14;    // %r14
    end

    // 根据指令类型读取寄存器
    // srcA的选择逻辑 - 根据指令类型选择sourceA寄存器
    // CALL/RET/POPL: %rsp (4)
    // PUSHL: rA_i
    // RRMOVL/RMMOVL/ALU: rA_i
    wire [3:0] srcA;
    assign srcA = ((icode_i == CALL) || (icode_i == RET) || (icode_i == POPL)) ? 4'h4 :  // %rsp
                  ((icode_i == RRMOVL) || (icode_i == RMMOVL) || (icode_i == ALU) || (icode_i == PUSHL)) ? rA_i :
                  4'hF;  // 不需要读取寄存器

    // srcB的选择逻辑 - 根据指令类型选择sourceB寄存器
    // ALU/RRMOVL: rB_i (两个寄存器操作数)
    // CALL/RET/MRMOVL/RMMOVL/PUSHL/POPL: %rsp (4) (栈或内存操作)
    wire [3:0] srcB;
    assign srcB = ((icode_i == CALL) || (icode_i == RET) || (icode_i == MRMOVL) || (icode_i == RMMOVL) || (icode_i == PUSHL) || (icode_i == POPL)) ? 4'h4 :  // %rsp
                  ((icode_i == RRMOVL) || (icode_i == ALU)) ? rB_i :
                  4'hF;  // 不需要读取寄存器

    // 从寄存器文件读出valA_o和valB_o
    // 当寄存器编号为0xF时，输出0
    assign valA_o = (srcA == 4'hF) ? 64'b0 : regfile[srcA];
    assign valB_o = (srcB == 4'hF) ? 64'b0 : regfile[srcB];

endmodule
