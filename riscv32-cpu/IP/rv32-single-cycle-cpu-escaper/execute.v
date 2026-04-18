`timescale 1ps/1ps

// ============================================================================
// RISC-V 单周期 CPU - 执行阶段 (Execute Stage / ALU)
// 支持 RV32I 全部 ALU 操作和分支条件判断
// ============================================================================

module execute(
    // Input signals
    input wire [6:0]  opcode_i,
    input wire [2:0]  funct3_i,
    input wire [6:0]  funct7_i,
    input wire [31:0] rs1_data_i,
    input wire [31:0] rs2_data_i,
    input wire [31:0] imm_i,
    input wire [31:0] PC_i,
    
    // Output signals
    output reg  [31:0] alu_result_o,   // ALU 计算结果
    output wire        branch_taken_o  // 分支是否成立
);

    // ==================== 操作码定义 ====================
    localparam OP_LUI    = 7'b0110111;
    localparam OP_AUIPC  = 7'b0010111;
    localparam OP_JAL    = 7'b1101111;
    localparam OP_JALR   = 7'b1100111;
    localparam OP_BRANCH = 7'b1100011;
    localparam OP_LOAD   = 7'b0000011;
    localparam OP_STORE  = 7'b0100011;
    localparam OP_ALUI   = 7'b0010011;
    localparam OP_ALU    = 7'b0110011;
    localparam OP_FENCE  = 7'b0001111;
    localparam OP_SYSTEM = 7'b1110011;

    // ==================== ALU 操作数选择 ====================
    wire [31:0] alu_a;
    wire [31:0] alu_b;
    
    // ALU 操作数 A：AUIPC 用 PC，其他用 rs1
    assign alu_a = (opcode_i == OP_AUIPC) ? PC_i : rs1_data_i;
    
    // ALU 操作数 B：R-type 用 rs2，其他用 imm
    assign alu_b = (opcode_i == OP_ALU || opcode_i == OP_BRANCH) ? rs2_data_i : imm_i;

    // ==================== 移位量 ====================
    wire [4:0] shamt;
    assign shamt = (opcode_i == OP_ALU) ? rs2_data_i[4:0] : imm_i[4:0];

    // 算术右移专用
    wire signed [31:0] rs1_signed;
    assign rs1_signed = rs1_data_i;
    wire signed [31:0] sra_result;
    assign sra_result = rs1_signed >>> shamt;

    // ==================== ALU 计算 ====================
    always @(*) begin
        case (opcode_i)
            OP_LUI: begin
                alu_result_o = imm_i;  // LUI: rd = imm << 12 (已在取指阶段左移)
            end
            
            OP_AUIPC: begin
                alu_result_o = PC_i + imm_i;  // AUIPC: rd = PC + (imm << 12)
            end
            
            OP_JAL, OP_JALR: begin
                alu_result_o = PC_i + 32'd4;  // JAL/JALR: rd = PC + 4
            end
            
            OP_LOAD, OP_STORE: begin
                alu_result_o = rs1_data_i + imm_i;  // 地址计算: rs1 + imm
            end
            
            OP_BRANCH: begin
                alu_result_o = 32'd0;  // 分支不写寄存器
            end
            
            OP_ALU: begin
                case (funct3_i)
                    3'b000: alu_result_o = (funct7_i[5]) ? (rs1_data_i - rs2_data_i) :  // SUB
                                                            (rs1_data_i + rs2_data_i);   // ADD
                    3'b001: alu_result_o = rs1_data_i << shamt;                          // SLL
                    3'b010: alu_result_o = ($signed(rs1_data_i) < $signed(rs2_data_i)) ? 32'd1 : 32'd0;  // SLT
                    3'b011: alu_result_o = (rs1_data_i < rs2_data_i) ? 32'd1 : 32'd0;                    // SLTU
                    3'b100: alu_result_o = rs1_data_i ^ rs2_data_i;                      // XOR
                    3'b101: alu_result_o = (funct7_i[5]) ? sra_result :  // SRA
                                                            (rs1_data_i >> shamt);            // SRL
                    3'b110: alu_result_o = rs1_data_i | rs2_data_i;                      // OR
                    3'b111: alu_result_o = rs1_data_i & rs2_data_i;                      // AND
                    default: alu_result_o = 32'd0;
                endcase
            end
            
            OP_ALUI: begin
                case (funct3_i)
                    3'b000: alu_result_o = rs1_data_i + imm_i;                           // ADDI
                    3'b001: alu_result_o = rs1_data_i << shamt;                          // SLLI
                    3'b010: alu_result_o = ($signed(rs1_data_i) < $signed(imm_i)) ? 32'd1 : 32'd0;  // SLTI
                    3'b011: alu_result_o = (rs1_data_i < imm_i) ? 32'd1 : 32'd0;                    // SLTIU
                    3'b100: alu_result_o = rs1_data_i ^ imm_i;                           // XORI
                    3'b101: alu_result_o = (funct7_i[5]) ? sra_result :  // SRAI
                                                            (rs1_data_i >> shamt);            // SRLI
                    3'b110: alu_result_o = rs1_data_i | imm_i;                           // ORI
                    3'b111: alu_result_o = rs1_data_i & imm_i;                           // ANDI
                    default: alu_result_o = 32'd0;
                endcase
            end
            
            default: alu_result_o = 32'd0;
        endcase
    end

    // ==================== 分支条件判断 ====================
    reg branch_cond;
    
    always @(*) begin
        if (opcode_i == OP_BRANCH) begin
            case (funct3_i)
                3'b000: branch_cond = (rs1_data_i == rs2_data_i);                             // BEQ
                3'b001: branch_cond = (rs1_data_i != rs2_data_i);                             // BNE
                3'b100: branch_cond = ($signed(rs1_data_i) < $signed(rs2_data_i));             // BLT
                3'b101: branch_cond = ($signed(rs1_data_i) >= $signed(rs2_data_i));            // BGE
                3'b110: branch_cond = (rs1_data_i < rs2_data_i);                               // BLTU
                3'b111: branch_cond = (rs1_data_i >= rs2_data_i);                              // BGEU
                default: branch_cond = 1'b0;
            endcase
        end else begin
            branch_cond = 1'b0;
        end
    end
    
    assign branch_taken_o = branch_cond;

endmodule
