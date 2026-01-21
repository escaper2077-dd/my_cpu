`timescale 1ps/1ps

module pc_update(
    // Clock and Reset
    input wire clk_i,
    input wire rst_n_i,
    
    // Input signals
    input wire [3:0] icode_i,
    input wire cnd_i,
    input wire [63:0] valC_i,
    input wire [63:0] valM_i,
    input wire [63:0] valP_i,
    input wire [1:0] stat_i,   // 添加状态输入
    
    // Output signal
    output reg [63:0] PC_o
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

    // 状态码定义
    localparam STAT_AOK = 2'b00;  // 正常运行
    localparam STAT_HLT = 2'b01;  // 遇到 halt 指令
    localparam STAT_ADR = 2'b10;  // 地址错误
    localparam STAT_INS = 2'b11;  // 非法指令

    // 新的 PC 值（组合逻辑）
    reg [63:0] new_PC;
    
    always @(*) begin
        case (icode_i)
            CALL: begin
                // CALL 指令：PC = Dest (valC)
                new_PC = valC_i;
            end
            RET: begin
                // RET 指令：PC = 从栈中弹出的返回地址 (valM)
                new_PC = valM_i;
            end
            JXX: begin
                // JXX 指令：如果条件满足，PC = Dest (valC)；否则 PC = valP
                new_PC = cnd_i ? valC_i : valP_i;
            end
            default: begin
                // 其他指令：PC = valP (PC + 指令长度)
                new_PC = valP_i;
            end
        endcase
    end

    // 在时钟上升沿更新 PC
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            PC_o <= 64'h0;  // 复位时 PC = 0
        end else begin
            // 如果 CPU 停止（HALT、地址错误或非法指令），PC 不更新
            if (stat_i == STAT_AOK) begin
                PC_o <= new_PC;
            end
            // 否则保持当前 PC 值（不执行任何操作）
        end
    end

endmodule
