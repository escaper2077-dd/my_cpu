`timescale 1ps/1ps

// ============================================================================
// RISC-V 五级流水线 CPU - 译码阶段 (ID Stage)
// 指令字段拆分 + 立即数生成 + 寄存器文件读取
// ============================================================================

module decode_pipe(
    input  wire        clk,
    input  wire        rst,

    // 来自 IF/ID 寄存器
    input  wire [31:0] instr_i,

    // WB 写回接口
    input  wire        wb_reg_wr_en,
    input  wire [4:0]  wb_wr_addr,
    input  wire [31:0] wb_wr_data,

    // 输出：指令字段
    output wire [6:0]  opcode_o,
    output wire [4:0]  rd_o,
    output wire [2:0]  funct3_o,
    output wire [4:0]  rs1_o,
    output wire [4:0]  rs2_o,
    output wire [6:0]  funct7_o,
    output wire [31:0] imm_o,

    // 输出：寄存器读取数据
    output wire [31:0] rs1_data_o,
    output wire [31:0] rs2_data_o
);

    // ==================== 指令字段拆分 ====================
    assign opcode_o = instr_i[6:0];
    assign rd_o     = instr_i[11:7];
    assign funct3_o = instr_i[14:12];
    assign rs1_o    = instr_i[19:15];
    assign rs2_o    = instr_i[24:20];
    assign funct7_o = instr_i[31:25];

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
                imm_gen = {{20{instr_i[31]}}, instr_i[31:20]};
            OP_STORE:
                imm_gen = {{20{instr_i[31]}}, instr_i[31:25], instr_i[11:7]};
            OP_BRANCH:
                imm_gen = {{19{instr_i[31]}}, instr_i[31], instr_i[7], instr_i[30:25], instr_i[11:8], 1'b0};
            OP_LUI, OP_AUIPC:
                imm_gen = {instr_i[31:12], 12'b0};
            OP_JAL:
                imm_gen = {{11{instr_i[31]}}, instr_i[31], instr_i[19:12], instr_i[20], instr_i[30:21], 1'b0};
            default:
                imm_gen = 32'b0;
        endcase
    end
    assign imm_o = imm_gen;

    // ==================== 寄存器文件 ====================
    reg [31:0] regfile [31:0];

    // DPI-C：将 regfile 暴露给测试框架
    import "DPI-C" function void dpi_read_regfile(input logic [31:0] a []);
    initial begin
        dpi_read_regfile(regfile);
    end

    // CSR 文件（全 0，框架需要）
    reg [31:0] csrfile [4095:0];
    import "DPI-C" function void dpi_read_csrfile(input logic [31:0] a []);
    initial begin
        integer i;
        for (i = 0; i < 4096; i = i + 1)
            csrfile[i] = 32'd0;
        dpi_read_csrfile(csrfile);
    end

    // 组合读（x0 恒为 0）+ WB 写优先：解决同周期 WB 写 / ID 读冲突
    assign rs1_data_o = (rs1_o == 5'd0) ? 32'd0 :
                        (wb_reg_wr_en && wb_wr_addr == rs1_o) ? wb_wr_data :
                        regfile[rs1_o];
    assign rs2_data_o = (rs2_o == 5'd0) ? 32'd0 :
                        (wb_reg_wr_en && wb_wr_addr == rs2_o) ? wb_wr_data :
                        regfile[rs2_o];

    // 时序写回
    integer k;
    always @(posedge clk) begin
        if (rst) begin
            for (k = 0; k < 32; k = k + 1)
                regfile[k] = 32'd0;
        end else begin
            if (wb_reg_wr_en && wb_wr_addr != 5'd0)
                regfile[wb_wr_addr] = wb_wr_data;
        end
    end

endmodule
