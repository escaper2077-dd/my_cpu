`timescale 1ps/1ps

// ============================================================================
// RISC-V 单周期 CPU - 取指阶段 (Fetch Stage)
// 通过 DPI-C dpi_instr_mem_read 从内存取指
// ============================================================================

module fetch(
    // Input
    input  wire [31:0] PC_i,

    // Output — 完整指令及拆分字段
    output wire [31:0] instr_o,
    output wire [6:0]  opcode_o,
    output wire [4:0]  rd_o,
    output wire [2:0]  funct3_o,
    output wire [4:0]  rs1_o,
    output wire [4:0]  rs2_o,
    output wire [6:0]  funct7_o,
    output wire [31:0] imm_o,
    output wire [31:0] valP_o      // PC + 4
);

    // ==================== DPI-C 取指 ====================
    import "DPI-C" function int dpi_instr_mem_read(input int addr);

    // 组合逻辑取指
    assign instr_o = dpi_instr_mem_read(PC_i);

    // ==================== 指令字段拆分 ====================
    wire [31:0] instr = instr_o;

    assign opcode_o = instr[6:0];
    assign rd_o     = instr[11:7];
    assign funct3_o = instr[14:12];
    assign rs1_o    = instr[19:15];
    assign rs2_o    = instr[24:20];
    assign funct7_o = instr[31:25];

    assign valP_o   = PC_i + 32'd4;

    // ==================== 立即数生成 ====================
    localparam OP_LUI    = 7'b0110111;
    localparam OP_AUIPC  = 7'b0010111;
    localparam OP_JAL    = 7'b1101111;
    localparam OP_JALR   = 7'b1100111;
    localparam OP_BRANCH = 7'b1100011;
    localparam OP_LOAD   = 7'b0000011;
    localparam OP_STORE  = 7'b0100011;
    localparam OP_ALUI   = 7'b0010011;
    localparam OP_FENCE  = 7'b0001111;
    localparam OP_SYSTEM = 7'b1110011;

    reg [31:0] imm_gen;
    always @(*) begin
        case (opcode_o)
            OP_JALR, OP_LOAD, OP_ALUI, OP_FENCE, OP_SYSTEM:
                imm_gen = {{20{instr[31]}}, instr[31:20]};
            OP_STORE:
                imm_gen = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            OP_BRANCH:
                imm_gen = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
            OP_LUI, OP_AUIPC:
                imm_gen = {instr[31:12], 12'b0};
            OP_JAL:
                imm_gen = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
            default:
                imm_gen = 32'b0;
        endcase
    end

    assign imm_o = imm_gen;

endmodule
