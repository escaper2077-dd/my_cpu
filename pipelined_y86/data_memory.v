`timescale 1ps/1ps

// 独立的数据内存模块 (Data Memory RAM)
// 64位字对齐访问，256个存储单元 (2KB)
module data_memory(
    input wire clk_i,
    input wire rst_n_i,
    
    // 读端口
    input wire r_en_i,              // 读使能
    input wire [63:0] r_addr_i,     // 读地址
    output wire [63:0] r_data_o,    // 读数据
    
    // 写端口
    input wire w_en_i,              // 写使能
    input wire [63:0] w_addr_i,     // 写地址
    input wire [63:0] w_data_i,     // 写数据
    
    // 错误信号
    output wire error_o             // 地址越界错误
);

    // 数据内存阵列：256个64位字
    reg [63:0] data_mem[0:255];
    
    // 地址有效性检查（地址应在0-2047字节范围内，即0-255个64位字）
    wire r_addr_valid;
    wire w_addr_valid;
    
    assign r_addr_valid = (r_addr_i <= 64'd2047);
    assign w_addr_valid = (w_addr_i <= 64'd2047);
    
    // 错误信号：任意读写操作地址无效
    assign error_o = (r_en_i && !r_addr_valid) || (w_en_i && !w_addr_valid);
    
    // 字地址转换（64位对齐，使用[10:3]位作为字索引）
    wire [7:0] r_word_addr;
    wire [7:0] w_word_addr;
    
    assign r_word_addr = r_addr_i[10:3];
    assign w_word_addr = w_addr_i[10:3];
    
    // 读操作（异步读取，组合逻辑）
    assign r_data_o = (r_en_i && r_addr_valid) ? data_mem[r_word_addr] : 64'h0;
    
    // 写操作（同步写入，时序逻辑）
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            // 复位时不清空内存（保持测试数据）
        end else begin
            if (w_en_i && w_addr_valid) begin
                data_mem[w_word_addr] <= w_data_i;
            end
        end
    end
    
    // 初始化内存（用于测试）
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            data_mem[i] = 64'h0;
        end
    end

endmodule
