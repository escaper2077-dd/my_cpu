`timescale 1ps/1ps

// ============================================================================
// RISC-V 单周期 CPU - PC 更新 (PC Update Stage)
// 计算下一个 PC：PC+4 / 分支目标 / JAL / JALR
// ============================================================================

module pc_update(
    // Clock and Reset
    input wire clk_i,
    input wire rst_n_i,
    
    // Input signals
    input wire [6:0]  opcode_i,
    input wire [31:0] PC_i,
    input wire [31:0] imm_i,
    input wire [31:0] rs1_data_i,     // JALR 需要
    input wire [31:0] valP_i,         // PC + 4
    input wire        branch_taken_i, // 分支是否成立
    input wire [1:0]  stat_i,         // CPU 状态
    
    // Output signal
    output reg [31:0] PC_o
);

    // 操作码定义
    localparam OP_JAL    = 7'b1101111;
    localparam OP_JALR   = 7'b1100111;
    localparam OP_BRANCH = 7'b1100011;

    localparam STAT_AOK = 2'b00;

    // 下一 PC 计算（组合逻辑）
    reg [31:0] new_PC;
    
    always @(*) begin
        case (opcode_i)
            OP_JAL:
                new_PC = PC_i + imm_i;                           // JAL: PC + offset
            OP_JALR:
                new_PC = (rs1_data_i + imm_i) & 32'hFFFFFFFE;   // JALR: (rs1 + imm) & ~1
            OP_BRANCH:
                new_PC = branch_taken_i ? (PC_i + imm_i) : valP_i;  // Branch: PC+offset or PC+4
            default:
                new_PC = valP_i;                                 // PC + 4
        endcase
    end

    // PC 寄存器更新（时序逻辑）
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            PC_o <= 32'h0;
        end else begin
            if (stat_i == STAT_AOK) begin
                PC_o <= new_PC;
            end
            // 非 AOK 状态时 PC 冻结
        end
    end

endmodule
