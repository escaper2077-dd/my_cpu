`timescale 1ps/1ps

// ============================================================================
// RISC-V 单周期 CPU - PC 更新 (PC Update Stage)
// 计算下一个 PC：PC+4 / 分支目标 / JAL / JALR
// rst 高电平复位，复位值 32'h80000000
// ============================================================================

module pc_update(
    // Clock and Reset
    input wire        clk,
    input wire        rst,

    // Input signals
    input wire [6:0]  opcode_i,
    input wire [31:0] PC_i,
    input wire [31:0] imm_i,
    input wire [31:0] rs1_data_i,     // JALR 需要
    input wire [31:0] valP_i,         // PC + 4
    input wire        branch_taken_i, // 分支是否成立

    // Output signals
    output reg  [31:0] PC_o,
    output wire [31:0] next_pc_o      // 组合逻辑下一 PC（供 commit_next_pc）
);

    // 上电初始值：让 PC 在 t=0 就等于复位值，避免 Verilator 默认 0 触发越界取指
    initial begin
        PC_o = 32'h80000000;
    end

    // 操作码定义
    localparam OP_JAL    = 7'b1101111;
    localparam OP_JALR   = 7'b1100111;
    localparam OP_BRANCH = 7'b1100011;

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

    assign next_pc_o = new_PC;

    // PC 寄存器更新（时序逻辑，rst 高电平复位，复位到 0x80000000）
    always @(posedge clk) begin
        if (rst) begin
            PC_o <= 32'h80000000;
        end else begin
            PC_o <= new_PC;
        end
    end

endmodule
