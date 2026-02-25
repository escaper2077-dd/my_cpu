`timescale 1ps/1ps

// Fetch阶段 - 按照PIPE框架实现
module pipe_stage_fetch(
    // 来自PC选择逻辑的PC
    input wire [63:0] f_pc,
    
    // 输出到F/D流水线寄存器
    output wire [1:0] f_stat,
    output wire [3:0] f_icode,
    output wire [3:0] f_ifun,
    output wire [3:0] f_rA,
    output wire [3:0] f_rB,
    output wire [63:0] f_valC,
    output wire [63:0] f_valP,
    
    // Predict PC输出
    output wire [63:0] f_predPC
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
    
    // 状态码
    localparam STAT_AOK = 2'b00;
    localparam STAT_ADR = 2'b10;
    localparam STAT_INS = 2'b11;
    
    // 指令内存
    reg [7:0] imem[0:1023];
    
    // 指令分割
    wire [7:0] byte0, byte1;
    wire need_regids, need_valC;
    wire instr_valid;
    wire imem_error;
    
    assign byte0 = imem[f_pc];
    assign byte1 = imem[f_pc + 1];
    
    assign f_icode = byte0[7:4];
    assign f_ifun = byte0[3:0];
    
    // 判断指令有效性
    wire valid_ifun;
    assign valid_ifun = ((f_icode == RRMOVL) && (f_ifun <= 4'h6)) ||
                        ((f_icode == ALU) && (f_ifun <= 4'h3)) ||
                        ((f_icode == JXX) && (f_ifun <= 4'h6)) ||
                        ((f_icode != RRMOVL) && (f_icode != ALU) && (f_icode != JXX) && (f_ifun == 4'h0));
    
    assign instr_valid = (f_icode <= 4'hB) && valid_ifun;
    assign imem_error = (f_pc > 1023);
    
    // 计算need_regids和need_valC
    assign need_regids = (f_icode == RRMOVL) || (f_icode == IRMOVL) ||
                         (f_icode == RMMOVL) || (f_icode == MRMOVL) ||
                         (f_icode == ALU) || (f_icode == PUSHL) || (f_icode == POPL);
    
    assign need_valC = (f_icode == IRMOVL) || (f_icode == RMMOVL) ||
                       (f_icode == MRMOVL) || (f_icode == JXX) || (f_icode == CALL);
    
    // 提取rA和rB
    assign f_rA = need_regids ? byte1[7:4] : 4'hF;
    assign f_rB = need_regids ? byte1[3:0] : 4'hF;
    
    // 提取valC
    assign f_valC = need_valC ? 
                    (need_regids ? 
                        {imem[f_pc+9], imem[f_pc+8], imem[f_pc+7], imem[f_pc+6],
                         imem[f_pc+5], imem[f_pc+4], imem[f_pc+3], imem[f_pc+2]} :
                        {imem[f_pc+8], imem[f_pc+7], imem[f_pc+6], imem[f_pc+5],
                         imem[f_pc+4], imem[f_pc+3], imem[f_pc+2], imem[f_pc+1]}) :
                    64'h0;
    
    // 计算valP (下一条指令地址)
    assign f_valP = f_pc + 64'd1 + (need_regids ? 64'd1 : 64'd0) + (need_valC ? 64'd8 : 64'd0);
    
    // 计算stat
    assign f_stat = imem_error ? STAT_ADR :
                    !instr_valid ? STAT_INS :
                    STAT_AOK;
    
    // Predict PC - 简单策略：总是预测为valP(下一条指令)
    // 对于CALL和JXX，会在后续阶段修正
    assign f_predPC = f_valP;

endmodule
