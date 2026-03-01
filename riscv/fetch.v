`timescale 1ps/1ps

// ============================================================================
// RISC-V 单周期 CPU - 取指阶段 (Fetch Stage)
// 从指令内存中根据 PC 取出 32 位指令
// ============================================================================

module fetch(
    // Clock and Reset
    input wire clk_i,
    input wire rst_n_i,
    
    // Input signal
    input wire [31:0] PC_i,
    
    // Output signals
    output wire [31:0] instr_o,       // 完整的 32 位指令
    output wire [6:0]  opcode_o,      // 操作码 [6:0]
    output wire [4:0]  rd_o,          // 目的寄存器 [11:7]
    output wire [2:0]  funct3_o,      // 功能码3 [14:12]
    output wire [4:0]  rs1_o,         // 源寄存器1 [19:15]
    output wire [4:0]  rs2_o,         // 源寄存器2 [24:20]
    output wire [6:0]  funct7_o,      // 功能码7 [31:25]
    output wire [31:0] imm_o,         // 立即数（符号扩展后）
    output wire [31:0] valP_o,        // PC + 4
    output wire        instr_valid_o, // 指令有效
    output wire        imem_error_o   // 取指内存错误
);

    // ==================== RV32I 指令操作码 ====================
    localparam OP_LUI    = 7'b0110111;  // LUI
    localparam OP_AUIPC  = 7'b0010111;  // AUIPC
    localparam OP_JAL    = 7'b1101111;  // JAL
    localparam OP_JALR   = 7'b1100111;  // JALR
    localparam OP_BRANCH = 7'b1100011;  // BEQ, BNE, BLT, BGE, BLTU, BGEU
    localparam OP_LOAD   = 7'b0000011;  // LB, LH, LW, LBU, LHU
    localparam OP_STORE  = 7'b0100011;  // SB, SH, SW
    localparam OP_ALUI   = 7'b0010011;  // ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI
    localparam OP_ALU    = 7'b0110011;  // ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
    localparam OP_FENCE  = 7'b0001111;  // FENCE
    localparam OP_SYSTEM = 7'b1110011;  // ECALL, EBREAK

    // 指令内存 - 4096 字节
    reg [7:0] instr_mem[0:4095];
    
    // 读取 32 位指令（小端序）
    wire [31:0] instr;
    assign instr = {instr_mem[PC_i + 3], instr_mem[PC_i + 2],
                    instr_mem[PC_i + 1], instr_mem[PC_i]};
    
    assign instr_o = instr;
    
    // 指令字段拆分
    assign opcode_o = instr[6:0];
    assign rd_o     = instr[11:7];
    assign funct3_o = instr[14:12];
    assign rs1_o    = instr[19:15];
    assign rs2_o    = instr[24:20];
    assign funct7_o = instr[31:25];
    
    // PC + 4
    assign valP_o = PC_i + 32'd4;
    
    // ==================== 立即数生成 ====================
    reg [31:0] imm_gen;
    
    always @(*) begin
        case (opcode_o)
            // I-type: JALR, LOAD, ALUI, SYSTEM
            OP_JALR, OP_LOAD, OP_ALUI, OP_FENCE, OP_SYSTEM:
                imm_gen = {{20{instr[31]}}, instr[31:20]};
            
            // S-type: STORE
            OP_STORE:
                imm_gen = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            
            // B-type: BRANCH
            OP_BRANCH:
                imm_gen = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
            
            // U-type: LUI, AUIPC
            OP_LUI, OP_AUIPC:
                imm_gen = {instr[31:12], 12'b0};
            
            // J-type: JAL
            OP_JAL:
                imm_gen = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
            
            default:
                imm_gen = 32'b0;
        endcase
    end
    
    assign imm_o = imm_gen;
    
    // ==================== 指令有效性检查 ====================
    reg valid;
    always @(*) begin
        case (opcode_o)
            OP_LUI, OP_AUIPC, OP_JAL:
                valid = 1'b1;
            OP_JALR:
                valid = (funct3_o == 3'b000);
            OP_BRANCH:
                valid = (funct3_o != 3'b010) && (funct3_o != 3'b011);
            OP_LOAD:
                valid = (funct3_o != 3'b011) && (funct3_o != 3'b110) && (funct3_o != 3'b111);
            OP_STORE:
                valid = (funct3_o <= 3'b010);
            OP_ALUI: begin
                if (funct3_o == 3'b001)       // SLLI
                    valid = (funct7_o == 7'b0000000);
                else if (funct3_o == 3'b101)  // SRLI / SRAI
                    valid = (funct7_o == 7'b0000000) || (funct7_o == 7'b0100000);
                else
                    valid = 1'b1;
            end
            OP_ALU:
                valid = (funct7_o == 7'b0000000) || (funct7_o == 7'b0100000 && (funct3_o == 3'b000 || funct3_o == 3'b101));
            OP_FENCE:
                valid = 1'b1;
            OP_SYSTEM:
                valid = (instr[31:7] == 25'b0) || (instr[31:7] == {25'b0000000000010000000000000});
            default:
                valid = 1'b0;
        endcase
    end
    
    assign instr_valid_o = valid;
    
    // 内存错误检查
    assign imem_error_o = (PC_i > 32'd4092);

endmodule
