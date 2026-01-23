`timescale 1ps/1ps

// 流水线Decode阶段
// 读取寄存器文件，确定源寄存器和目标寄存器
module pipe_decode(
    input wire clk_i,
    input wire rst_n_i,
    
    // 来自IF/ID寄存器的输入
    input wire [3:0] icode_i,
    input wire [3:0] rA_i,
    input wire [3:0] rB_i,
    
    // 来自WB阶段的写回信号
    input wire [3:0] W_dstE,
    input wire [3:0] W_dstM,
    input wire [63:0] W_valE,
    input wire [63:0] W_valM,
    
    // 输出：读取的寄存器值
    output wire [63:0] valA_o,
    output wire [63:0] valB_o,
    
    // 输出：源寄存器和目标寄存器
    output reg [3:0] srcA_o,
    output reg [3:0] srcB_o,
    output reg [3:0] dstE_o,
    output reg [3:0] dstM_o
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

    // 寄存器文件
    reg [63:0] regfile[14:0];
    
    // 初始化寄存器
    integer i;
    initial begin
        for (i = 0; i < 15; i = i + 1) begin
            regfile[i] = 64'd0;
        end
    end

    // 源寄存器选择
    always @(*) begin
        case (icode_i)
            RRMOVL, IRMOVL, ALU: begin
                srcA_o = rA_i;
                srcB_o = rB_i;
            end
            RMMOVL: begin
                srcA_o = rA_i;
                srcB_o = rB_i;
            end
            MRMOVL: begin
                srcA_o = 4'hF;
                srcB_o = rB_i;
            end
            CALL: begin
                srcA_o = 4'hF;
                srcB_o = 4'h4;  // %rsp
            end
            RET: begin
                srcA_o = 4'h4;  // %rsp
                srcB_o = 4'h4;  // %rsp
            end
            PUSHL: begin
                srcA_o = rA_i;
                srcB_o = 4'h4;  // %rsp
            end
            POPL: begin
                srcA_o = 4'h4;  // %rsp
                srcB_o = 4'h4;  // %rsp
            end
            default: begin
                srcA_o = 4'hF;
                srcB_o = 4'hF;
            end
        endcase
    end

    // 目标寄存器选择
    always @(*) begin
        case (icode_i)
            RRMOVL: begin
                dstE_o = rB_i;
                dstM_o = 4'hF;
            end
            IRMOVL: begin
                dstE_o = rB_i;
                dstM_o = 4'hF;
            end
            RMMOVL: begin
                dstE_o = 4'hF;
                dstM_o = 4'hF;
            end
            MRMOVL: begin
                dstE_o = 4'hF;
                dstM_o = rA_i;
            end
            ALU: begin
                dstE_o = rB_i;
                dstM_o = 4'hF;
            end
            CALL, RET, PUSHL, POPL: begin
                dstE_o = 4'h4;  // %rsp
                dstM_o = (icode_i == POPL) ? rA_i : 4'hF;
            end
            default: begin
                dstE_o = 4'hF;
                dstM_o = 4'hF;
            end
        endcase
    end

    // 读取寄存器
    assign valA_o = (srcA_o == 4'hF) ? 64'b0 : regfile[srcA_o];
    assign valB_o = (srcB_o == 4'hF) ? 64'b0 : regfile[srcB_o];

    // 寄存器写回（时序逻辑）
    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            for (i = 0; i < 15; i = i + 1) begin
                regfile[i] <= 64'd0;
            end
        end else begin
            // 写回valE到dstE
            if (W_dstE != 4'hF) begin
                regfile[W_dstE] <= W_valE;
            end
            
            // 写回valM到dstM
            if (W_dstM != 4'hF) begin
                regfile[W_dstM] <= W_valM;
            end
        end
    end

endmodule
