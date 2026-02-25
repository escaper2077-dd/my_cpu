`timescale 1ps/1ps

// Memory阶段 - 按照PIPE框架实现
// 包含数据内存访问和地址计算
module pipe_stage_memory(
    input wire clk_i,
    input wire rst_n_i,
    
    // 来自M流水线寄存器的输入
    input wire [1:0] M_stat,
    input wire [3:0] M_icode,
    input wire [63:0] M_valA,
    input wire [63:0] M_valE,
    input wire [63:0] M_valP,
    input wire [3:0] M_dstE,
    input wire [3:0] M_dstM,
    
    // 输出到W流水线寄存器
    output wire [1:0] m_stat,
    output wire [3:0] m_icode,
    output wire [63:0] m_valE,
    output wire [63:0] m_valM,
    output wire [3:0] m_dstE,
    output wire [3:0] m_dstM
);

    // Y86指令码
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
    
    // 状态码
    localparam STAT_AOK = 2'b00;
    localparam STAT_ADR = 2'b10;
    
    // ============ Memory Control - 内存访问控制 ============
    reg mem_read, mem_write;
    reg [63:0] mem_addr, mem_data;
    wire [63:0] mem_data_out;
    wire mem_error;
    
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
        .w_data_i(mem_data),
        
        // 错误信号
        .error_o(mem_error)
    );
    
    always @(*) begin
        mem_read = 1'b0;
        mem_write = 1'b0;
        mem_addr = 64'h0;
        mem_data = 64'h0;
        
        case (M_icode)
            MRMOVL: begin
                mem_read = 1'b1;
                mem_addr = M_valE;  // 地址来自ALU计算
            end
            RMMOVL: begin
                mem_write = 1'b1;
                mem_addr = M_valE;  // 地址来自ALU计算
                mem_data = M_valA;  // 数据来自寄存器
            end
            CALL, PUSHL: begin
                mem_write = 1'b1;
                mem_addr = M_valE;  // 栈指针
                mem_data = (M_icode == CALL) ? M_valP : M_valA;
            end
            RET, POPL: begin
                mem_read = 1'b1;
                mem_addr = M_valA;  // 从旧栈指针读取
            end
            default: begin
                mem_read = 1'b0;
                mem_write = 1'b0;
            end
        endcase
    end
    
    // ============ 内存读取（使用RAM模块的输出）============
    wire [63:0] valM;
    assign valM = (mem_read && !mem_error) ? mem_data_out : 64'h0;
    
    // ============ 状态更新 ============
    wire [1:0] stat;
    assign stat = mem_error ? STAT_ADR : M_stat;
    
    // ============ 输出信号 ============
    assign m_stat = stat;
    assign m_icode = M_icode;
    assign m_valE = M_valE;
    assign m_valM = valM;
    assign m_dstE = M_dstE;
    assign m_dstM = M_dstM;

endmodule
