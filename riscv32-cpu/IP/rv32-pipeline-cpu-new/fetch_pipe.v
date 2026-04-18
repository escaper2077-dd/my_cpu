`timescale 1ps/1ps

// ============================================================================
// RISC-V 五级流水线 CPU - 取指阶段 (IF Stage)
// 通过 DPI-C 取指，包含 PC 寄存器
// ============================================================================

module fetch_pipe(
    input  wire        clk,
    input  wire        rst,
    input  wire        stall,          // 来自 hazard unit 的暂停
    input  wire        pc_sel,         // 1=跳转目标, 0=PC+4
    input  wire [31:0] pc_target,      // 跳转/分支目标地址

    output wire [31:0] pc_o,
    output wire [31:0] instr_o,
    output wire [31:0] pc_plus4_o
);

    // ==================== PC 寄存器 ====================
    reg [31:0] PC;

    initial begin
        PC = 32'h80000000;
    end

    always @(posedge clk) begin
        if (rst)
            PC <= 32'h80000000;
        else if (!stall)
            PC <= pc_sel ? pc_target : (PC + 32'd4);
    end

    assign pc_o      = PC;
    assign pc_plus4_o = PC + 32'd4;

    // ==================== DPI-C 取指 ====================
    import "DPI-C" function int dpi_instr_mem_read(input int addr);

    assign instr_o = dpi_instr_mem_read(PC);

endmodule
