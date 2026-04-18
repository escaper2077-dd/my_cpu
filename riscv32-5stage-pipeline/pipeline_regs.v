`timescale 1ps/1ps

// ============================================================================
// RISC-V 五级流水线 CPU - 流水线寄存器
// IF/ID, ID/EX, EX/MEM, MEM/WB 四组流水线寄存器
// 支持 flush 和 stall 控制
// ============================================================================

// ==================== IF/ID 流水线寄存器 ====================
module if_id_reg(
    input wire        clk,
    input wire        rst,
    input wire        stall,      // 暂停信号
    input wire        flush,      // 冲刷信号
    
    // IF 阶段输入
    input wire [31:0] if_pc,
    input wire [31:0] if_instr,
    input wire [31:0] if_valP,
    
    // ID 阶段输出
    output reg [31:0] id_pc,
    output reg [31:0] id_instr,
    output reg [31:0] id_valP
);
    always @(posedge clk) begin
        if (rst || flush) begin
            id_pc    <= 32'h80000000;
            id_instr <= 32'h00000013;  // NOP (ADDI x0, x0, 0)
            id_valP  <= 32'h80000004;
        end else if (!stall) begin
            id_pc    <= if_pc;
            id_instr <= if_instr;
            id_valP  <= if_valP;
        end
    end
endmodule

// ==================== ID/EX 流水线寄存器 ====================
module id_ex_reg(
    input wire        clk,
    input wire        rst,
    input wire        stall,
    input wire        flush,
    
    // ID 阶段输入
    input wire [31:0] id_pc,
    input wire [31:0] id_instr,
    input wire [31:0] id_valP,
    input wire [6:0]  id_opcode,
    input wire [2:0]  id_funct3,
    input wire [6:0]  id_funct7,
    input wire [4:0]  id_rs1,
    input wire [4:0]  id_rs2,
    input wire [4:0]  id_rd,
    input wire [31:0] id_rs1_data,
    input wire [31:0] id_rs2_data,
    input wire [31:0] id_imm,
    
    // EX 阶段输出
    output reg [31:0] ex_pc,
    output reg [31:0] ex_instr,
    output reg [31:0] ex_valP,
    output reg [6:0]  ex_opcode,
    output reg [2:0]  ex_funct3,
    output reg [6:0]  ex_funct7,
    output reg [4:0]  ex_rs1,
    output reg [4:0]  ex_rs2,
    output reg [4:0]  ex_rd,
    output reg [31:0] ex_rs1_data,
    output reg [31:0] ex_rs2_data,
    output reg [31:0] ex_imm
);
    always @(posedge clk) begin
        if (rst || flush) begin
            ex_pc       <= 32'h80000000;
            ex_instr    <= 32'h00000013;
            ex_valP     <= 32'h80000004;
            ex_opcode   <= 7'b0010011;
            ex_funct3   <= 3'b000;
            ex_funct7   <= 7'b0000000;
            ex_rs1      <= 5'd0;
            ex_rs2      <= 5'd0;
            ex_rd       <= 5'd0;
            ex_rs1_data <= 32'd0;
            ex_rs2_data <= 32'd0;
            ex_imm      <= 32'd0;
        end else if (!stall) begin
            ex_pc       <= id_pc;
            ex_instr    <= id_instr;
            ex_valP     <= id_valP;
            ex_opcode   <= id_opcode;
            ex_funct3   <= id_funct3;
            ex_funct7   <= id_funct7;
            ex_rs1      <= id_rs1;
            ex_rs2      <= id_rs2;
            ex_rd       <= id_rd;
            ex_rs1_data <= id_rs1_data;
            ex_rs2_data <= id_rs2_data;
            ex_imm      <= id_imm;
        end
    end
endmodule

// ==================== EX/MEM 流水线寄存器 ====================
module ex_mem_reg(
    input wire        clk,
    input wire        rst,
    input wire        stall,
    input wire        flush,
    
    // EX 阶段输入
    input wire [31:0] ex_pc,
    input wire [31:0] ex_instr,
    input wire [31:0] ex_valP,
    input wire [6:0]  ex_opcode,
    input wire [2:0]  ex_funct3,
    input wire [4:0]  ex_rd,
    input wire [31:0] ex_alu_result,
    input wire [31:0] ex_rs2_data,
    
    // MEM 阶段输出
    output reg [31:0] mem_pc,
    output reg [31:0] mem_instr,
    output reg [31:0] mem_valP,
    output reg [6:0]  mem_opcode,
    output reg [2:0]  mem_funct3,
    output reg [4:0]  mem_rd,
    output reg [31:0] mem_alu_result,
    output reg [31:0] mem_rs2_data
);
    always @(posedge clk) begin
        if (rst || flush) begin
            mem_pc         <= 32'h80000000;
            mem_instr      <= 32'h00000013;
            mem_valP       <= 32'h80000004;
            mem_opcode     <= 7'b0010011;
            mem_funct3     <= 3'b000;
            mem_rd         <= 5'd0;
            mem_alu_result <= 32'd0;
            mem_rs2_data   <= 32'd0;
        end else if (!stall) begin
            mem_pc         <= ex_pc;
            mem_instr      <= ex_instr;
            mem_valP       <= ex_valP;
            mem_opcode     <= ex_opcode;
            mem_funct3     <= ex_funct3;
            mem_rd         <= ex_rd;
            mem_alu_result <= ex_alu_result;
            mem_rs2_data   <= ex_rs2_data;
        end
    end
endmodule

// ==================== MEM/WB 流水线寄存器 ====================
module mem_wb_reg(
    input wire        clk,
    input wire        rst,
    input wire        stall,
    input wire        flush,
    
    // MEM 阶段输入
    input wire [31:0] mem_pc,
    input wire [31:0] mem_instr,
    input wire [31:0] mem_valP,
    input wire [6:0]  mem_opcode,
    input wire [4:0]  mem_rd,
    input wire [31:0] mem_alu_result,
    input wire [31:0] mem_data,
    
    // WB 阶段输出
    output reg [31:0] wb_pc,
    output reg [31:0] wb_instr,
    output reg [31:0] wb_valP,
    output reg [6:0]  wb_opcode,
    output reg [4:0]  wb_rd,
    output reg [31:0] wb_alu_result,
    output reg [31:0] wb_mem_data
);
    always @(posedge clk) begin
        if (rst || flush) begin
            wb_pc         <= 32'h80000000;
            wb_instr      <= 32'h00000013;
            wb_valP       <= 32'h80000004;
            wb_opcode     <= 7'b0010011;
            wb_rd         <= 5'd0;
            wb_alu_result <= 32'd0;
            wb_mem_data   <= 32'd0;
        end else if (!stall) begin
            wb_pc         <= mem_pc;
            wb_instr      <= mem_instr;
            wb_valP       <= mem_valP;
            wb_opcode     <= mem_opcode;
            wb_rd         <= mem_rd;
            wb_alu_result <= mem_alu_result;
            wb_mem_data   <= mem_data;
        end
    end
endmodule
