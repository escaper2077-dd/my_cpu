`timescale 1ps/1ps

// ============================================================================
// RISC-V 五级流水线 CPU - 译码 & 寄存器文件 (Decode Stage)
// 32 个 32 位寄存器，x0 恒为 0
// 通过 DPI-C dpi_read_regfile 将 regfile 暴露给测试框架
// 支持数据转发
// ============================================================================

module decode_pipe(
    input  wire        clk,
    input  wire        rst,

    input  wire [4:0]  rs1_i,
    input  wire [4:0]  rs2_i,

    // 来自 WB 阶段的写回信号
    input  wire        reg_wr_en_i,
    input  wire [4:0]  wr_addr_i,
    input  wire [31:0] wr_data_i,

    output wire [31:0] rs1_data_o,
    output wire [31:0] rs2_data_o
);

    // ==================== 寄存器文件 ====================
    reg [31:0] regfile[31:0];

    // ---------- DPI-C：将 regfile 传递给测试框架 ----------
    import "DPI-C" function void dpi_read_regfile(input logic [31:0] a []);
    initial begin
        dpi_read_regfile(regfile);
    end

    // ==================== CSR 文件（全 0，不实现 CSR 指令）====================
    reg [31:0] csrfile[4095:0];
    import "DPI-C" function void dpi_read_csrfile(input logic [31:0] a []);
    initial begin
        integer i;
        for (i = 0; i < 4096; i = i + 1)
            csrfile[i] = 32'd0;
        dpi_read_csrfile(csrfile);
    end

    // 组合读（x0 恒为 0）
    // 内部转发：如果写回地址与读取地址相同，直接转发写回数据
    assign rs1_data_o = (rs1_i == 5'd0) ? 32'd0 :
                       (reg_wr_en_i && (wr_addr_i == rs1_i)) ? wr_data_i : 
                       regfile[rs1_i];
    
    assign rs2_data_o = (rs2_i == 5'd0) ? 32'd0 :
                       (reg_wr_en_i && (wr_addr_i == rs2_i)) ? wr_data_i : 
                       regfile[rs2_i];

    // 时序写回（rst 高电平复位，仅复位 x0）
    integer k;
    always @(posedge clk) begin
        if (rst) begin
            for (k = 0; k < 32; k = k + 1)
                regfile[k] <= 32'd0;
        end else begin
            if (reg_wr_en_i && wr_addr_i != 5'd0)
                regfile[wr_addr_i] <= wr_data_i;
        end
    end

endmodule
