`timescale 1ps/1ps

// 五级流水线Y86 CPU顶层模块
module pipelined_y86_cpu(
    input wire clk_i,
    input wire rst_n_i,
    
    // 状态输出
    output wire [1:0] stat_o,
    
    // 调试输出
    output wire [63:0] PC_o,
    output wire [3:0] F_icode_o,
    output wire [3:0] D_icode_o,
    output wire [3:0] E_icode_o,
    output wire [3:0] M_icode_o,
    output wire [3:0] W_icode_o
);

    // ==================== 流水线寄存器信号 ====================
    
    // PC和Fetch阶段
    wire [63:0] F_PC;
    wire [63:0] F_predPC;
    
    // IF/ID寄存器
    wire [63:0] D_PC;
    wire [3:0] D_icode, D_ifun;
    wire [3:0] D_rA, D_rB;
    wire [63:0] D_valC, D_valP;
    wire D_instr_valid, D_imem_error;
    
    // ID/EX寄存器
    wire [63:0] E_PC;
    wire [3:0] E_icode, E_ifun;
    wire [63:0] E_valA, E_valB, E_valC, E_valP;
    wire [3:0] E_dstE, E_dstM;
    wire [3:0] E_srcA, E_srcB;
    wire E_instr_valid, E_imem_error;
    
    // EX/MEM寄存器
    wire [63:0] M_PC;
    wire [3:0] M_icode;
    wire [63:0] M_valA, M_valE, M_valP;
    wire [3:0] M_dstE, M_dstM;
    wire M_Cnd;
    wire M_instr_valid, M_imem_error;
    
    // MEM/WB寄存器
    wire [63:0] W_PC;
    wire [3:0] W_icode;
    wire [63:0] W_valE, W_valM;
    wire [3:0] W_dstE, W_dstM;
    wire W_instr_valid, W_imem_error, W_dmem_error;
    
    // ==================== 阶段间的信号 ====================
    
    // Fetch阶段输出
    wire [63:0] f_PC;
    wire [3:0] f_icode, f_ifun;
    wire [3:0] f_rA, f_rB;
    wire [63:0] f_valC, f_valP;
    wire f_instr_valid, f_imem_error;
    
    // Decode阶段输出
    wire [63:0] d_valA, d_valB;
    wire [3:0] d_srcA, d_srcB;
    wire [3:0] d_dstE, d_dstM;
    
    // Execute阶段输出
    wire [63:0] e_valE;
    wire e_Cnd;
    wire [3:0] e_dstE;
    
    // Memory阶段输出
    wire [63:0] m_valM;
    wire m_dmem_error;
    
    // WriteBack阶段输出
    wire [1:0] w_stat;
    
    // CPU状态寄存器（保持最差的状态）
    reg [1:0] cpu_stat;
    
    localparam STAT_AOK = 2'b00;
    localparam STAT_HLT = 2'b01;
    localparam STAT_ADR = 2'b10;
    localparam STAT_INS = 2'b11;
    
    // 状态保持逻辑：一旦出现非AOK状态就保持
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            cpu_stat <= STAT_AOK;
        end else begin
            // 保持最严重的状态
            if (cpu_stat != STAT_AOK) begin
                cpu_stat <= cpu_stat;  // 保持当前状态
            end else begin
                cpu_stat <= w_stat;  // 更新为新状态
            end
        end
    end
    
    assign stat_o = cpu_stat;
    
    // ==================== 控制信号 ====================
    
    wire F_stall, F_bubble;
    wire D_stall, D_bubble;
    wire E_bubble;
    wire M_bubble;
    wire W_stall;
    
    wire [1:0] forwardA, forwardB;
    
    // ==================== PC选择和Fetch阶段 ====================
    
    assign F_predPC = f_valP;  // 简单的预测：总是预测顺序执行
    
    pipe_pc_select pc_select(
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .M_icode(M_icode),
        .M_Cnd(M_Cnd),
        .M_valA(M_valA),
        .M_valP(M_valP),
        .W_valM(W_valM),
        .F_predPC(F_predPC),
        .F_stall(F_stall),
        .stat_i(cpu_stat),
        .PC_o(F_PC)
    );
    
    pipe_fetch fetch_stage(
        .PC_i(F_PC),
        .PC_o(f_PC),
        .icode_o(f_icode),
        .ifun_o(f_ifun),
        .rA_o(f_rA),
        .rB_o(f_rB),
        .valC_o(f_valC),
        .valP_o(f_valP),
        .instr_valid_o(f_instr_valid),
        .imem_error_o(f_imem_error)
    );
    
    // ==================== IF/ID流水线寄存器 ====================
    
    if_id_reg if_id(
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .stall_i(D_stall),
        .bubble_i(D_bubble),
        .PC_i(f_PC),
        .icode_i(f_icode),
        .ifun_i(f_ifun),
        .rA_i(f_rA),
        .rB_i(f_rB),
        .valC_i(f_valC),
        .valP_i(f_valP),
        .instr_valid_i(f_instr_valid),
        .imem_error_i(f_imem_error),
        .PC_o(D_PC),
        .icode_o(D_icode),
        .ifun_o(D_ifun),
        .rA_o(D_rA),
        .rB_o(D_rB),
        .valC_o(D_valC),
        .valP_o(D_valP),
        .instr_valid_o(D_instr_valid),
        .imem_error_o(D_imem_error)
    );
    
    // ==================== Decode阶段 ====================
    
    pipe_decode decode_stage(
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .icode_i(D_icode),
        .rA_i(D_rA),
        .rB_i(D_rB),
        .W_dstE(W_dstE),
        .W_dstM(W_dstM),
        .W_valE(W_valE),
        .W_valM(W_valM),
        .valA_o(d_valA),
        .valB_o(d_valB),
        .srcA_o(d_srcA),
        .srcB_o(d_srcB),
        .dstE_o(d_dstE),
        .dstM_o(d_dstM)
    );
    
    // ==================== ID/EX流水线寄存器 ====================
    
    id_ex_reg id_ex(
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .stall_i(1'b0),
        .bubble_i(E_bubble),
        .PC_i(D_PC),
        .icode_i(D_icode),
        .ifun_i(D_ifun),
        .valA_i(d_valA),
        .valB_i(d_valB),
        .valC_i(D_valC),
        .valP_i(D_valP),
        .dstE_i(d_dstE),
        .dstM_i(d_dstM),
        .srcA_i(d_srcA),
        .srcB_i(d_srcB),
        .instr_valid_i(D_instr_valid),
        .imem_error_i(D_imem_error),
        .PC_o(E_PC),
        .icode_o(E_icode),
        .ifun_o(E_ifun),
        .valA_o(E_valA),
        .valB_o(E_valB),
        .valC_o(E_valC),
        .valP_o(E_valP),
        .dstE_o(E_dstE),
        .dstM_o(E_dstM),
        .srcA_o(E_srcA),
        .srcB_o(E_srcB),
        .instr_valid_o(E_instr_valid),
        .imem_error_o(E_imem_error)
    );
    
    // ==================== Execute阶段 ====================
    
    pipe_execute execute_stage(
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .icode_i(E_icode),
        .ifun_i(E_ifun),
        .valA_i(E_valA),
        .valB_i(E_valB),
        .valC_i(E_valC),
        .dstE_i(E_dstE),
        .forwardA_i(forwardA),
        .forwardB_i(forwardB),
        .M_valE(M_valE),
        .W_valM(W_valM),
        .W_valE(W_valE),
        .valE_o(e_valE),
        .Cnd_o(e_Cnd),
        .dstE_o(e_dstE)
    );
    
    // ==================== EX/MEM流水线寄存器 ====================
    
    ex_mem_reg ex_mem(
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .stall_i(1'b0),
        .bubble_i(M_bubble),
        .PC_i(E_PC),
        .icode_i(E_icode),
        .valA_i(E_valA),
        .valE_i(e_valE),
        .valP_i(E_valP),
        .dstE_i(e_dstE),
        .dstM_i(E_dstM),
        .Cnd_i(e_Cnd),
        .instr_valid_i(E_instr_valid),
        .imem_error_i(E_imem_error),
        .PC_o(M_PC),
        .icode_o(M_icode),
        .valA_o(M_valA),
        .valE_o(M_valE),
        .valP_o(M_valP),
        .dstE_o(M_dstE),
        .dstM_o(M_dstM),
        .Cnd_o(M_Cnd),
        .instr_valid_o(M_instr_valid),
        .imem_error_o(M_imem_error)
    );
    
    // ==================== Memory阶段 ====================
    
    pipe_memory memory_stage(
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .icode_i(M_icode),
        .valA_i(M_valA),
        .valE_i(M_valE),
        .valP_i(M_valP),
        .valM_o(m_valM),
        .dmem_error_o(m_dmem_error)
    );
    
    // ==================== MEM/WB流水线寄存器 ====================
    
    mem_wb_reg mem_wb(
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .stall_i(W_stall),
        .bubble_i(1'b0),
        .PC_i(M_PC),
        .icode_i(M_icode),
        .valE_i(M_valE),
        .valM_i(m_valM),
        .dstE_i(M_dstE),
        .dstM_i(M_dstM),
        .instr_valid_i(M_instr_valid),
        .imem_error_i(M_imem_error),
        .dmem_error_i(m_dmem_error),
        .PC_o(W_PC),
        .icode_o(W_icode),
        .valE_o(W_valE),
        .valM_o(W_valM),
        .dstE_o(W_dstE),
        .dstM_o(W_dstM),
        .instr_valid_o(W_instr_valid),
        .imem_error_o(W_imem_error),
        .dmem_error_o(W_dmem_error)
    );
    
    // ==================== WriteBack阶段 ====================
    
    pipe_writeback writeback_stage(
        .icode_i(W_icode),
        .instr_valid_i(W_instr_valid),
        .imem_error_i(W_imem_error),
        .dmem_error_i(W_dmem_error),
        .stat_o(w_stat)
    );
    
    // ==================== 冒险检测和转发单元 ====================
    
    hazard_control hazard_ctrl(
        .D_icode(D_icode),
        .E_icode(E_icode),
        .E_dstE(E_dstE),
        .E_dstM(E_dstM),
        .E_srcA(E_srcA),
        .E_srcB(E_srcB),
        .M_icode(M_icode),
        .M_dstE(M_dstE),
        .M_dstM(M_dstM),
        .M_Cnd(M_Cnd),
        .W_icode(W_icode),
        .W_dstE(W_dstE),
        .W_dstM(W_dstM),
        .d_srcA(d_srcA),
        .d_srcB(d_srcB),
        .F_stall(F_stall),
        .F_bubble(F_bubble),
        .D_stall(D_stall),
        .D_bubble(D_bubble),
        .E_bubble(E_bubble),
        .M_bubble(M_bubble),
        .W_stall(W_stall)
    );
    
    forwarding_unit forward_unit(
        .E_srcA(E_srcA),
        .E_srcB(E_srcB),
        .M_dstE(M_dstE),
        .M_dstM(M_dstM),
        .W_dstE(W_dstE),
        .W_dstM(W_dstM),
        .forwardA(forwardA),
        .forwardB(forwardB)
    );
    
    // ==================== 调试输出 ====================
    
    assign PC_o = F_PC;
    assign F_icode_o = f_icode;
    assign D_icode_o = D_icode;
    assign E_icode_o = E_icode;
    assign M_icode_o = M_icode;
    assign W_icode_o = W_icode;

endmodule
