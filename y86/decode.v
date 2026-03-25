`timescale 1ps/1ps

module decode(
    // Clock and Reset
    input wire clk_i,
    input wire rst_n_i,
    
    // Input signals from Fetch
    input wire [3:0] icode_i,
    input wire [3:0] rA_i,
    input wire [3:0] rB_i,
    
    // Input signals from Write-back (for register write)
    input wire [63:0] valE_i,
    input wire [63:0] valM_i,
    input wire cnd_i,
    
    // Output signals
    output wire [63:0] valA_o,
    output wire [63:0] valB_o
);

    // Y86操作码定义 (icode - 指令码的高4位)
    localparam NOP    = 4'h0;
    localparam HALT   = 4'h1;
    localparam RRMOVL = 4'h2;
    localparam IRMOVL = 4'h3;
    localparam RMMOVL = 4'h4;
    localparam MRMOVL = 4'h5;
    localparam ALU    = 4'h6;  // ADDL, SUBL, ANDL, XORL
    localparam JXX    = 4'h7;  // JMPL, JLE, JL, JE, JNE, JGE, JG
    localparam CALL   = 4'h8;
    localparam RET    = 4'h9;
    localparam PUSHL  = 4'hA;
    localparam POPL   = 4'hB;

    // 寄存器文件
    reg [63:0] regfile[14:0];  // 15个寄存器 (RAX-R14, %r15不存储)

    // 寄存器初始化 - 全部为0，测试程序需显式初始化
    initial begin
        regfile[0]  = 64'd0;     // %rax
        regfile[1]  = 64'd0;     // %rcx
        regfile[2]  = 64'd0;     // %rdx
        regfile[3]  = 64'd0;     // %rbx
        regfile[4]  = 64'd0;     // %rsp
        regfile[5]  = 64'd0;     // %rbp
        regfile[6]  = 64'd0;     // %rsi
        regfile[7]  = 64'd0;     // %rdi
        regfile[8]  = 64'd0;     // %r8
        regfile[9]  = 64'd0;     // %r9
        regfile[10] = 64'd0;     // %r10
        regfile[11] = 64'd0;     // %r11
        regfile[12] = 64'd0;     // %r12
        regfile[13] = 64'd0;     // %r13
        regfile[14] = 64'd0;     // %r14
    end

    // 根据指令类型读取寄存器 - 使用case语句选择srcA和srcB
    // srcA/srcB的选择逻辑：
    // - 需要regids且用到该源操作数的指令读实际寄存器
    // - PUSHL/POPL中F被特殊对待为%rsp(4)
    // - 不需要的寄存器设为F（无效）
    reg [3:0] srcA;
    reg [3:0] srcB;
    
    always @(*) begin
        case (icode_i)
            NOP: begin
                srcA = 4'hF;
                srcB = 4'hF;
            end
            HALT: begin
                srcA = 4'hF;
                srcB = 4'hF;
            end
            RRMOVL: begin
                srcA = rA_i;
                srcB = rB_i;
            end
            IRMOVL: begin
                srcA = rA_i;
                srcB = rB_i;
            end
            RMMOVL: begin
                srcA = rA_i;
                srcB = rB_i;
            end
            MRMOVL: begin
                srcA = rA_i;
                srcB = rB_i;
            end
            ALU: begin
                srcA = rA_i;
                srcB = rB_i;
            end
            JXX: begin
                srcA = 4'hF;
                srcB = 4'hF;
            end
            CALL: begin
                srcA = 4'hF;
                srcB = 4'h4;  // CALL需要读取%rsp来计算新栈指针
            end
            RET: begin
                srcA = 4'h4;  // RET需要读取%rsp来读取返回地址
                srcB = 4'h4;  // 同时也需要%rsp来计算新的栈指针
            end
            PUSHL: begin
                srcA = rA_i;                           // 读取要入栈的寄存器
                srcB = 4'h4;                           // srcB总是%rsp(4)，用于计算新栈指针
            end
            POPL: begin
                srcA = 4'h4;                           // srcA读取%rsp，用于内存访问
                srcB = 4'h4;                           // srcB也读取%rsp，用于计算新栈指针
            end
            default: begin
                srcA = 4'hF;
                srcB = 4'hF;
            end
        endcase
    end

    // 从寄存器文件读出valA_o和valB_o
    // 当寄存器编号为0xF时，输出0
    assign valA_o = (srcA == 4'hF) ? 64'b0 : regfile[srcA];
    assign valB_o = (srcB == 4'hF) ? 64'b0 : regfile[srcB];

    // ==================== 目标寄存器选择 ====================
    // dstE 和 dstM 用于确定哪些寄存器需要被写入
    reg [3:0] dstE;
    reg [3:0] dstM;
    
    always @(*) begin
        case (icode_i)
            RRMOVL: begin
                dstE = rB_i;
                dstM = 4'hF;
            end
            IRMOVL: begin
                dstE = rB_i;
                dstM = 4'hF;
            end
            RMMOVL: begin
                dstE = 4'hF;
                dstM = 4'hF;
            end
            MRMOVL: begin
                dstE = 4'hF;
                dstM = rA_i;
            end
            ALU: begin
                dstE = rB_i;
                dstM = 4'hF;
            end
            CALL: begin
                dstE = 4'h4;  // %rsp
                dstM = 4'hF;
            end
            RET: begin
                dstE = 4'h4;  // %rsp
                dstM = 4'hF;
            end
            PUSHL: begin
                dstE = 4'h4;  // %rsp
                dstM = 4'hF;
            end
            POPL: begin
                dstE = 4'h4;  // %rsp
                dstM = rA_i;
            end
            default: begin
                dstE = 4'hF;
                dstM = 4'hF;
            end
        endcase
    end

    // ==================== 寄存器写回 ====================
    // 在时钟上升沿写回寄存器
    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            // 复位时初始化所有寄存器
            regfile[0]  <= 64'd0;
            regfile[1]  <= 64'd1;
            regfile[2]  <= 64'd2;
            regfile[3]  <= 64'd3;
            regfile[4]  <= 64'd4;
            regfile[5]  <= 64'd5;
            regfile[6]  <= 64'd6;
            regfile[7]  <= 64'd7;
            regfile[8]  <= 64'd8;
            regfile[9]  <= 64'd9;
            regfile[10] <= 64'd10;
            regfile[11] <= 64'd11;
            regfile[12] <= 64'd12;
            regfile[13] <= 64'd13;
            regfile[14] <= 64'd14;
        end else begin
            // 写回 valE 到 dstE
            if (dstE != 4'hF) begin
                // RRMOVL 需要检查条件码
                if (icode_i == RRMOVL) begin
                    if (cnd_i)
                        regfile[dstE] <= valE_i;
                end else begin
                    regfile[dstE] <= valE_i;
                end
            end
            
            // 写回 valM 到 dstM
            if (dstM != 4'hF) begin
                regfile[dstM] <= valM_i;
            end
        end
    end

endmodule
