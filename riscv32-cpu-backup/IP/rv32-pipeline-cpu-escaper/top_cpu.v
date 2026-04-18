`timescale 1ps/1ps

// ============================================================================
// RISC-V 五级流水线 CPU - 顶层模块
// 五级流水线：IF -> ID -> EX -> MEM -> WB
// 支持数据转发、Load-Use 冒险检测、控制冒险处理
// 符合测试框架要求
// ============================================================================

module top_cpu(
    input  wire        clk,
    input  wire        rst,

    output wire [31:0] cur_pc,
    output wire        commit,
    output wire [31:0] commit_pc,
    output wire [31:0] commit_instr,
    output wire [31:0] commit_next_pc,
    output wire [31:0] commit_mem_addr,
    output wire [31:0] commit_mem_wdata,
    output wire [31:0] commit_mem_rdata
);

    // ==================== 流水线寄存器间的信号 ====================
    
    // IF 阶段
    wire [31:0] if_pc;
    wire [31:0] if_instr;
    wire [6:0]  if_opcode;
    wire [4:0]  if_rd;
    wire [2:0]  if_funct3;
    wire [4:0]  if_rs1;
    wire [4:0]  if_rs2;
    wire [6:0]  if_funct7;
    wire [31:0] if_imm;
    wire [31:0] if_valP;
    
    // IF/ID 寄存器输出
    wire [31:0] id_pc;
    wire [31:0] id_instr;
    wire [31:0] id_valP;
    
    // ID 阶段解码
    wire [6:0]  id_opcode = id_instr[6:0];
    wire [4:0]  id_rd     = id_instr[11:7];
    wire [2:0]  id_funct3 = id_instr[14:12];
    wire [4:0]  id_rs1    = id_instr[19:15];
    wire [4:0]  id_rs2    = id_instr[24:20];
    wire [6:0]  id_funct7 = id_instr[31:25];
    wire [31:0] id_rs1_data;
    wire [31:0] id_rs2_data;
    wire [31:0] id_imm;
    
    // ID/EX 寄存器输出
    wire [31:0] ex_pc;
    wire [31:0] ex_instr;
    wire [31:0] ex_valP;
    wire [6:0]  ex_opcode;
    wire [2:0]  ex_funct3;
    wire [6:0]  ex_funct7;
    wire [4:0]  ex_rs1;
    wire [4:0]  ex_rs2;
    wire [4:0]  ex_rd;
    wire [31:0] ex_rs1_data;
    wire [31:0] ex_rs2_data;
    wire [31:0] ex_imm;
    
    // EX 阶段
    wire [31:0] ex_alu_result;
    wire        ex_branch_taken;
    wire [31:0] ex_branch_target;
    
    // EX/MEM 寄存器输出
    wire [31:0] mem_pc;
    wire [31:0] mem_instr;
    wire [31:0] mem_valP;
    wire [6:0]  mem_opcode;
    wire [2:0]  mem_funct3;
    wire [4:0]  mem_rd;
    wire [31:0] mem_alu_result;
    wire [31:0] mem_rs2_data;
    
    // MEM 阶段
    wire [31:0] mem_data;
    
    // MEM/WB 寄存器输出
    wire [31:0] wb_pc;
    wire [31:0] wb_instr;
    wire [31:0] wb_valP;
    wire [6:0]  wb_opcode;
    wire [4:0]  wb_rd;
    wire [31:0] wb_alu_result;
    wire [31:0] wb_mem_data;
    
    // WB 阶段
    wire        wb_reg_wr_en;
    wire [4:0]  wb_wr_addr;
    wire [31:0] wb_wr_data;
    
    // 冒险检测与转发控制
    wire [1:0]  forward_a;
    wire [1:0]  forward_b;
    wire        stall_if;
    wire        stall_id;
    wire        flush_if_id;
    wire        flush_id_ex;
    wire        flush_ex_mem;
    
    // ==================== 立即数生成（ID 阶段）====================
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

    reg [31:0] id_imm_gen;
    always @(*) begin
        case (id_opcode)
            OP_JALR, OP_LOAD, OP_ALUI, OP_FENCE, OP_SYSTEM:
                id_imm_gen = {{20{id_instr[31]}}, id_instr[31:20]};
            OP_STORE:
                id_imm_gen = {{20{id_instr[31]}}, id_instr[31:25], id_instr[11:7]};
            OP_BRANCH:
                id_imm_gen = {{19{id_instr[31]}}, id_instr[31], id_instr[7], id_instr[30:25], id_instr[11:8], 1'b0};
            OP_LUI, OP_AUIPC:
                id_imm_gen = {id_instr[31:12], 12'b0};
            OP_JAL:
                id_imm_gen = {{11{id_instr[31]}}, id_instr[31], id_instr[19:12], id_instr[20], id_instr[30:21], 1'b0};
            default:
                id_imm_gen = 32'b0;
        endcase
    end
    assign id_imm = id_imm_gen;
    
    // ==================== 各阶段实例化 ====================
    
    // IF 阶段
    fetch_pipe u_fetch(
        .clk           (clk),
        .rst           (rst),
        .stall         (stall_if),
        .branch_taken  (ex_branch_taken),
        .branch_target (ex_branch_target),
        .pc_o          (if_pc),
        .instr_o       (if_instr),
        .opcode_o      (if_opcode),
        .rd_o          (if_rd),
        .funct3_o      (if_funct3),
        .rs1_o         (if_rs1),
        .rs2_o         (if_rs2),
        .funct7_o      (if_funct7),
        .imm_o         (if_imm),
        .valP_o        (if_valP)
    );
    
    // IF/ID 流水线寄存器
    if_id_reg u_if_id_reg(
        .clk       (clk),
        .rst       (rst),
        .stall     (stall_id),
        .flush     (flush_if_id),
        .if_pc     (if_pc),
        .if_instr  (if_instr),
        .if_valP   (if_valP),
        .id_pc     (id_pc),
        .id_instr  (id_instr),
        .id_valP   (id_valP)
    );
    
    // ID 阶段（寄存器文件）
    decode_pipe u_decode(
        .clk          (clk),
        .rst          (rst),
        .rs1_i        (id_rs1),
        .rs2_i        (id_rs2),
        .reg_wr_en_i  (wb_reg_wr_en),
        .wr_addr_i    (wb_wr_addr),
        .wr_data_i    (wb_wr_data),
        .rs1_data_o   (id_rs1_data),
        .rs2_data_o   (id_rs2_data)
    );
    
    // ID/EX 流水线寄存器
    id_ex_reg u_id_ex_reg(
        .clk         (clk),
        .rst         (rst),
        .stall       (1'b0),
        .flush       (flush_id_ex),
        .id_pc       (id_pc),
        .id_instr    (id_instr),
        .id_valP     (id_valP),
        .id_opcode   (id_opcode),
        .id_funct3   (id_funct3),
        .id_funct7   (id_funct7),
        .id_rs1      (id_rs1),
        .id_rs2      (id_rs2),
        .id_rd       (id_rd),
        .id_rs1_data (id_rs1_data),
        .id_rs2_data (id_rs2_data),
        .id_imm      (id_imm),
        .ex_pc       (ex_pc),
        .ex_instr    (ex_instr),
        .ex_valP     (ex_valP),
        .ex_opcode   (ex_opcode),
        .ex_funct3   (ex_funct3),
        .ex_funct7   (ex_funct7),
        .ex_rs1      (ex_rs1),
        .ex_rs2      (ex_rs2),
        .ex_rd       (ex_rd),
        .ex_rs1_data (ex_rs1_data),
        .ex_rs2_data (ex_rs2_data),
        .ex_imm      (ex_imm)
    );
    
    // EX 阶段
    execute_pipe u_execute(
        .opcode_i         (ex_opcode),
        .funct3_i         (ex_funct3),
        .funct7_i         (ex_funct7),
        .rs1_data_i       (ex_rs1_data),
        .rs2_data_i       (ex_rs2_data),
        .imm_i            (ex_imm),
        .PC_i             (ex_pc),
        .valP_i           (ex_valP),
        .forward_a        (forward_a),
        .forward_b        (forward_b),
        .ex_forward_data  (mem_alu_result),
        .mem_forward_data (wb_wr_data),
        .wb_forward_data  (wb_wr_data),
        .alu_result_o     (ex_alu_result),
        .branch_taken_o   (ex_branch_taken),
        .branch_target_o  (ex_branch_target)
    );
    
    // EX/MEM 流水线寄存器
    ex_mem_reg u_ex_mem_reg(
        .clk            (clk),
        .rst            (rst),
        .stall          (1'b0),
        .flush          (flush_ex_mem),
        .ex_pc          (ex_pc),
        .ex_instr       (ex_instr),
        .ex_valP        (ex_valP),
        .ex_opcode      (ex_opcode),
        .ex_funct3      (ex_funct3),
        .ex_rd          (ex_rd),
        .ex_alu_result  (ex_alu_result),
        .ex_rs2_data    (ex_rs2_data),
        .mem_pc         (mem_pc),
        .mem_instr      (mem_instr),
        .mem_valP       (mem_valP),
        .mem_opcode     (mem_opcode),
        .mem_funct3     (mem_funct3),
        .mem_rd         (mem_rd),
        .mem_alu_result (mem_alu_result),
        .mem_rs2_data   (mem_rs2_data)
    );
    
    // MEM 阶段
    memory_access_pipe u_memory(
        .clk          (clk),
        .opcode_i     (mem_opcode),
        .funct3_i     (mem_funct3),
        .alu_result_i (mem_alu_result),
        .rs2_data_i   (mem_rs2_data),
        .PC_i         (mem_pc),
        .mem_data_o   (mem_data)
    );
    
    // MEM/WB 流水线寄存器
    mem_wb_reg u_mem_wb_reg(
        .clk            (clk),
        .rst            (rst),
        .stall          (1'b0),
        .flush          (1'b0),
        .mem_pc         (mem_pc),
        .mem_instr      (mem_instr),
        .mem_valP       (mem_valP),
        .mem_opcode     (mem_opcode),
        .mem_rd         (mem_rd),
        .mem_alu_result (mem_alu_result),
        .mem_data       (mem_data),
        .wb_pc          (wb_pc),
        .wb_instr       (wb_instr),
        .wb_valP        (wb_valP),
        .wb_opcode      (wb_opcode),
        .wb_rd          (wb_rd),
        .wb_alu_result  (wb_alu_result),
        .wb_mem_data    (wb_mem_data)
    );
    
    // WB 阶段
    write_back_pipe u_writeback(
        .opcode_i     (wb_opcode),
        .rd_i         (wb_rd),
        .alu_result_i (wb_alu_result),
        .mem_data_i   (wb_mem_data),
        .valP_i       (wb_valP),
        .reg_wr_en_o  (wb_reg_wr_en),
        .wr_addr_o    (wb_wr_addr),
        .wr_data_o    (wb_wr_data)
    );
    
    // 冒险检测与转发单元
    hazard_unit u_hazard(
        .id_rs1        (id_rs1),
        .id_rs2        (id_rs2),
        .id_opcode     (id_opcode),
        .ex_rd         (ex_rd),
        .ex_opcode     (ex_opcode),
        .ex_branch_taken (ex_branch_taken),
        .mem_rd        (mem_rd),
        .mem_opcode    (mem_opcode),
        .wb_rd         (wb_rd),
        .wb_reg_wr_en  (wb_reg_wr_en),
        .forward_a     (forward_a),
        .forward_b     (forward_b),
        .stall_if      (stall_if),
        .stall_id      (stall_id),
        .flush_if_id   (flush_if_id),
        .flush_id_ex   (flush_id_ex),
        .flush_ex_mem  (flush_ex_mem)
    );
    
    // ==================== commit 信号 ====================
    // WB 阶段的指令才算真正提交
    wire wb_is_valid;
    assign wb_is_valid = (wb_instr != 32'h00000013) || (wb_pc != 32'h80000000);
    
    assign cur_pc            = if_pc;
    assign commit            = wb_is_valid;
    assign commit_pc         = wb_pc;
    assign commit_instr      = wb_instr;
    assign commit_next_pc    = wb_pc + 32'd4;
    assign commit_mem_addr   = 32'd0;
    assign commit_mem_wdata  = 32'd0;
    assign commit_mem_rdata  = 32'd0;

endmodule
