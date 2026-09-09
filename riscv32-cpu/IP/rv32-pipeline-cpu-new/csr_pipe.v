`timescale 1ps/1ps

// ============================================================================
// RISC-V 五级流水线 CPU - CSR 模块
//
// 功能：
//   1. CSR 寄存器文件 (mstatus, mtvec, mepc, mcause, mie, mip 等)
//   2. Trap 处理（ecall/ebreak → 进入机器模式中断/异常处理）
//   3. 中断检测（外部中断 MEI、定时器中断 MTI）
//   4. mret 返回机制
//
// CSR 地址定义（RISC-V 机器模式）：
//   mstatus  = 0x300  - 机器模式状态寄存器
//   misa     = 0x301  - ISA 寄存器（只读）
//   mie      = 0x304  - 中断使能
//   mtvec    = 0x305  - 中断向量基址
//   mscratch = 0x340  - 机器模式暂存寄存器
//   mepc     = 0x341  - 异常返回地址
//   mcause   = 0x342  - 异常原因
//   mtval    = 0x343  - 异常地址/信息
//   mip      = 0x344  - 中断待处理
//   mcycle   = 0xb00  - 周期计数器
//   minstret = 0xb02  - 指令计数器
// ============================================================================

module csr_pipe(
    input  wire        clk,
    input  wire        rst,

    // =============== 来自 ID 阶段（CSR 指令） ==============
    input  wire [11:0] id_csr_addr,       // CSR 地址
    input  wire [31:0] id_csr_wdata,      // CSR 写数据
    input  wire [2:0]  id_csr_op,         // CSR 操作类型：1=CSRRW, 2=CSRRS, 3=CSRRC, 5=CSRRWI, 6=CSRRSI, 7=CSRRCI
    input  wire        id_csr_we,         // CSR 写使能
    input  wire [31:0] id_instr,          // 当前指令（用于 ecall/ebreak/mret 检测）

    // =============== 来自 EX 阶段（Trap 触发） ==============
    input  wire        ex_trap_valid,     // EX 阶段检测到 trap（ecall/ebreak）
    input  wire [31:0] ex_trap_pc,        // 触发 trap 的指令 PC
    input  wire [31:0] ex_trap_cause,     // 异常原因
    input  wire [31:0] ex_trap_tval,      // 异常附加值

    // =============== 中断输入 ==============
    input  wire        meip,              // 机器模式外部中断挂起
    input  wire        mtip,              // 机器模式定时器中断挂起

    // =============== CSR 读输出（到 WB 阶段） ==============
    output wire [31:0] csr_rd_data,       // CSR 读数据

    // =============== Trap 控制输出 ==============
    output wire        trap_enter,        // 本次是否进入 trap（组合逻辑，同周期生效）
    output wire [31:0] trap_target_pc,    // Trap 目标 PC（mtvec）
    output wire        trap_flush_all,    // 冲刷所有流水线阶段

    // =============== mret 控制输出 ==============
    output wire        mret_valid,        // mret 指令有效
    output wire [31:0] mret_target_pc,    // mret 返回地址（mepc）

    // =============== 外部可见 CSR ==============
    output wire [31:0] csr_mstatus,
    output wire [31:0] csr_mtvec,
    output wire [31:0] csr_mepc,
    output wire [31:0] csr_mcause,
    output wire [31:0] csr_mip,
    output wire [31:0] csr_mie
);

    // ============================================================
    // CSR 寄存器文件（4096 × 32bit 地址空间）
    // ============================================================
    reg [31:0] csrfile [4095:0];

    // DPI-C 导出 CSR 文件（用于测试框架）
    import "DPI-C" function void dpi_read_csrfile(input logic [31:0] a []);
    initial begin
        integer i;
        for (i = 0; i < 4096; i = i + 1)
            csrfile[i] = 32'd0;
        dpi_read_csrfile(csrfile);
    end

    // ============================================================
    // CSR 字段位置定义（RISC-V 机器模式）
    // ============================================================
    // mstatus 字段
    wire [1:0]  mstatus_xlen  = 2'b01;  // XLEN=32 (01)
    wire [1:0]  mstatus_mpp   = csrfile[12'h300][12:11]; // 前权限模式
    wire        mstatus_mpie  = csrfile[12'h300][7];     // 前中断使能
    wire        mstatus_mie   = csrfile[12'h300][3];     // 机器模式中断使能

    // mip/mie 字段
    wire        mip_meip      = csrfile[12'h344][11];    // 机器外部中断待处理
    wire        mip_mtip      = csrfile[12'h344][7];     // 机器定时器中断待处理
    wire        mie_meie      = csrfile[12'h304][11];    // 机器外部中断使能
    wire        mie_mtie      = csrfile[12'h304][7];     // 机器定时器中断使能

    // ============================================================
    // CSR 地址常量
    // ============================================================
    localparam CSR_MSTATUS  = 12'h300;
    localparam CSR_MISA     = 12'h301;
    localparam CSR_MIE      = 12'h304;
    localparam CSR_MTVEC    = 12'h305;
    localparam CSR_MSCRATCH = 12'h340;
    localparam CSR_MEPC     = 12'h341;
    localparam CSR_MCAUSE   = 12'h342;
    localparam CSR_MTVAL    = 12'h343;
    localparam CSR_MIP      = 12'h344;
    localparam CSR_MCYCLE   = 12'hb00;
    localparam CSR_MINSTRET = 12'hb02;

    // ============================================================
    // 指令解码
    // ============================================================
    wire is_ecall  = (id_instr == 32'h00000073);
    wire is_ebreak = (id_instr == 32'h00100073);
    wire is_mret   = (id_instr == 32'h30200073);

    // ============================================================
    // Trap 编码
    // ============================================================
    // mcause 编码（RISC-V 特权规范）
    localparam CAUSE_ECALL_M    = 32'd11;   // 机器模式 ecall
    localparam CAUSE_EBREAK     = 32'd3;    // 断点
    localparam CAUSE_MEI        = 32'd11 + 32'h80000000;  // 机器外部中断（bit 31=1）
    localparam CAUSE_MTI        = 32'd7  + 32'h80000000;  // 机器定时器中断（bit 31=1）

    // ============================================================
    // CSR 读操作（组合逻辑）
    // ============================================================
    reg [31:0] csr_read_val;
    always @(*) begin
        case (id_csr_addr)
            CSR_MCYCLE:   csr_read_val = cycle_cnt[31:0];
            CSR_MINSTRET: csr_read_val = instr_cnt[31:0];
            default:      csr_read_val = csrfile[id_csr_addr];
        endcase
    end
    assign csr_rd_data = csr_read_val;

    // ============================================================
    // 中断检测（组合逻辑）
    // ============================================================
    // 外部中断：mie.MEIE & mip.MEIP & mstatus.MIE
    wire interrupt_pending_mei = mie_meie & meip;
    wire interrupt_pending_mti = mie_mtie & mtip;

    // 机器模式下，只有 mstatus.MIE=1 时才响应中断
    wire interrupt_taken;
    reg [31:0] interrupt_cause;
    reg [31:0] interrupt_tval;

    // 中断优先级：MEI > MTI
    assign interrupt_taken = trap_enter ? 1'b0 :  // 已经在处理 trap，不再响应新中断
                             mstatus_mie & (interrupt_pending_mei | interrupt_pending_mti);

    always @(*) begin
        if (interrupt_pending_mei) begin
            interrupt_cause = CAUSE_MEI;
            interrupt_tval  = 32'd0;
        end else if (interrupt_pending_mti) begin
            interrupt_cause = CAUSE_MTI;
            interrupt_tval  = 32'd0;
        end else begin
            interrupt_cause = 32'd0;
            interrupt_tval  = 32'd0;
        end
    end

    // ============================================================
    // Trap 进入条件
    // ============================================================
    // trap_enter: 同步异常（来自 EX 阶段）或中断
    wire sync_trap = ex_trap_valid;
    assign trap_enter      = sync_trap | interrupt_taken;
    assign trap_target_pc  = csrfile[CSR_MTVEC];          // 跳到 mtvec
    assign trap_flush_all  = trap_enter;

    // ============================================================
    // mret 检测
    // ============================================================
    assign mret_valid      = is_mret;
    assign mret_target_pc  = csrfile[CSR_MEPC];

    // ============================================================
    // CSR 写 & Trap 状态更新（时序逻辑）
    // ============================================================
    // mstatus 复位值：mpp=11（M 模式），mpie=0，mie=0
    localparam MSTATUS_RESET = 32'h00001800;

    // 计数器
    reg [63:0] cycle_cnt;
    reg [63:0] instr_cnt;

    // 上一周期是否进入了 trap（用于在下一周期阻止再次触发）
    reg trap_entered_last;

    always @(posedge clk) begin
        if (rst) begin
            // 复位 CSR
            csrfile[CSR_MSTATUS]  <= MSTATUS_RESET;
            csrfile[CSR_MISA]     <= 32'h40001100;  // RV32I + Zicsr
            csrfile[CSR_MIE]      <= 32'd0;
            csrfile[CSR_MTVEC]    <= 32'd0;
            csrfile[CSR_MSCRATCH] <= 32'd0;
            csrfile[CSR_MEPC]     <= 32'd0;
            csrfile[CSR_MCAUSE]   <= 32'd0;
            csrfile[CSR_MTVAL]    <= 32'd0;
            csrfile[CSR_MIP]      <= 32'd0;

            cycle_cnt             <= 64'd0;
            instr_cnt             <= 64'd0;
            trap_entered_last     <= 1'b0;
        end else begin
            // 更新计数器
            cycle_cnt <= cycle_cnt + 64'd1;

            // ============ 1. Trap 进入（优先级最高） ============
            if (trap_enter) begin
                // 保存异常 PC 到 mepc
                if (sync_trap) begin
                    // 同步异常：mepc = 触发指令的 PC
                    csrfile[CSR_MEPC]   <= ex_trap_pc;
                    csrfile[CSR_MCAUSE] <= ex_trap_cause;
                    csrfile[CSR_MTVAL]  <= ex_trap_tval;
                end else begin
                    // 中断：mepc = 当前 PC（中断返回后继续执行）
                    // 注：中断 PC 由 ID 阶段传入（实际由上层决定）
                    csrfile[CSR_MEPC]   <= ex_trap_pc;   // 使用当前 PC
                    csrfile[CSR_MCAUSE] <= interrupt_cause;
                    csrfile[CSR_MTVAL]  <= interrupt_tval;
                end

                // 更新 mstatus
                // mstatus.MPP = 当前权限模式（始终为 3=M-mode）
                // mstatus.MPIE = mstatus.MIE（保存旧的中断使能）
                // mstatus.MIE = 0（进入中断处理，关闭中断）
                csrfile[CSR_MSTATUS][12:11] <= 2'b11;   // MPP = M-mode
                csrfile[CSR_MSTATUS][7]     <= csrfile[CSR_MSTATUS][3];  // MPIE = MIE
                csrfile[CSR_MSTATUS][3]     <= 1'b0;    // MIE = 0

                trap_entered_last <= 1'b1;
            end
            // ============ 2. mret 返回 ============
            else if (is_mret) begin
                // 恢复 mstatus
                // mstatus.MIE = mstatus.MPIE
                // mstatus.MPIE = 1
                // mstatus.MPP = 0（U 模式，但实际上我们保持在 M 模式）
                csrfile[CSR_MSTATUS][3]     <= csrfile[CSR_MSTATUS][7];  // MIE = MPIE
                csrfile[CSR_MSTATUS][7]     <= 1'b1;    // MPIE = 1
                csrfile[CSR_MSTATUS][12:11] <= 2'b00;   // MPP = U-mode

                trap_entered_last <= 1'b0;
            end
            // ============ 3. 普通 CSR 写 ============
            else if (id_csr_we) begin
                case (id_csr_op)
                    3'b001: begin // CSRRW: csr = rs1
                        csrfile[id_csr_addr] <= id_csr_wdata;
                    end
                    3'b010: begin // CSRRS: csr = csr | rs1
                        csrfile[id_csr_addr] <= csr_read_val | id_csr_wdata;
                    end
                    3'b011: begin // CSRRC: csr = csr & ~rs1
                        csrfile[id_csr_addr] <= csr_read_val & ~id_csr_wdata;
                    end
                    3'b101: begin // CSRRWI: csr = zimm
                        csrfile[id_csr_addr] <= id_csr_wdata;
                    end
                    3'b110: begin // CSRRSI: csr = csr | zimm
                        csrfile[id_csr_addr] <= csr_read_val | id_csr_wdata;
                    end
                    3'b111: begin // CSRRCI: csr = csr & ~zimm
                        csrfile[id_csr_addr] <= csr_read_val & ~id_csr_wdata;
                    end
                    default: ;
                endcase
                trap_entered_last <= 1'b0;
            end else begin
                trap_entered_last <= 1'b0;
            end

            // ============ 更新 mip（中断待处理标志） ============
            // mip.MEIP = meip（外部中断源）
            // mip.MTIP = mtip（定时器中断源）
            csrfile[CSR_MIP][11] <= meip;
            csrfile[CSR_MIP][7]  <= mtip;

            // 指令计数（由外部递增）
            // instr_cnt 在顶层更新
        end
    end

    // ============================================================
    // 指令计数器更新（由外部驱动）
    // ============================================================
    always @(posedge clk) begin
        if (!rst) begin
            // instr_cnt 在顶层模块中递增，这里不重复计数
        end
    end

    // ============================================================
    // 导出 CSR 值（供外部使用）
    // ============================================================
    assign csr_mstatus = csrfile[CSR_MSTATUS];
    assign csr_mtvec   = csrfile[CSR_MTVEC];
    assign csr_mepc    = csrfile[CSR_MEPC];
    assign csr_mcause  = csrfile[CSR_MCAUSE];
    assign csr_mip     = csrfile[CSR_MIP];
    assign csr_mie     = csrfile[CSR_MIE];

endmodule
