`timescale 1ps/1ps

// ============================================================================
// RISC-V 五级流水线 CPU - 执行阶段 (EX Stage)
// ALU 计算 + 分支判断 + 跳转目标计算
// 转发 MUX 在此阶段：用 EX 阶段的 rs1/rs2 与 MEM/WB 的 rd 比较
// ============================================================================

module execute_pipe(
    // 来自 ID/EX 寄存器
    input wire [6:0]  opcode_i,
    input wire [2:0]  funct3_i,
    input wire [6:0]  funct7_i,
    input wire [31:0] rs1_data_i,     // 从寄存器文件读出的原始值
    input wire [31:0] rs2_data_i,
    input wire [31:0] imm_i,
    input wire [31:0] pc_i,
    input wire [31:0] pc_plus4_i,

    // 转发控制（组合逻辑，由 hazard_unit 生成）
    input wire [1:0]  forward_a_i,    // 00=无转发, 01=从MEM, 10=从WB
    input wire [1:0]  forward_b_i,
    input wire [31:0] mem_fwd_data_i, // MEM 阶段转发数据
    input wire [31:0] wb_fwd_data_i,  // WB  阶段转发数据

    // 输出
    output reg  [31:0] alu_result_o,
    output wire        branch_taken_o,  // 需要跳转/分支成立
    output wire [31:0] pc_target_o      // 跳转/分支目标地址
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

    // ==================== 转发 MUX ====================
    reg [31:0] rs1_val;
    reg [31:0] rs2_val;

    always @(*) begin
        case (forward_a_i)
            2'b01:   rs1_val = mem_fwd_data_i;
            2'b10:   rs1_val = wb_fwd_data_i;
            default: rs1_val = rs1_data_i;
        endcase
    end

    always @(*) begin
        case (forward_b_i)
            2'b01:   rs2_val = mem_fwd_data_i;
            2'b10:   rs2_val = wb_fwd_data_i;
            default: rs2_val = rs2_data_i;
        endcase
    end

    // ==================== 移位量 ====================
    wire [4:0] shamt;
    assign shamt = (opcode_i == OP_ALU) ? rs2_val[4:0] : imm_i[4:0];

    wire signed [31:0] rs1_signed;
    assign rs1_signed = rs1_val;
    wire signed [31:0] sra_result;
    assign sra_result = rs1_signed >>> shamt;

    // ==================== ALU 计算 ====================
    always @(*) begin
        case (opcode_i)
            OP_LUI:
                alu_result_o = imm_i;

            OP_AUIPC:
                alu_result_o = pc_i + imm_i;

            OP_JAL, OP_JALR:
                alu_result_o = pc_plus4_i;       // 返回地址 = PC+4

            OP_LOAD, OP_STORE:
                alu_result_o = rs1_val + imm_i;  // 地址计算

            OP_BRANCH:
                alu_result_o = 32'd0;

            OP_ALU: begin
                case (funct3_i)
                    3'b000: alu_result_o = funct7_i[5] ? (rs1_val - rs2_val) : (rs1_val + rs2_val);
                    3'b001: alu_result_o = rs1_val << shamt;
                    3'b010: alu_result_o = ($signed(rs1_val) < $signed(rs2_val)) ? 32'd1 : 32'd0;
                    3'b011: alu_result_o = (rs1_val < rs2_val) ? 32'd1 : 32'd0;
                    3'b100: alu_result_o = rs1_val ^ rs2_val;
                    3'b101: alu_result_o = funct7_i[5] ? sra_result : (rs1_val >> shamt);
                    3'b110: alu_result_o = rs1_val | rs2_val;
                    3'b111: alu_result_o = rs1_val & rs2_val;
                    default: alu_result_o = 32'd0;
                endcase
            end

            OP_ALUI: begin
                case (funct3_i)
                    3'b000: alu_result_o = rs1_val + imm_i;
                    3'b001: alu_result_o = rs1_val << shamt;
                    3'b010: alu_result_o = ($signed(rs1_val) < $signed(imm_i)) ? 32'd1 : 32'd0;
                    3'b011: alu_result_o = (rs1_val < imm_i) ? 32'd1 : 32'd0;
                    3'b100: alu_result_o = rs1_val ^ imm_i;
                    3'b101: alu_result_o = funct7_i[5] ? sra_result : (rs1_val >> shamt);
                    3'b110: alu_result_o = rs1_val | imm_i;
                    3'b111: alu_result_o = rs1_val & imm_i;
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
                3'b000: branch_cond = (rs1_val == rs2_val);
                3'b001: branch_cond = (rs1_val != rs2_val);
                3'b100: branch_cond = ($signed(rs1_val) < $signed(rs2_val));
                3'b101: branch_cond = ($signed(rs1_val) >= $signed(rs2_val));
                3'b110: branch_cond = (rs1_val < rs2_val);
                3'b111: branch_cond = (rs1_val >= rs2_val);
                default: branch_cond = 1'b0;
            endcase
        end else
            branch_cond = 1'b0;
    end

    // ==================== 跳转信号 ====================
    assign branch_taken_o = (opcode_i == OP_JAL) ||
                            (opcode_i == OP_JALR) ||
                            (opcode_i == OP_BRANCH && branch_cond);

    // ==================== 跳转目标地址 ====================
    reg [31:0] pc_target_reg;
    always @(*) begin
        case (opcode_i)
            OP_JAL:    pc_target_reg = pc_i + imm_i;
            OP_JALR:   pc_target_reg = (rs1_val + imm_i) & 32'hFFFFFFFE;
            OP_BRANCH: pc_target_reg = pc_i + imm_i;
            default:   pc_target_reg = pc_plus4_i;
        endcase
    end
    assign pc_target_o = pc_target_reg;

endmodule
