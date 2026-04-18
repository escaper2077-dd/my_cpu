`timescale 1ps/1ps

// ============================================================================
// RISC-V 五级流水线 CPU - 顶层模块
// IF → ID → EX → MEM → WB
//
// 转发：在 EX 阶段用组合逻辑检测，直接选择 MEM/WB 的数据
// Load-Use 暂停：EX 阶段是 LOAD 且 ID 阶段需要该寄存器 → 暂停 1 周期
// 控制冒险：EX 阶段检测到跳转/分支 → 冲刷 IF/ID 和 ID/EX
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

    // ==================== 性能计数器 ====================
    reg [63:0] cycle_cnt;
    reg [63:0] instr_cnt;
    reg [63:0] stall_cnt;

    // ==================== 冒险控制信号 ====================
    wire [1:0] forward_a, forward_b;
    wire       stall_if, stall_id;
    wire       flush_if_id, flush_id_ex;

    // ==================== IF 阶段信号 ====================
    wire [31:0] if_pc, if_instr, if_pc_plus4;

    // ==================== IF/ID 寄存器输出 ====================
    wire [31:0] id_pc, id_instr, id_pc_plus4;

    // ==================== ID 阶段信号 ====================
    wire [6:0]  id_opcode;
    wire [4:0]  id_rd, id_rs1, id_rs2;
    wire [2:0]  id_funct3;
    wire [6:0]  id_funct7;
    wire [31:0] id_imm;
    wire [31:0] id_rs1_data, id_rs2_data;

    // ==================== ID/EX 寄存器输出 ====================
    wire [31:0] ex_pc, ex_instr, ex_pc_plus4;
    wire [6:0]  ex_opcode;
    wire [4:0]  ex_rd, ex_rs1, ex_rs2;
    wire [2:0]  ex_funct3;
    wire [6:0]  ex_funct7;
    wire [31:0] ex_imm;
    wire [31:0] ex_rs1_data, ex_rs2_data;

    // ==================== EX 阶段信号 ====================
    wire [31:0] ex_alu_result;
    wire        ex_branch_taken;
    wire [31:0] ex_pc_target;
    // Store 数据需要经过转发 MUX（forward_b 选择后的 rs2）
    wire [31:0] ex_rs2_fwd;

    // ==================== EX/MEM 寄存器输出 ====================
    wire [31:0] mem_pc, mem_instr, mem_pc_plus4;
    wire [6:0]  mem_opcode;
    wire [4:0]  mem_rd;
    wire [2:0]  mem_funct3;
    wire [31:0] mem_alu_result;
    wire [31:0] mem_rs2_data;
    wire [31:0] mem_next_pc;

    // ==================== MEM 阶段信号 ====================
    wire [31:0] mem_mem_data;
    wire        mem_reg_wr_en;
    wire [31:0] mem_wr_data;   // MEM 阶段的写回数据（用于转发）

    // ==================== MEM/WB 寄存器输出 ====================
    wire [31:0] wb_pc, wb_instr, wb_pc_plus4;
    wire [6:0]  wb_opcode;
    wire [4:0]  wb_rd;
    wire [31:0] wb_alu_result;
    wire [31:0] wb_mem_data;
    wire [31:0] wb_next_pc;

    // ==================== WB 阶段信号 ====================
    wire        wb_reg_wr_en;
    wire [4:0]  wb_wr_addr;
    wire [31:0] wb_wr_data;

    // ==================================================================
    //                         IF 阶段
    // ==================================================================
    fetch_pipe u_fetch(
        .clk       (clk),
        .rst       (rst),
        .stall     (stall_if),
        .pc_sel    (ex_branch_taken),
        .pc_target (ex_pc_target),
        .pc_o      (if_pc),
        .instr_o   (if_instr),
        .pc_plus4_o(if_pc_plus4)
    );

    // ==================================================================
    //                       IF/ID 寄存器
    // ==================================================================
    if_id_reg u_if_id(
        .clk        (clk),
        .rst        (rst),
        .stall      (stall_id),
        .flush      (flush_if_id),
        .if_pc      (if_pc),
        .if_instr   (if_instr),
        .if_pc_plus4(if_pc_plus4),
        .id_pc      (id_pc),
        .id_instr   (id_instr),
        .id_pc_plus4(id_pc_plus4)
    );

    // ==================================================================
    //                         ID 阶段
    // ==================================================================
    decode_pipe u_decode(
        .clk          (clk),
        .rst          (rst),
        .instr_i      (id_instr),
        .wb_reg_wr_en (wb_reg_wr_en),
        .wb_wr_addr   (wb_wr_addr),
        .wb_wr_data   (wb_wr_data),
        .opcode_o     (id_opcode),
        .rd_o         (id_rd),
        .funct3_o     (id_funct3),
        .rs1_o        (id_rs1),
        .rs2_o        (id_rs2),
        .funct7_o     (id_funct7),
        .imm_o        (id_imm),
        .rs1_data_o   (id_rs1_data),
        .rs2_data_o   (id_rs2_data)
    );

    // ==================================================================
    //                       ID/EX 寄存器
    // ==================================================================
    id_ex_reg u_id_ex(
        .clk         (clk),
        .rst         (rst),
        .flush       (flush_id_ex),
        .id_pc       (id_pc),
        .id_instr    (id_instr),
        .id_pc_plus4 (id_pc_plus4),
        .id_opcode   (id_opcode),
        .id_rd       (id_rd),
        .id_funct3   (id_funct3),
        .id_rs1      (id_rs1),
        .id_rs2      (id_rs2),
        .id_funct7   (id_funct7),
        .id_imm      (id_imm),
        .id_rs1_data (id_rs1_data),
        .id_rs2_data (id_rs2_data),
        .ex_pc       (ex_pc),
        .ex_instr    (ex_instr),
        .ex_pc_plus4 (ex_pc_plus4),
        .ex_opcode   (ex_opcode),
        .ex_rd       (ex_rd),
        .ex_funct3   (ex_funct3),
        .ex_rs1      (ex_rs1),
        .ex_rs2      (ex_rs2),
        .ex_funct7   (ex_funct7),
        .ex_imm      (ex_imm),
        .ex_rs1_data (ex_rs1_data),
        .ex_rs2_data (ex_rs2_data)
    );

    // ==================================================================
    //                         EX 阶段
    // ==================================================================

    // MEM 阶段写回数据（用于转发）：
    // 对于非 LOAD 指令，写回数据就是 ALU 结果
    // 对于 LOAD 指令，数据要等 MEM 阶段读完才有，但 load-use 暂停已经处理了
    // 所以这里直接用 ALU 结果作为 MEM 阶段的转发数据
    // （LOAD 指令的 load-use 暂停保证了不会在下一个周期就需要 LOAD 的结果）
    assign mem_wr_data = mem_alu_result;

    execute_pipe u_execute(
        .opcode_i      (ex_opcode),
        .funct3_i      (ex_funct3),
        .funct7_i      (ex_funct7),
        .rs1_data_i    (ex_rs1_data),
        .rs2_data_i    (ex_rs2_data),
        .imm_i         (ex_imm),
        .pc_i          (ex_pc),
        .pc_plus4_i    (ex_pc_plus4),
        .forward_a_i   (forward_a),
        .forward_b_i   (forward_b),
        .mem_fwd_data_i(mem_wr_data),
        .wb_fwd_data_i (wb_wr_data),
        .alu_result_o  (ex_alu_result),
        .branch_taken_o(ex_branch_taken),
        .pc_target_o   (ex_pc_target)
    );

    // 提取转发后的 rs2 值，供 Store 使用
    // 与 execute_pipe 内部的 rs2_val 逻辑一致
    assign ex_rs2_fwd = (forward_b == 2'b01) ? mem_wr_data :
                        (forward_b == 2'b10) ? wb_wr_data  :
                                               ex_rs2_data;

    // ==================================================================
    //                       EX/MEM 寄存器
    // ==================================================================
    ex_mem_reg u_ex_mem(
        .clk           (clk),
        .rst           (rst),
        .ex_pc         (ex_pc),
        .ex_instr      (ex_instr),
        .ex_pc_plus4   (ex_pc_plus4),
        .ex_opcode     (ex_opcode),
        .ex_rd         (ex_rd),
        .ex_funct3     (ex_funct3),
        .ex_alu_result (ex_alu_result),
        .ex_rs2_data   (ex_rs2_fwd),
        .ex_next_pc    (ex_branch_taken ? ex_pc_target : ex_pc_plus4),
        .mem_pc        (mem_pc),
        .mem_instr     (mem_instr),
        .mem_pc_plus4  (mem_pc_plus4),
        .mem_opcode    (mem_opcode),
        .mem_rd        (mem_rd),
        .mem_funct3    (mem_funct3),
        .mem_alu_result(mem_alu_result),
        .mem_rs2_data  (mem_rs2_data),
        .mem_next_pc   (mem_next_pc)
    );

    // ==================================================================
    //                        MEM 阶段
    // ==================================================================
    memory_access_pipe u_mem(
        .clk         (clk),
        .opcode_i    (mem_opcode),
        .funct3_i    (mem_funct3),
        .alu_result_i(mem_alu_result),
        .rs2_data_i  (mem_rs2_data),
        .pc_i        (mem_pc),
        .mem_data_o  (mem_mem_data)
    );

    // MEM 阶段是否写寄存器（用于 hazard_unit 的转发检测）
    // 简化：只要 rd != 0 且不是 STORE/BRANCH/FENCE/SYSTEM 就写
    localparam OP_STORE  = 7'b0100011;
    localparam OP_BRANCH = 7'b1100011;
    localparam OP_FENCE  = 7'b0001111;
    localparam OP_SYSTEM = 7'b1110011;
    assign mem_reg_wr_en = (mem_rd != 5'd0) &&
                           (mem_opcode != OP_STORE) &&
                           (mem_opcode != OP_BRANCH) &&
                           (mem_opcode != OP_FENCE) &&
                           (mem_opcode != OP_SYSTEM);

    // ==================================================================
    //                      MEM/WB 寄存器
    // ==================================================================
    mem_wb_reg u_mem_wb(
        .clk           (clk),
        .rst           (rst),
        .mem_pc        (mem_pc),
        .mem_instr     (mem_instr),
        .mem_pc_plus4  (mem_pc_plus4),
        .mem_opcode    (mem_opcode),
        .mem_rd        (mem_rd),
        .mem_alu_result(mem_alu_result),
        .mem_mem_data  (mem_mem_data),
        .mem_next_pc   (mem_next_pc),
        .wb_pc         (wb_pc),
        .wb_instr      (wb_instr),
        .wb_pc_plus4   (wb_pc_plus4),
        .wb_opcode     (wb_opcode),
        .wb_rd         (wb_rd),
        .wb_alu_result (wb_alu_result),
        .wb_mem_data   (wb_mem_data),
        .wb_next_pc    (wb_next_pc)
    );

    // ==================================================================
    //                        WB 阶段
    // ==================================================================
    write_back_pipe u_wb(
        .opcode_i    (wb_opcode),
        .rd_i        (wb_rd),
        .alu_result_i(wb_alu_result),
        .mem_data_i  (wb_mem_data),
        .pc_plus4_i  (wb_pc_plus4),
        .reg_wr_en_o (wb_reg_wr_en),
        .wr_addr_o   (wb_wr_addr),
        .wr_data_o   (wb_wr_data)
    );

    // ==================================================================
    //                     冒险检测与转发单元
    // ==================================================================
    hazard_unit u_hazard(
        // 转发检测（EX 阶段 vs MEM/WB 阶段）
        .ex_rs1         (ex_rs1),
        .ex_rs2         (ex_rs2),
        .mem_rd         (mem_rd),
        .mem_opcode     (mem_opcode),
        .mem_reg_wr_en  (mem_reg_wr_en),
        .wb_rd          (wb_wr_addr),
        .wb_reg_wr_en   (wb_reg_wr_en),

        // Load-Use 检测（ID 阶段 vs EX 阶段）
        .id_rs1         (id_rs1),
        .id_rs2         (id_rs2),
        .ex_rd          (ex_rd),
        .ex_opcode      (ex_opcode),

        // 控制冒险
        .ex_branch_taken(ex_branch_taken),

        // 输出
        .forward_a   (forward_a),
        .forward_b   (forward_b),
        .stall_if    (stall_if),
        .stall_id    (stall_id),
        .flush_if_id (flush_if_id),
        .flush_id_ex (flush_id_ex)
    );

    // ==================================================================
    //                      性能计数器
    // ==================================================================
    wire wb_valid = (wb_instr != 32'h00000013) || (wb_pc != 32'h80000000);

    always @(posedge clk) begin
        if (rst) begin
            cycle_cnt <= 64'd0;
            instr_cnt <= 64'd0;
            stall_cnt <= 64'd0;
        end else begin
            cycle_cnt <= cycle_cnt + 64'd1;
            if (wb_valid)
                instr_cnt <= instr_cnt + 64'd1;
            if (stall_if)
                stall_cnt <= stall_cnt + 64'd1;
        end
    end

    // ==================================================================
    //                      commit 信号
    // ==================================================================
    assign cur_pc           = if_pc;
    assign commit           = wb_valid;
    assign commit_pc        = wb_pc;
    assign commit_instr     = wb_instr;
    assign commit_next_pc   = wb_next_pc;
    assign commit_mem_addr  = 32'd0;
    assign commit_mem_wdata = 32'd0;
    assign commit_mem_rdata = 32'd0;

    // ==================================================================
    //                  DPI-C 导出性能计数器
    // ==================================================================
    export "DPI-C" function get_cycle_count;
    export "DPI-C" function get_instr_count;
    export "DPI-C" function get_stall_count;

    function longint get_cycle_count();
        get_cycle_count = cycle_cnt;
    endfunction

    function longint get_instr_count();
        get_instr_count = instr_cnt;
    endfunction

    function longint get_stall_count();
        get_stall_count = stall_cnt;
    endfunction

endmodule
