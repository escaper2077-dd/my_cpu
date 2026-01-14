module fetch(
    input clk,
    input [31:0] PC,
    input [31:0] mem_data,  // 从PC地址读取的32位内存数据
    output reg [31:0] next_PC,
    output reg [47:0] instr_bytes,  // 指令字节，6*8=48位
    output reg [2:0] instr_len  // 指令长度（字节数）
);

    // Y86操作码定义
    localparam NOP = 8'h00;
    localparam HALT = 8'h10;
    localparam RRMOVL = 8'h20;
    localparam IRMOVL = 8'h30;
    localparam RMMOVL = 8'h40;
    localparam MRMOVL = 8'h50;
    localparam ADDL = 8'h60;
    localparam SUBL = 8'h61;
    localparam ANDL = 8'h62;
    localparam XORL = 8'h63;
    localparam JMPL = 8'h70;
    localparam JLE = 8'h71;
    localparam JL = 8'h72;
    localparam JE = 8'h73;
    localparam JNE = 8'h74;
    localparam JGE = 8'h75;
    localparam JG = 8'h76;
    localparam CALL = 8'h80;
    localparam RET = 8'h90;
    localparam PUSHL = 8'hA0;
    localparam POPL = 8'hB0;

    always @(posedge clk) begin
        // 提取指令字节（小端序）
        instr_bytes = {16'b0, mem_data[31:24], mem_data[23:16], mem_data[15:8], mem_data[7:0]};  // 填充前2字节为0，简化

        // 确定指令长度基于操作码
        case (mem_data[7:0])  // 操作码
            NOP, HALT, RET: instr_len = 3'd1;
            RRMOVL, ADDL, SUBL, ANDL, XORL, PUSHL, POPL: instr_len = 3'd2;
            IRMOVL, RMMOVL, MRMOVL: instr_len = 3'd6;  // op + reg + 4字节立即数
            JMPL, JLE, JL, JE, JNE, JGE, JG, CALL: instr_len = 3'd5;  // op + 4字节地址
            default: instr_len = 3'd1;  // 默认1字节
        endcase

        // 计算下一个PC
        next_PC = PC + instr_len;
    end

endmodule
