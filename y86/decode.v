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

    // 根据指令类型读取寄存器 - 使用case语句选择srcA和srcB
    // srcA/srcB的选择逻辑：
    // - 需要regids且用到该源操作数的指令读实际寄存器
    // - PUSHL/POPL中F被特殊对待为%rsp(4)
    // - 不需要的寄存器设为F（无效）
    reg [3:0] srcA;
    reg [3:0] srcB;
    
    always @(*) begin
        case (icode_i)
            NOP: begin
                srcA = 4'hF;
                srcB = 4'hF;
            end
            HALT: begin
                srcA = 4'hF;
                srcB = 4'hF;
            end
            RRMOVL: begin
                srcA = rA_i;
                srcB = rB_i;
            end
            IRMOVL: begin
                srcA = rA_i;
                srcB = rB_i;
            end
            RMMOVL: begin
                srcA = rA_i;
                srcB = rB_i;
            end
            MRMOVL: begin
                srcA = rA_i;
                srcB = rB_i;
            end
            ALU: begin
                srcA = rA_i;
                srcB = rB_i;
            end
            JXX: begin
                srcA = 4'hF;
                srcB = 4'hF;
            end
            CALL: begin
                srcA = 4'hF;
                srcB = 4'hF;
            end
            RET: begin
                srcA = 4'hF;
                srcB = 4'hF;
            end
            PUSHL: begin
                srcA = rA_i;
                //srcB = (rB_i == 4'hF) ? 4'h4 : rB_i;  // rB=F时理解为%rsp(4)
                srcB = 4'h4;                           // srcB总是%rsp(4)，因为PUSHL入栈
            end
            POPL: begin
                srcA = rA_i;                           // rA是目标寄存器
                srcB = 4'h4;                           // srcB总是%rsp(4)，因为POPL从栈弹出
            end
            default: begin
                srcA = 4'hF;
                srcB = 4'hF;
            end
        endcase
    end

    // 从寄存器文件读出valA_o和valB_o
    // 当寄存器编号为0xF时，输出0
    assign valA_o = (srcA == 4'hF) ? 64'b0 : regfile[srcA];
    assign valB_o = (srcB == 4'hF) ? 64'b0 : regfile[srcB];

endmodule
