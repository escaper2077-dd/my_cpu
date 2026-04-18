`timescale 1ps/1ps

// ============================================================================
// RISC-V 单周期 CPU - 写回阶段 (Write Back Stage)
// 选择写回数据来源：ALU结果 / 内存数据 / PC+4
// 生成寄存器写使能信号
// ============================================================================

module write_back(
    // Input signals
    input wire [6:0]  opcode_i,
    input wire [4:0]  rd_i,
    input wire [31:0] alu_result_i,
    input wire [31:0] mem_data_i,
    input wire [31:0] valP_i,         // PC + 4

    // Output signals
    output reg        reg_wr_en_o,    // 寄存器写使能
    output wire [4:0] wr_addr_o,      // 写回目标寄存器
    output reg [31:0] wr_data_o       // 写回数据
);

    // 操作码定义
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

    // 写回目标寄存器
    assign wr_addr_o = rd_i;

    // 写回数据选择与写使能
    always @(*) begin
        case (opcode_i)
            OP_LUI, OP_AUIPC, OP_ALU, OP_ALUI: begin
                reg_wr_en_o = 1'b1;
                wr_data_o = alu_result_i;
            end
            OP_JAL, OP_JALR: begin
                reg_wr_en_o = 1'b1;
                wr_data_o = valP_i;       // 保存返回地址 PC+4
            end
            OP_LOAD: begin
                reg_wr_en_o = 1'b1;
                wr_data_o = mem_data_i;    // 从内存加载的数据
            end
            OP_STORE, OP_BRANCH, OP_FENCE: begin
                reg_wr_en_o = 1'b0;       // 不写寄存器
                wr_data_o = 32'd0;
            end
            OP_SYSTEM: begin
                reg_wr_en_o = 1'b0;       // ECALL/EBREAK 不写寄存器
                wr_data_o = 32'd0;
            end
            default: begin
                reg_wr_en_o = 1'b0;
                wr_data_o = 32'd0;
            end
        endcase
    end

endmodule
