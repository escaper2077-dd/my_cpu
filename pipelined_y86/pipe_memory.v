`timescale 1ps/1ps

// 流水线Memory阶段
// 访问数据内存
module pipe_memory(
    input wire clk_i,
    input wire rst_n_i,
    
    // 来自EX/MEM寄存器的输入
    input wire [3:0] icode_i,
    input wire [63:0] valA_i,
    input wire [63:0] valE_i,
    input wire [63:0] valP_i,
    
    // 输出
    output reg [63:0] valM_o,
    output wire dmem_error_o
);

    // Y86操作码定义
    localparam NOP    = 4'h0;
    localparam HALT   = 4'h1;
    localparam RRMOVL = 4'h2;
    localparam IRMOVL = 4'h3;
    localparam RMMOVL = 4'h4;
    localparam MRMOVL = 4'h5;
    localparam ALU    = 4'h6;
    localparam JXX    = 4'h7;
    localparam CALL   = 4'h8;
    localparam RET    = 4'h9;
    localparam PUSHL  = 4'hA;
    localparam POPL   = 4'hB;

    // 内部信号
    reg mem_read;
    reg mem_write;
    reg [63:0] mem_addr;
    reg [63:0] mem_data_in;

    // 数据内存
    reg [63:0] data_memory[0:255];
    
    // 初始化内存
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            data_memory[i] = 64'b0;
        end
    end
    
    // 错误检测
    assign dmem_error_o = (mem_read || mem_write) && (mem_addr > 64'd2047);

    // 确定内存操作
    always @(*) begin
        mem_read = 1'b0;
        mem_write = 1'b0;
        mem_addr = 64'b0;
        mem_data_in = 64'b0;
        
        case (icode_i)
            MRMOVL: begin
                mem_read = 1'b1;
                mem_addr = valE_i;
            end
            RMMOVL: begin
                mem_write = 1'b1;
                mem_addr = valE_i;
                mem_data_in = valA_i;
            end
            CALL: begin
                mem_write = 1'b1;
                mem_addr = valE_i;
                mem_data_in = valP_i;
            end
            RET: begin
                mem_read = 1'b1;
                mem_addr = valA_i;
            end
            PUSHL: begin
                mem_write = 1'b1;
                mem_addr = valE_i;
                mem_data_in = valA_i;
            end
            POPL: begin
                mem_read = 1'b1;
                mem_addr = valA_i;
            end
            default: begin
                mem_read = 1'b0;
                mem_write = 1'b0;
            end
        endcase
    end

    // 内存读操作
    always @(*) begin
        if (mem_read && !dmem_error_o) begin
            valM_o = data_memory[mem_addr[10:3]];
        end else begin
            valM_o = 64'b0;
        end
    end

    // 内存写操作（同步）
    always @(posedge clk_i) begin
        if (mem_write && !dmem_error_o) begin
            data_memory[mem_addr[10:3]] <= mem_data_in;
        end
    end

endmodule
