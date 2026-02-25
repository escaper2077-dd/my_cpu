`timescale 1ps/1ps

module memory_access(
    // Clock and Reset
    input wire clk_i,
    input wire rst_n_i,
    
    // Input signals from Execute stage
    input wire [3:0] icode_i,
    input wire [63:0] valE_i,    // ALU计算结果，用于地址计算
    input wire [63:0] valA_i,    // 来自寄存器文件的值，用于写入数据
    input wire [63:0] valP_i,    // PC+指令长度
    
    // Output signals
    output reg [63:0] valM_o,    // 从内存读取的数据
    output wire dmem_error_o      // 数据内存错误信号
);

    // Y86操作码定义
    localparam NOP    = 4'h0;
    localparam HALT   = 4'h1;
    localparam RRMOVL = 4'h2;
    localparam IRMOVL = 4'h3;
    localparam RMMOVL = 4'h4;  // 寄存器到内存
    localparam MRMOVL = 4'h5;  // 内存到寄存器
    localparam ALU    = 4'h6;
    localparam JXX    = 4'h7;
    localparam CALL   = 4'h8;
    localparam RET    = 4'h9;
    localparam PUSHL  = 4'hA;
    localparam POPL   = 4'hB;

    // 内部信号
    reg mem_read;                // 内存读使能
    reg mem_write;               // 内存写使能
    reg [63:0] mem_addr;         // 内存地址
    reg [63:0] mem_data_in;      // 写入内存的数据
    wire [63:0] mem_data_out;    // 从内存读出的数据
    wire mem_error;              // 内存错误信号

    // 数据内存实例（独立的RAM模块）
    data_memory dmem_inst(
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        
        // 读端口
        .r_en_i(mem_read),
        .r_addr_i(mem_addr),
        .r_data_o(mem_data_out),
        
        // 写端口
        .w_en_i(mem_write),
        .w_addr_i(mem_addr),
        .w_data_i(mem_data_in),
        
        // 错误信号
        .error_o(mem_error)
    );
    
    // 错误信号输出
    assign dmem_error_o = mem_error;

    // 确定内存操作类型和地址
    always @(*) begin
        // 默认值
        mem_read = 1'b0;
        mem_write = 1'b0;
        mem_addr = 64'b0;
        mem_data_in = 64'b0;
        
        case (icode_i)
            MRMOVL: begin
                // 从内存读取到寄存器: M[valE] -> rB
                mem_read = 1'b1;
                mem_addr = valE_i;
            end
            
            RMMOVL: begin
                // 从寄存器写入到内存: rA -> M[valE]
                mem_write = 1'b1;
                mem_addr = valE_i;
                mem_data_in = valA_i;
            end
            
            CALL: begin
                // 调用函数：将返回地址压栈
                // 返回地址valP写入M[valE]（valE是更新后的栈指针）
                mem_write = 1'b1;
                mem_addr = valE_i;
                mem_data_in = valP_i;
            end
            
            RET: begin
                // 从栈中弹出返回地址
                // 从M[valA]读取返回地址（valA是旧的栈指针）
                mem_read = 1'b1;
                mem_addr = valA_i;
            end
            
            PUSHL: begin
                // 压栈操作：将寄存器值写入栈
                // valA写入M[valE]（valE是更新后的栈指针）
                mem_write = 1'b1;
                mem_addr = valE_i;
                mem_data_in = valA_i;
            end
            
            POPL: begin
                // 出栈操作：从栈中读取值
                // 从M[valA]读取（valA是旧的栈指针）
                mem_read = 1'b1;
                mem_addr = valA_i;
            end
            
            default: begin
                // 其他指令不需要访存
                mem_read = 1'b0;
                mem_write = 1'b0;
            end
        endcase
    end

    // 内存读操作（使用RAM模块的输出）
    always @(*) begin
        if (mem_read && !dmem_error_o) begin
            valM_o = mem_data_out;
        end else begin
            valM_o = 64'b0;
        end
    end

endmodule
