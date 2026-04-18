`timescale 1ps/1ps

// ============================================================================
// RISC-V 五级流水线 CPU - 执行阶段 (Execute Stage / ALU)
// 支持 RV32I 全部 ALU 操作和分支条件判断
// 支持数据转发
// ============================================================================

module execute_pipe(
    input wire [6:0]  opcode_i,
    input wire [2:0]  funct3_i,
    input wire [6:0]  funct7_i,
    input wire [31:0] rs1_data_i,
    input wire [31:0] rs2_data_i,
    input wire [31:0] imm_i,
    input wire [31:0] PC_i,
    input wire [31:0] valP_i,
    
    // 转发数据输入
    input wire [1:0]  forward_a,
    input wire [1:0]  forward_b,
    input wire [31:0] ex_forward_data,   // 从 EX/MEM 转发
    input wire [31:0] mem_forward_data,  // 从 MEM/WB 转发
    input wire [31:0] wb_forward_data,   // 从 WB 转发
    
    output reg  [31:0] alu_result_o,
    output wire        branch_taken_o,
    output wire [31:0] branch_target_o
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

    // ==================== 数据转发选择 ====================
    reg [31:0] rs1_forwarded;
    reg [31:0] rs2_forwarded;
    
    always @(*) begin
        case (forward_a)
            2'b00: rs1_forwarded = rs1_data_i;
            2'b01: rs1_forwarded = ex_forward_data;
            2'b10: rs1_forwarded = mem_forward_data;
            2'b11: rs1_forwarded = wb_forward_data;
            default: rs1_forwarded = rs1_data_i;
        endcase
    end
    
    always @(*) begin
        case (forward_b)
            2'b00: rs2_forwarded = rs2_data_i;
            2'b01: rs2_forwarded = ex_forward_data;
            2'b10: rs2_forwarded = mem_forward_data;
            2'b11: rs2_forwarded = wb_forward_data;
            default: rs2_forwarded = rs2_data_i;
        endcase
    end

    // ==================== ALU 操作数选择 ====================
    wire [31:0] alu_a;
    wire [31:0] alu_b;
    
    assign alu_a = (opcode_i == OP_AUIPC) ? PC_i : rs1_forwarded;
    assign alu_b = (opcode_i == OP_ALU || opcode_i == OP_BRANCH) ? rs2_forwarded : imm_i;

    // ==================== 移位量 ====================
    wire [4:0] shamt;
    assign shamt = (opcode_i == OP_ALU) ? rs2_forwarded[4:0] : imm_i[4:0];

    wire signed [31:0] rs1_signed;
    assign rs1_signed = rs1_forwarded;
    wire signed [31:0] sra_result;
    assign sra_result = rs1_signed >>> shamt;

    // ==================== ALU 计算 ====================
    always @(*) begin
        case (opcode_i)
            OP_LUI: begin
                alu_result_o = imm_i;
            end
            
            OP_AUIPC: begin
                alu_result_o = PC_i + imm_i;
            end
            
            OP_JAL, OP_JALR: begin
                alu_result_o = valP_i;
            end
            
            OP_LOAD, OP_STORE: begin
                alu_result_o = rs1_forwarded + imm_i;
            end
            
            OP_BRANCH: begin
                alu_result_o = 32'd0;
            end
            
            OP_ALU: begin
                case (funct3_i)
                    3'b000: alu_result_o = (funct7_i[5]) ? (rs1_forwarded - rs2_forwarded) :
                                                            (rs1_forwarded + rs2_forwarded);
                    3'b001: alu_result_o = rs1_forwarded << shamt;
                    3'b010: alu_result_o = ($signed(rs1_forwarded) < $signed(rs2_forwarded)) ? 32'd1 : 32'd0;
                    3'b011: alu_result_o = (rs1_forwarded < rs2_forwarded) ? 32'd1 : 32'd0;
                    3'b100: alu_result_o = rs1_forwarded ^ rs2_forwarded;
                    3'b101: alu_result_o = (funct7_i[5]) ? sra_result :
                                                            (rs1_forwarded >> shamt);
                    3'b110: alu_result_o = rs1_forwarded | rs2_forwarded;
                    3'b111: alu_result_o = rs1_forwarded & rs2_forwarded;
                    default: alu_result_o = 32'd0;
                endcase
            end
            
            OP_ALUI: begin
                case (funct3_i)
                    3'b000: alu_result_o = rs1_forwarded + imm_i;
                    3'b001: alu_result_o = rs1_forwarded << shamt;
                    3'b010: alu_result_o = ($signed(rs1_forwarded) < $signed(imm_i)) ? 32'd1 : 32'd0;
                    3'b011: alu_result_o = (rs1_forwarded < imm_i) ? 32'd1 : 32'd0;
                    3'b100: alu_result_o = rs1_forwarded ^ imm_i;
                    3'b101: alu_result_o = (funct7_i[5]) ? sra_result :
                                                            (rs1_forwarded >> shamt);
                    3'b110: alu_result_o = rs1_forwarded | imm_i;
                    3'b111: alu_result_o = rs1_forwarded & imm_i;
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
                3'b000: branch_cond = (rs1_forwarded == rs2_forwarded);
                3'b001: branch_cond = (rs1_forwarded != rs2_forwarded);
                3'b100: branch_cond = ($signed(rs1_forwarded) < $signed(rs2_forwarded));
                3'b101: branch_cond = ($signed(rs1_forwarded) >= $signed(rs2_forwarded));
                3'b110: branch_cond = (rs1_forwarded < rs2_forwarded);
                3'b111: branch_cond = (rs1_forwarded >= rs2_forwarded);
                default: branch_cond = 1'b0;
            endcase
        end else begin
            branch_cond = 1'b0;
        end
    end
    
    assign branch_taken_o = (opcode_i == OP_BRANCH && branch_cond) || 
                           (opcode_i == OP_JAL) || 
                           (opcode_i == OP_JALR);

    // ==================== 分支目标计算 ====================
    reg [31:0] branch_target_reg;
    always @(*) begin
        case (opcode_i)
            OP_JAL:
                branch_target_reg = PC_i + imm_i;
            OP_JALR:
                branch_target_reg = (rs1_forwarded + imm_i) & 32'hFFFFFFFE;
            OP_BRANCH:
                branch_target_reg = branch_cond ? (PC_i + imm_i) : valP_i;
            default:
                branch_target_reg = valP_i;
        endcase
    end
    
    assign branch_target_o = branch_target_reg;

endmodule
