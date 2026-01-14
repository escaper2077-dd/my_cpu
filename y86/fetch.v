module fetch(
    input clk,
    input [63:0] PC,
    input [63:0] imem_data,  // 从PC读取的64位内存数据（假设足够字节）
    output reg [3:0] icode,
    output reg [3:0] ifun,
    output reg [3:0] rA,
    output reg [3:0] rB,
    output reg [63:0] valC,
    output reg [63:0] valP,
    output reg instr_valid,
    output reg imem_error
);

    reg [3:0] instr_len;  // 内部使用，指令长度

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
        // 解析指令字段（假设小端序）
        icode = imem_data[7:4];
        ifun = imem_data[3:0];
        rA = imem_data[15:12];
        rB = imem_data[11:8];
        valC = {32'b0, imem_data[47:16]};  // valC 32位，扩展为64位

        // 确定指令长度和valP
        case (icode)
            4'h0: begin // NOP
                instr_len = 1;
                valP = PC + 1;
            end
            4'h1: begin // HALT
                instr_len = 1;
                valP = PC + 1;
            end
            4'h2: begin // RRMOVL, CMOVXX
                instr_len = 2;
                valP = PC + 2;
            end
            4'h3: begin // IRMOVL
                instr_len = 6;
                valP = PC + 6;
            end
            4'h4: begin // RMMOVL
                instr_len = 6;
                valP = PC + 6;
            end
            4'h5: begin // MRMOVL
                instr_len = 6;
                valP = PC + 6;
            end
            4'h6: begin // OP
                instr_len = 2;
                valP = PC + 2;
            end
            4'h7: begin // JXX
                instr_len = 5;
                valP = PC + 5;
            end
            4'h8: begin // CALL
                instr_len = 5;
                valP = PC + 5;
            end
            4'h9: begin // RET
                instr_len = 1;
                valP = PC + 1;
            end
            4'hA: begin // PUSHL
                instr_len = 2;
                valP = PC + 2;
            end
            4'hB: begin // POPL
                instr_len = 2;
                valP = PC + 2;
            end
            default: begin
                instr_len = 1;
                valP = PC + 1;
            end
        endcase

        // 指令有效性
        instr_valid = (icode >= 4'h0 && icode <= 4'hB) ? 1 : 0;

        // 内存错误（简化）
        imem_error = 0;
    end

endmodule
