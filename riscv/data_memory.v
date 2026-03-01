`timescale 1ps/1ps

// ============================================================================
// RISC-V 单周期 CPU - 数据内存 (Data Memory)
// 支持字节(8)、半字(16)、字(32)访问，小端序
// 1024 words = 4096 字节地址空间
// ============================================================================

module data_memory(
    input wire clk_i,
    input wire rst_n_i,
    
    // 读端口
    input wire        r_en_i,
    input wire [31:0] r_addr_i,
    input wire [2:0]  r_funct3_i,    // 区分 LB/LH/LW/LBU/LHU
    output reg [31:0] r_data_o,
    
    // 写端口
    input wire        w_en_i,
    input wire [31:0] w_addr_i,
    input wire [2:0]  w_funct3_i,    // 区分 SB/SH/SW
    input wire [31:0] w_data_i,
    
    // 错误信号
    output wire error_o
);

    // 数据内存 - 按字节存储，4096 字节
    reg [7:0] mem [0:4095];

    // 地址有效性检查
    wire r_addr_valid;
    wire w_addr_valid;
    
    assign r_addr_valid = (r_addr_i <= 32'd4095);
    assign w_addr_valid = (w_addr_i <= 32'd4095);
    
    assign error_o = (r_en_i && !r_addr_valid) || (w_en_i && !w_addr_valid);

    // ==================== 异步读 ====================
    always @(*) begin
        if (r_en_i && r_addr_valid) begin
            case (r_funct3_i)
                3'b000: // LB - 加载字节（符号扩展）
                    r_data_o = {{24{mem[r_addr_i][7]}}, mem[r_addr_i]};
                3'b001: // LH - 加载半字（符号扩展）
                    r_data_o = {{16{mem[r_addr_i + 1][7]}}, mem[r_addr_i + 1], mem[r_addr_i]};
                3'b010: // LW - 加载字
                    r_data_o = {mem[r_addr_i + 3], mem[r_addr_i + 2], mem[r_addr_i + 1], mem[r_addr_i]};
                3'b100: // LBU - 加载无符号字节
                    r_data_o = {24'b0, mem[r_addr_i]};
                3'b101: // LHU - 加载无符号半字
                    r_data_o = {16'b0, mem[r_addr_i + 1], mem[r_addr_i]};
                default:
                    r_data_o = 32'd0;
            endcase
        end else begin
            r_data_o = 32'd0;
        end
    end

    // ==================== 同步写 ====================
    always @(posedge clk_i) begin
        if (rst_n_i) begin
            if (w_en_i && w_addr_valid) begin
                case (w_funct3_i)
                    3'b000: // SB - 存字节
                        mem[w_addr_i] <= w_data_i[7:0];
                    3'b001: begin // SH - 存半字
                        mem[w_addr_i]     <= w_data_i[7:0];
                        mem[w_addr_i + 1] <= w_data_i[15:8];
                    end
                    3'b010: begin // SW - 存字
                        mem[w_addr_i]     <= w_data_i[7:0];
                        mem[w_addr_i + 1] <= w_data_i[15:8];
                        mem[w_addr_i + 2] <= w_data_i[23:16];
                        mem[w_addr_i + 3] <= w_data_i[31:24];
                    end
                    default: ; // 不操作
                endcase
            end
        end
    end

    // 初始化
    integer i;
    initial begin
        for (i = 0; i < 4096; i = i + 1) begin
            mem[i] = 8'h0;
        end
    end

endmodule
