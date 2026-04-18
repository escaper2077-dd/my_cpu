`timescale 1ps/1ps

// ============================================================================
// RISC-V 五级流水线 CPU - 流水线寄存器
// IF/ID, ID/EX, EX/MEM, MEM/WB
// NOP = addi x0, x0, 0 = 32'h00000013, opcode = 7'b0010011
// ============================================================================

// ======================== IF/ID 寄存器 ========================
module if_id_reg(
    input wire        clk,
    input wire        rst,
    input wire        stall,
    input wire        flush,

    input wire [31:0] if_pc,
    input wire [31:0] if_instr,
    input wire [31:0] if_pc_plus4,

    output reg [31:0] id_pc,
    output reg [31:0] id_instr,
    output reg [31:0] id_pc_plus4
);
    always @(posedge clk) begin
        if (rst || flush) begin
            id_pc       <= 32'h80000000;
            id_instr    <= 32'h00000013; // NOP
            id_pc_plus4 <= 32'h80000004;
        end else if (!stall) begin
            id_pc       <= if_pc;
            id_instr    <= if_instr;
            id_pc_plus4 <= if_pc_plus4;
        end
    end
endmodule

// ======================== ID/EX 寄存器 ========================
module id_ex_reg(
    input wire        clk,
    input wire        rst,
    input wire        flush,

    input wire [31:0] id_pc,
    input wire [31:0] id_instr,
    input wire [31:0] id_pc_plus4,
    input wire [6:0]  id_opcode,
    input wire [4:0]  id_rd,
    input wire [2:0]  id_funct3,
    input wire [4:0]  id_rs1,
    input wire [4:0]  id_rs2,
    input wire [6:0]  id_funct7,
    input wire [31:0] id_imm,
    input wire [31:0] id_rs1_data,
    input wire [31:0] id_rs2_data,

    output reg [31:0] ex_pc,
    output reg [31:0] ex_instr,
    output reg [31:0] ex_pc_plus4,
    output reg [6:0]  ex_opcode,
    output reg [4:0]  ex_rd,
    output reg [2:0]  ex_funct3,
    output reg [4:0]  ex_rs1,
    output reg [4:0]  ex_rs2,
    output reg [6:0]  ex_funct7,
    output reg [31:0] ex_imm,
    output reg [31:0] ex_rs1_data,
    output reg [31:0] ex_rs2_data
);
    always @(posedge clk) begin
        if (rst || flush) begin
            ex_pc       <= 32'h80000000;
            ex_instr    <= 32'h00000013;
            ex_pc_plus4 <= 32'h80000004;
            ex_opcode   <= 7'b0010011;
            ex_rd       <= 5'd0;
            ex_funct3   <= 3'd0;
            ex_rs1      <= 5'd0;
            ex_rs2      <= 5'd0;
            ex_funct7   <= 7'd0;
            ex_imm      <= 32'd0;
            ex_rs1_data <= 32'd0;
            ex_rs2_data <= 32'd0;
        end else begin
            ex_pc       <= id_pc;
            ex_instr    <= id_instr;
            ex_pc_plus4 <= id_pc_plus4;
            ex_opcode   <= id_opcode;
            ex_rd       <= id_rd;
            ex_funct3   <= id_funct3;
            ex_rs1      <= id_rs1;
            ex_rs2      <= id_rs2;
            ex_funct7   <= id_funct7;
            ex_imm      <= id_imm;
            ex_rs1_data <= id_rs1_data;
            ex_rs2_data <= id_rs2_data;
        end
    end
endmodule

// ======================== EX/MEM 寄存器 ========================
module ex_mem_reg(
    input wire        clk,
    input wire        rst,

    input wire [31:0] ex_pc,
    input wire [31:0] ex_instr,
    input wire [31:0] ex_pc_plus4,
    input wire [6:0]  ex_opcode,
    input wire [4:0]  ex_rd,
    input wire [2:0]  ex_funct3,
    input wire [31:0] ex_alu_result,
    input wire [31:0] ex_rs2_data,     // Store 数据（已转发）
    input wire [31:0] ex_next_pc,

    output reg [31:0] mem_pc,
    output reg [31:0] mem_instr,
    output reg [31:0] mem_pc_plus4,
    output reg [6:0]  mem_opcode,
    output reg [4:0]  mem_rd,
    output reg [2:0]  mem_funct3,
    output reg [31:0] mem_alu_result,
    output reg [31:0] mem_rs2_data,
    output reg [31:0] mem_next_pc
);
    always @(posedge clk) begin
        if (rst) begin
            mem_pc         <= 32'h80000000;
            mem_instr      <= 32'h00000013;
            mem_pc_plus4   <= 32'h80000004;
            mem_opcode     <= 7'b0010011;
            mem_rd         <= 5'd0;
            mem_funct3     <= 3'd0;
            mem_alu_result <= 32'd0;
            mem_rs2_data   <= 32'd0;
            mem_next_pc    <= 32'h80000004;
        end else begin
            mem_pc         <= ex_pc;
            mem_instr      <= ex_instr;
            mem_pc_plus4   <= ex_pc_plus4;
            mem_opcode     <= ex_opcode;
            mem_rd         <= ex_rd;
            mem_funct3     <= ex_funct3;
            mem_alu_result <= ex_alu_result;
            mem_rs2_data   <= ex_rs2_data;
            mem_next_pc    <= ex_next_pc;
        end
    end
endmodule

// ======================== MEM/WB 寄存器 ========================
module mem_wb_reg(
    input wire        clk,
    input wire        rst,

    input wire [31:0] mem_pc,
    input wire [31:0] mem_instr,
    input wire [31:0] mem_pc_plus4,
    input wire [6:0]  mem_opcode,
    input wire [4:0]  mem_rd,
    input wire [31:0] mem_alu_result,
    input wire [31:0] mem_mem_data,
    input wire [31:0] mem_next_pc,

    output reg [31:0] wb_pc,
    output reg [31:0] wb_instr,
    output reg [31:0] wb_pc_plus4,
    output reg [6:0]  wb_opcode,
    output reg [4:0]  wb_rd,
    output reg [31:0] wb_alu_result,
    output reg [31:0] wb_mem_data,
    output reg [31:0] wb_next_pc
);
    always @(posedge clk) begin
        if (rst) begin
            wb_pc         <= 32'h80000000;
            wb_instr      <= 32'h00000013;
            wb_pc_plus4   <= 32'h80000004;
            wb_opcode     <= 7'b0010011;
            wb_rd         <= 5'd0;
            wb_alu_result <= 32'd0;
            wb_mem_data   <= 32'd0;
            wb_next_pc    <= 32'h80000004;
        end else begin
            wb_pc         <= mem_pc;
            wb_instr      <= mem_instr;
            wb_pc_plus4   <= mem_pc_plus4;
            wb_opcode     <= mem_opcode;
            wb_rd         <= mem_rd;
            wb_alu_result <= mem_alu_result;
            wb_mem_data   <= mem_mem_data;
            wb_next_pc    <= mem_next_pc;
        end
    end
endmodule
