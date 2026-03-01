`timescale 1ps/1ps

// ============================================================================
// RISC-V 单周期 CPU - 译码 & 寄存器文件 (Decode Stage)
// 包含 32 个 32 位寄存器 (x0 恒为 0)
// 组合读取 + 时序写回
// ============================================================================

module decode(
    // Clock and Reset
    input wire clk_i,
    input wire rst_n_i,
    
    // Input signals from Fetch
    input wire [6:0]  opcode_i,
    input wire [4:0]  rs1_i,
    input wire [4:0]  rs2_i,
    input wire [4:0]  rd_i,
    
    // Input signals from Write-back (for register write)
    input wire        reg_wr_en_i,   // 寄存器写使能
    input wire [4:0]  wr_addr_i,     // 写回目标寄存器地址
    input wire [31:0] wr_data_i,     // 写回数据
    
    // Output signals
    output wire [31:0] rs1_data_o,   // rs1 读数据
    output wire [31:0] rs2_data_o    // rs2 读数据
);

    // ==================== 寄存器文件 ====================
    reg [31:0] regfile [0:31];

    // 寄存器初始化
    integer k;
    initial begin
        for (k = 0; k < 32; k = k + 1) begin
            regfile[k] = 32'd0;
        end
    end

    // 组合读取 (x0 恒为 0)
    assign rs1_data_o = (rs1_i == 5'd0) ? 32'd0 : regfile[rs1_i];
    assign rs2_data_o = (rs2_i == 5'd0) ? 32'd0 : regfile[rs2_i];

    // 时序写回（时钟上升沿）
    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            // 复位时清零所有寄存器
            for (k = 0; k < 32; k = k + 1) begin
                regfile[k] <= 32'd0;
            end
        end else begin
            if (reg_wr_en_i && wr_addr_i != 5'd0) begin
                regfile[wr_addr_i] <= wr_data_i;
            end
        end
    end

endmodule
