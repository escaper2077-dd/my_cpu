`timescale 1ps/1ps

module fetch(
    //input signal
    input wire [63:0] PC_i,
    
    //output signal
    output wire [3:0] icode_o,
    output wire [3:0] ifun_o,
    output wire [3:0] rA_o,
    output wire [3:0] rB_o,
    output wire [63:0] valC_o,
    output wire [63:0] valP_o,
    output wire instr_valid_o,
    output wire imem_error_o
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

    // 指令内存 - 1024字节（0-1023）
    reg [7:0] instr_mem[0:1023];
    
    // 内部电平信号
    //wire [3:0] icode_o_internal;
    //wire [3:0] ifun_o_internal;
    wire [79:0] instr;
    wire need_regids;
    wire need_valC;
    
    // Split current instruction - 从PC取出第一个字节
    //assign icode_o_internal = instr_mem[PC_i][7:4];
    //assign ifun_o_internal = instr_mem[PC_i][3:0];
    assign instr = {instr_mem[PC_i+9], instr_mem[PC_i+8], instr_mem[PC_i+7], instr_mem[PC_i+6],
                    instr_mem[PC_i+5], instr_mem[PC_i+4], instr_mem[PC_i+3], instr_mem[PC_i+2],
                    instr_mem[PC_i+1], instr_mem[PC_i]};

    // Split current instruction - 从PC取出第一个字节
    assign icode_o = instr[7:4];
    assign ifun_o = instr[3:0];
    
    // Check instruction code if > C, error
    assign instr_valid_o = (icode_o < 4'hC);
    
    // Instruction set - 判断指令是否需要寄存器字节
    // 需要regids的指令: RRMOVL, IRMOVL, RMMOVL, MRMOVL, ALU, PUSHL, POPL
    assign need_regids = (icode_o == RRMOVL) || (icode_o == IRMOVL) ||
                         (icode_o == RMMOVL) || (icode_o == MRMOVL) ||
                         (icode_o == ALU) || (icode_o == PUSHL) ||
                         (icode_o == POPL);
    
    // Instruction set - 判断指令是否需要8字节常数
    // 需要valC的指令: IRMOVL, RMMOVL, MRMOVL, JXX, CALL
    assign need_valC = (icode_o == IRMOVL) || (icode_o == RMMOVL) ||
                       (icode_o == MRMOVL) || (icode_o == JXX) ||
                       (icode_o == CALL);
    
    // Extract rA and rB conditionally - 从第二个字节（PC+1）取出
    assign rA_o = need_regids ? instr_mem[PC_i + 1][7:4] : 4'hF;
    assign rB_o = need_regids ? instr_mem[PC_i + 1][3:0] : 4'hF;
    
    // Extract valC based on need_valC and need_regids - 64位常数从PC+1或PC+2开始
    assign valC_o = need_regids ? {instr_mem[PC_i + 9], instr_mem[PC_i + 8], instr_mem[PC_i + 7], instr_mem[PC_i + 6], 
                                    instr_mem[PC_i + 5], instr_mem[PC_i + 4], instr_mem[PC_i + 3], instr_mem[PC_i + 2]} :
                                   {instr_mem[PC_i + 8], instr_mem[PC_i + 7], instr_mem[PC_i + 6], instr_mem[PC_i + 5],
                                    instr_mem[PC_i + 4], instr_mem[PC_i + 3], instr_mem[PC_i + 2], instr_mem[PC_i + 1]};
    
    // Calculate valP - PC + 1 + need_regids + 8*need_valC
    assign valP_o = PC_i + 1 + need_regids + (need_valC ? 8 : 0);
    
    // Check memory error
    assign imem_error_o = (PC_i > 1023);
    
    // Output assignments
    //assign icode_o = icode_o_internal;
    //assign ifun_o = ifun_o_internal;    
    // 初始化指令内存（可选示例）
    //initial begin
    //    // 示例：可以在这里加载指令
    //    // instr_mem[0] = NOP;  // NOP指令
    //end

endmodule