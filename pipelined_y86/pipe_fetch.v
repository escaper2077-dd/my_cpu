`timescale 1ps/1ps

// 流水线Fetch阶段
// 从指令内存读取指令，并将其传递到IF/ID寄存器
module pipe_fetch(
    // 来自PC选择逻辑的PC值
    input wire [63:0] PC_i,
    
    // 输出信号 -> IF/ID寄存器
    output wire [63:0] PC_o,
    output wire [3:0] icode_o,
    output wire [3:0] ifun_o,
    output wire [3:0] rA_o,
    output wire [3:0] rB_o,
    output wire [63:0] valC_o,
    output wire [63:0] valP_o,
    output wire instr_valid_o,
    output wire imem_error_o
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

    // 指令内存
    reg [7:0] instr_mem[0:1023];
    
    // 内部信号
    wire [79:0] instr;
    wire need_regids;
    wire need_valC;
    
    assign instr = {instr_mem[PC_i+9], instr_mem[PC_i+8], instr_mem[PC_i+7], instr_mem[PC_i+6],
                    instr_mem[PC_i+5], instr_mem[PC_i+4], instr_mem[PC_i+3], instr_mem[PC_i+2],
                    instr_mem[PC_i+1], instr_mem[PC_i]};

    assign icode_o = instr[7:4];
    assign ifun_o = instr[3:0];
    
    // 指令有效性检查
    wire valid_ifun;
    assign valid_ifun = ((icode_o == RRMOVL) && (ifun_o >= 4'h0 && ifun_o <= 4'h6)) ||
                        ((icode_o == ALU) && (ifun_o >= 4'h0 && ifun_o <= 4'h3)) ||
                        ((icode_o == JXX) && (ifun_o >= 4'h0 && ifun_o <= 4'h6)) ||
                        ((icode_o != RRMOVL) && (icode_o != ALU) && (icode_o != JXX) && (ifun_o == 4'h0));
    
    assign instr_valid_o = (icode_o < 4'hC) && valid_ifun;
    
    // 判断指令是否需要寄存器字节
    assign need_regids = (icode_o == RRMOVL) || (icode_o == IRMOVL) ||
                         (icode_o == RMMOVL) || (icode_o == MRMOVL) ||
                         (icode_o == ALU) || (icode_o == PUSHL) ||
                         (icode_o == POPL);
    
    // 判断指令是否需要常数
    assign need_valC = (icode_o == IRMOVL) || (icode_o == RMMOVL) ||
                       (icode_o == MRMOVL) || (icode_o == JXX) ||
                       (icode_o == CALL);
    
    // 提取寄存器字段
    assign rA_o = need_regids ? instr_mem[PC_i + 1][7:4] : 4'hF;
    assign rB_o = need_regids ? instr_mem[PC_i + 1][3:0] : 4'hF;
    
    // 提取常数
    assign valC_o = need_valC ? (need_regids ? {instr_mem[PC_i + 9], instr_mem[PC_i + 8], instr_mem[PC_i + 7], instr_mem[PC_i + 6], 
                                                 instr_mem[PC_i + 5], instr_mem[PC_i + 4], instr_mem[PC_i + 3], instr_mem[PC_i + 2]} :
                                                {instr_mem[PC_i + 8], instr_mem[PC_i + 7], instr_mem[PC_i + 6], instr_mem[PC_i + 5],
                                                 instr_mem[PC_i + 4], instr_mem[PC_i + 3], instr_mem[PC_i + 2], instr_mem[PC_i + 1]})
                              : 64'h0;
    
    // 计算下一条指令地址
    assign valP_o = PC_i + 1 + need_regids + (need_valC ? 8 : 0);
    
    // 内存错误检查
    assign imem_error_o = (PC_i > 1023);
    
    // 传递PC
    assign PC_o = PC_i;

endmodule
