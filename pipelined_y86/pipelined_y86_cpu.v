`timescale 1ps/1ps

// Y86五级流水线CPU顶层模块 - 基于PIPE框架
module pipelined_y86_cpu(
    input wire clk_i,
    input wire rst_n_i,
    output wire [1:0] cpu_stat_o
);

    // ========== PC相关信号 ==========
    wire [63:0] f_pc;
    wire [63:0] f_predPC;
    
    // ========== F阶段输出 ==========
    wire [1:0] f_stat;
    wire [3:0] f_icode, f_ifun, f_rA, f_rB;
    wire [63:0] f_valC, f_valP;
    
    // ========== F/D寄存器输出 ==========
    wire [1:0] D_stat;
    wire [3:0] D_icode, D_ifun, D_rA, D_rB;
    wire [63:0] D_valC, D_valP;
    
    // ========== D阶段输出 ==========
    wire [1:0] d_stat;
    wire [3:0] d_icode, d_ifun, d_dstE, d_dstM, d_srcA, d_srcB;
    wire [63:0] d_valC, d_valP, d_valA, d_valB;
    
    // ========== D/E寄存器输出 ==========
    wire [1:0] E_stat;
    wire [3:0] E_icode, E_ifun, E_dstE, E_dstM, E_srcA, E_srcB;
    wire [63:0] E_valC, E_valP, E_valA, E_valB;
    
    // ========== E阶段输出 ==========
    wire [1:0] e_stat;
    wire [3:0] e_icode, e_dstE, e_dstM;
    wire [63:0] e_valA, e_valE, e_valC, e_valP;
    wire e_Cnd;
    
    // ========== E/M寄存器输出 ==========
    wire [1:0] M_stat;
    wire [3:0] M_icode, M_dstE, M_dstM;
    wire [63:0] M_valA, M_valE, M_valC, M_valP;
    wire M_Cnd;
    
    // ========== M阶段输出 ==========
    wire [1:0] m_stat;
    wire [3:0] m_icode, m_dstE, m_dstM;
    wire [63:0] m_valE, m_valM;
    
    // ========== M/W寄存器输出 ==========
    wire [1:0] W_stat;
    wire [3:0] W_icode, W_dstE, W_dstM;
    wire [63:0] W_valE, W_valM;
    
    // ========== W阶段输出 ==========
    wire [1:0] w_stat;
    
    // ========== 控制信号 ==========
    wire F_stall, D_stall, D_bubble, E_bubble;
    
    // ========== Final CPU Status (保持非AOK状态) ==========
    reg [1:0] cpu_stat_reg;
    localparam STAT_AOK = 2'b00;
    
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            cpu_stat_reg <= STAT_AOK;
        end else if (w_stat != STAT_AOK) begin
            cpu_stat_reg <= w_stat;  // 一旦变为非AOK，保持该状态
        end
    end
    
    assign cpu_stat_o = cpu_stat_reg;
    
    // ========== 实例化各阶段模块 ==========
    
    // PC选择逻辑
    pipe_pc_logic pc_logic(
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .F_stall(F_stall),
        .f_predPC(f_predPC),
        .M_icode(M_icode),
        .M_Cnd(M_Cnd),
        .M_valC(M_valC),
        .M_valA(M_valA),
        .W_icode(W_icode),
        .W_valM(W_valM),
        .f_pc(f_pc)
    );
    
    // Fetch阶段
    pipe_stage_fetch fetch_stage(
        .f_pc(f_pc),
        .f_stat(f_stat),
        .f_icode(f_icode),
        .f_ifun(f_ifun),
        .f_rA(f_rA),
        .f_rB(f_rB),
        .f_valC(f_valC),
        .f_valP(f_valP),
        .f_predPC(f_predPC)
    );
    
    // F/D流水线寄存器
    pipe_reg_fd fd_reg(
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .stall(D_stall),
        .bubble(D_bubble),
        .f_stat(f_stat),
        .f_icode(f_icode),
        .f_ifun(f_ifun),
        .f_rA(f_rA),
        .f_rB(f_rB),
        .f_valC(f_valC),
        .f_valP(f_valP),
        .D_stat(D_stat),
        .D_icode(D_icode),
        .D_ifun(D_ifun),
        .D_rA(D_rA),
        .D_rB(D_rB),
        .D_valC(D_valC),
        .D_valP(D_valP)
    );
    
    // Decode阶段
    pipe_stage_decode decode_stage(
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .D_stat(D_stat),
        .D_icode(D_icode),
        .D_ifun(D_ifun),
        .D_rA(D_rA),
        .D_rB(D_rB),
        .D_valC(D_valC),
        .D_valP(D_valP),
        // E阶段转发
        .e_dstE(e_dstE),
        .e_valE(e_valE),
        // M阶段转发
        .M_dstE(M_dstE),
        .m_dstM(m_dstM),
        .M_valE(M_valE),
        .m_valM(m_valM),
        // W阶段写回
        .W_dstE(W_dstE),
        .W_valE(W_valE),
        .W_dstM(W_dstM),
        .W_valM(W_valM),
        .d_stat(d_stat),
        .d_icode(d_icode),
        .d_ifun(d_ifun),
        .d_valC(d_valC),
        .d_valP(d_valP),
        .d_valA(d_valA),
        .d_valB(d_valB),
        .d_dstE(d_dstE),
        .d_dstM(d_dstM),
        .d_srcA(d_srcA),
        .d_srcB(d_srcB)
    );
    
    // D/E流水线寄存器
    pipe_reg_de de_reg(
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .bubble(E_bubble),
        .d_stat(d_stat),
        .d_icode(d_icode),
        .d_ifun(d_ifun),
        .d_valC(d_valC),
        .d_valP(d_valP),
        .d_valA(d_valA),
        .d_valB(d_valB),
        .d_dstE(d_dstE),
        .d_dstM(d_dstM),
        .d_srcA(d_srcA),
        .d_srcB(d_srcB),
        .E_stat(E_stat),
        .E_icode(E_icode),
        .E_ifun(E_ifun),
        .E_valC(E_valC),
        .E_valP(E_valP),
        .E_valA(E_valA),
        .E_valB(E_valB),
        .E_dstE(E_dstE),
        .E_dstM(E_dstM),
        .E_srcA(E_srcA),
        .E_srcB(E_srcB)
    );
    
    // Execute阶段
    pipe_stage_execute execute_stage(
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .E_bubble(E_bubble),
        .E_stat(E_stat),
        .E_icode(E_icode),
        .E_ifun(E_ifun),
        .E_valC(E_valC),
        .E_valA(E_valA),
        .E_valB(E_valB),
        .E_dstE(E_dstE),
        .E_dstM(E_dstM),
        .E_srcA(E_srcA),
        .E_srcB(E_srcB),
        .M_dstE(M_dstE),
        .M_valE(M_valE),
        .W_dstM(W_dstM),
        .W_valM(W_valM),
        .W_dstE(W_dstE),
        .W_valE(W_valE),
        .e_stat(e_stat),
        .e_icode(e_icode),
        .e_valA(e_valA),
        .e_valE(e_valE),
        .e_valC(e_valC),
        .e_valP(E_valP),
        .e_dstE(e_dstE),
        .e_dstM(e_dstM),
        .e_Cnd(e_Cnd)
    );
    
    // E/M流水线寄存器
    pipe_reg_em em_reg(
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .bubble(E_bubble),
        .e_stat(e_stat),
        .e_icode(e_icode),
        .e_valA(e_valA),
        .e_valE(e_valE),
        .e_valC(e_valC),
        .e_valP(e_valP),
        .e_dstE(e_dstE),
        .e_dstM(e_dstM),
        .e_Cnd(e_Cnd),
        .M_stat(M_stat),
        .M_icode(M_icode),
        .M_valA(M_valA),
        .M_valE(M_valE),
        .M_valC(M_valC),
        .M_valP(M_valP),
        .M_dstE(M_dstE),
        .M_dstM(M_dstM),
        .M_Cnd(M_Cnd)
    );
    
    // Memory阶段
    pipe_stage_memory memory_stage(
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .M_stat(M_stat),
        .M_icode(M_icode),
        .M_valA(M_valA),
        .M_valE(M_valE),
        .M_valP(M_valP),
        .M_dstE(M_dstE),
        .M_dstM(M_dstM),
        .m_stat(m_stat),
        .m_icode(m_icode),
        .m_valE(m_valE),
        .m_valM(m_valM),
        .m_dstE(m_dstE),
        .m_dstM(m_dstM)
    );
    
    // M/W流水线寄存器
    pipe_reg_mw mw_reg(
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .m_stat(m_stat),
        .m_icode(m_icode),
        .m_valE(m_valE),
        .m_valM(m_valM),
        .m_dstE(m_dstE),
        .m_dstM(m_dstM),
        .W_stat(W_stat),
        .W_icode(W_icode),
        .W_valE(W_valE),
        .W_valM(W_valM),
        .W_dstE(W_dstE),
        .W_dstM(W_dstM)
    );
    
    // WriteBack阶段
    pipe_stage_writeback writeback_stage(
        .W_stat(W_stat),
        .W_icode(W_icode),
        .w_stat(w_stat)
    );
    
    // 控制逻辑
    pipe_control control(
        .D_icode(D_icode),
        .d_srcA(d_srcA),
        .d_srcB(d_srcB),
        .E_icode(E_icode),
        .E_dstM(E_dstM),
        .M_icode(M_icode),
        .M_Cnd(M_Cnd),
        .F_stall(F_stall),
        .D_stall(D_stall),
        .D_bubble(D_bubble),
        .E_bubble(E_bubble)
    );

endmodule
