`timescale 1ps/1ps

module execute_tb();

    // 时钟和复位信号
    reg clk_i;
    reg rst_n_i;
    
    // 输入信号
    reg [3:0] icode_i;
    reg [3:0] ifun_i;
    reg [63:0] valA_i;
    reg [63:0] valB_i;
    reg [63:0] valC_i;
    
    // 输出信号
    wire [63:0] valE_o;
    wire Cnd_o;
    
    // 实例化Execute模块
    execute execute_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .icode_i(icode_i),
        .ifun_i(ifun_i),
        .valA_i(valA_i),
        .valB_i(valB_i),
        .valC_i(valC_i),
        .valE_o(valE_o),
        .Cnd_o(Cnd_o)
    );
    
    // 指令码定义
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
    
    // RRMOVL func码定义
    localparam RRMOV_RRMOVL = 4'h0;  // 无条件移动
    localparam RRMOV_CMOVLE = 4'h1;  // 小于等于时移动
    localparam RRMOV_CMOVL  = 4'h2;  // 小于时移动
    localparam RRMOV_CMOVE  = 4'h3;  // 等于时移动
    localparam RRMOV_CMOVNE = 4'h4;  // 不等于时移动
    localparam RRMOV_CMOVGE = 4'h5;  // 大于等于时移动
    localparam RRMOV_CMOVG  = 4'h6;  // 大于时移动
    
    // ALU func码定义
    localparam ALU_ADDL = 4'h0;
    localparam ALU_SUBL = 4'h1;
    localparam ALU_ANDL = 4'h2;
    localparam ALU_XORL = 4'h3;
    
    // JXX func码定义
    localparam JXX_JMP  = 4'h0;
    localparam JXX_JLE  = 4'h1;
    localparam JXX_JL   = 4'h2;
    localparam JXX_JE   = 4'h3;
    localparam JXX_JNE  = 4'h4;
    localparam JXX_JGE  = 4'h5;
    localparam JXX_JG   = 4'h6;
    
    initial begin
        clk_i = 1'b0;
        forever #5 clk_i = ~clk_i;
    end
    
    initial begin
        // 初始化
        rst_n_i = 1'b0;
        icode_i = 4'h0;
        ifun_i = 4'h0;
        valA_i = 64'h0;
        valB_i = 64'h0;
        valC_i = 64'h0;
        
        #100;
        rst_n_i = 1'b1;
        
        $display("================== Execute Stage Test Cases ==================");
        
        // ========== Test 1: ALU ADDL ==========
        $display("\n========== Test 1: ALU ADDL (3 + 5 = 8) ==========");
        icode_i = ALU;
        ifun_i = ALU_ADDL;
        valA_i = 64'h3;
        valB_i = 64'h5;
        #10;
        $display("ADDL 0x3 + 0x5 = 0x%016h (expected 0x8), Condition Code: ZF=%d, SF=%d, OF=%d", 
                 valE_o, execute_inst.ZF, execute_inst.SF, execute_inst.OF);
        
        // ========== Test 2: ALU SUBL (10 - 3 = 7) ==========
        $display("\n========== Test 2: ALU SUBL (10 - 3 = 7) ==========");
        icode_i = ALU;
        ifun_i = ALU_SUBL;
        valA_i = 64'hA;
        valB_i = 64'h3;
        #10;
        $display("SUBL 0xA - 0x3 = 0x%016h (expected 0x7), Condition Code: ZF=%d, SF=%d, OF=%d", 
                 valE_o, execute_inst.ZF, execute_inst.SF, execute_inst.OF);
        
        // ========== Test 3: ALU ANDL (0xFF & 0x0F = 0x0F) ==========
        $display("\n========== Test 3: ALU ANDL (0xFF & 0x0F = 0x0F) ==========");
        icode_i = ALU;
        ifun_i = ALU_ANDL;
        valA_i = 64'hFF;
        valB_i = 64'h0F;
        #10;
        $display("ANDL 0xFF & 0x0F = 0x%016h (expected 0xF), Condition Code: ZF=%d, SF=%d, OF=%d", 
                 valE_o, execute_inst.ZF, execute_inst.SF, execute_inst.OF);
        
        // ========== Test 4: ALU XORL (0xAA ^ 0x55 = 0xFF) ==========
        $display("\n========== Test 4: ALU XORL (0xAA ^ 0x55 = 0xFF) ==========");
        icode_i = ALU;
        ifun_i = ALU_XORL;
        valA_i = 64'hAA;
        valB_i = 64'h55;
        #10;
        $display("XORL 0xAA ^ 0x55 = 0x%016h (expected 0xFF), Condition Code: ZF=%d, SF=%d, OF=%d", 
                 valE_o, execute_inst.ZF, execute_inst.SF, execute_inst.OF);
        
        // ========== Test 5: ALU ADDL with zero result (5 + (-5) = 0) ==========
        $display("\n========== Test 5: ALU ADDL Zero Result (5 + (-5) = 0) ==========");
        icode_i = ALU;
        ifun_i = ALU_ADDL;
        valA_i = 64'h5;
        valB_i = 64'hFFFFFFFFFFFFFFFB;  // -5
        #10;
        $display("ADDL 0x5 + 0xFFFFFFFFFFFFFFFB = 0x%016h (expected 0x0), Condition Code: ZF=%d, SF=%d, OF=%d", 
                 valE_o, execute_inst.ZF, execute_inst.SF, execute_inst.OF);
        
        // ========== Test 6: ALU ADDL with negative result ==========
        $display("\n========== Test 6: ALU ADDL Negative Result (-1 + (-1) = -2) ==========");
        icode_i = ALU;
        ifun_i = ALU_ADDL;
        valA_i = 64'hFFFFFFFFFFFFFFFF;  // -1
        valB_i = 64'hFFFFFFFFFFFFFFFF;  // -1
        #10;
        $display("ADDL 0xFFFFFFFFFFFFFFFF + 0xFFFFFFFFFFFFFFFF = 0x%016h (expected 0xFFFFFFFFFFFFFFFE), Condition Code: ZF=%d, SF=%d, OF=%d", 
                 valE_o, execute_inst.ZF, execute_inst.SF, execute_inst.OF);
        
        // ========== Test 7: RRMOVL (条件移动，无条件) ==========
        $display("\n========== Test 7: RRMOVL (Unconditional Move) ==========");
        icode_i = RRMOVL;
        ifun_i = RRMOV_RRMOVL;
        valA_i = 64'h0123456789ABCDEF;
        valB_i = 64'h0;
        #10;
        $display("RRMOVL valA=0x%016h => valE=0x%016h, Cnd=%d (should be 1)", 
                 valA_i, valE_o, Cnd_o);
        
        // ========== Test 8: IRMOVL (立即数加载) ==========
        $display("\n========== Test 8: IRMOVL (Immediate Load) ==========");
        icode_i = IRMOVL;
        ifun_i = 4'h0;
        valC_i = 64'h1234567890ABCDEF;
        #10;
        $display("IRMOVL valC=0x%016h => valE=0x%016h", valC_i, valE_o);
        
        // ========== Test 9: RMMOVL (寄存器存储到内存) ==========
        $display("\n========== Test 9: RMMOVL (Store Register to Memory) ==========");
        icode_i = RMMOVL;
        ifun_i = 4'h0;
        valB_i = 64'h1000;  // 基址
        valC_i = 64'h100;   // 偏移
        #10;
        $display("RMMOVL Addr = valB(0x%016h) + valC(0x%016h) = 0x%016h", 
                 valB_i, valC_i, valE_o);
        
        // ========== Test 10: MRMOVL (从内存读到寄存器) ==========
        $display("\n========== Test 10: MRMOVL (Load Register from Memory) ==========");
        icode_i = MRMOVL;
        ifun_i = 4'h0;
        valB_i = 64'h2000;
        valC_i = 64'h200;
        #10;
        $display("MRMOVL Addr = valB(0x%016h) + valC(0x%016h) = 0x%016h", 
                 valB_i, valC_i, valE_o);
        
        // ========== Test 11: PUSHL (栈指针减8) ==========
        $display("\n========== Test 11: PUSHL (Push to Stack) ==========");
        icode_i = PUSHL;
        ifun_i = 4'h0;
        valB_i = 64'h8000;  // %rsp = 0x8000
        #10;
        $display("PUSHL RSP = 0x%016h => New RSP = 0x%016h", valB_i, valE_o);
        
        // ========== Test 12: POPL (栈指针加8) ==========
        $display("\n========== Test 12: POPL (Pop from Stack) ==========");
        icode_i = POPL;
        ifun_i = 4'h0;
        valB_i = 64'h7FF8;  // %rsp = 0x7FF8
        #10;
        $display("POPL RSP = 0x%016h => New RSP = 0x%016h", valB_i, valE_o);
        
        // ========== Test 13: CALL (栈指针减8) ==========
        $display("\n========== Test 13: CALL (Function Call) ==========");
        icode_i = CALL;
        ifun_i = 4'h0;
        valB_i = 64'h8000;
        #10;
        $display("CALL RSP = 0x%016h => New RSP = 0x%016h", valB_i, valE_o);
        
        // ========== Test 14: RET (栈指针加8) ==========
        $display("\n========== Test 14: RET (Return from Function) ==========");
        icode_i = RET;
        ifun_i = 4'h0;
        valB_i = 64'h7FF8;
        #10;
        $display("RET RSP = 0x%016h => New RSP = 0x%016h", valB_i, valE_o);
        
        // ========== Test 15: Conditional Jump - JMP (always jump) ==========
        $display("\n========== Test 15: JMP (Always Jump) ==========");
        icode_i = JXX;
        ifun_i = JXX_JMP;
        #10;
        $display("JMP => Condition = %d (expected 1)", Cnd_o);
        
        // ========== Test 16: Conditional Jump - JE (Zero Flag = 1) ==========
        $display("\n========== Test 16: JE (Jump if Equal) - ZF=1 ==========");
        // 先执行减法得到0，设置ZF=1
        icode_i = ALU;
        ifun_i = ALU_SUBL;
        valA_i = 64'h5;
        valB_i = 64'h5;
        #10;
        // 然后执行JE
        icode_i = JXX;
        ifun_i = JXX_JE;
        #10;
        $display("JE (ZF=%d) => Condition = %d (expected 1)", execute_inst.ZF, Cnd_o);
        
        // ========== Test 17: Conditional Jump - JE (Zero Flag = 0) ==========
        $display("\n========== Test 17: JE (Jump if Equal) - ZF=0 ==========");
        // 先执行减法得到非零，设置ZF=0
        icode_i = ALU;
        ifun_i = ALU_SUBL;
        valA_i = 64'h5;
        valB_i = 64'h3;
        #10;
        // 然后执行JE
        icode_i = JXX;
        ifun_i = JXX_JE;
        #10;
        $display("JE (ZF=%d) => Condition = %d (expected 0)", execute_inst.ZF, Cnd_o);
        
        // ========== Test 18: Conditional Jump - JL (Sign Flag = 1) ==========
        $display("\n========== Test 18: JL (Jump if Less) - SF=1 ==========");
        // 先执行减法得到负数，设置SF=1
        icode_i = ALU;
        ifun_i = ALU_SUBL;
        valA_i = 64'h3;
        valB_i = 64'h5;
        #10;
        // 然后执行JL
        icode_i = JXX;
        ifun_i = JXX_JL;
        #10;
        $display("JL (SF=%d) => Condition = %d (expected 1)", execute_inst.SF, Cnd_o);
        
        // ========== Test 19: Conditional Jump - JG (SF=0 && ZF=0) ==========
        $display("\n========== Test 19: JG (Jump if Greater) - SF=0, ZF=0 ==========");
        // 先执行减法得到正数，设置SF=0, ZF=0
        icode_i = ALU;
        ifun_i = ALU_SUBL;
        valA_i = 64'h5;
        valB_i = 64'h3;
        #10;
        // 然后执行JG
        icode_i = JXX;
        ifun_i = JXX_JG;
        #10;
        $display("JG (SF=%d, ZF=%d) => Condition = %d (expected 1)", 
                 execute_inst.SF, execute_inst.ZF, Cnd_o);
        
        // ========== Test 20: CMOVE (条件移动 - 等于时移动) ==========
        $display("\n========== Test 20: CMOVE (Conditional Move if Equal) - ZF=1 ==========");
        // 先执行减法得到0，设置ZF=1
        icode_i = ALU;
        ifun_i = ALU_SUBL;
        valA_i = 64'h5;
        valB_i = 64'h5;
        #10;
        // 然后执行CMOVE
        icode_i = RRMOVL;
        ifun_i = RRMOV_CMOVE;
        valA_i = 64'h0FEDCBA987654321;
        #10;
        $display("CMOVE (ZF=%d) => valE=0x%016h, Cnd=%d (expected 1)", 
                 execute_inst.ZF, valE_o, Cnd_o);
        
        // ========== Test 21: CMOVL (条件移动 - 小于时移动) ==========
        $display("\n========== Test 21: CMOVL (Conditional Move if Less) - SF=1 ==========");
        // 先执行减法得到负数，设置SF=1
        icode_i = ALU;
        ifun_i = ALU_SUBL;
        valA_i = 64'h3;
        valB_i = 64'h5;
        #10;
        // 然后执行CMOVL
        icode_i = RRMOVL;
        ifun_i = RRMOV_CMOVL;
        valA_i = 64'h1111111111111111;
        #10;
        $display("CMOVL (SF=%d) => valE=0x%016h, Cnd=%d (expected 1)", 
                 execute_inst.SF, valE_o, Cnd_o);
        
        // ========== Test 22: CMOVNE (条件移动 - 不等于时移动) ==========
        $display("\n========== Test 22: CMOVNE (Conditional Move if Not Equal) - ZF=0 ==========");
        // SF已经是1，ZF也是0（从之前的负数结果）
        icode_i = RRMOVL;
        ifun_i = RRMOV_CMOVNE;
        valA_i = 64'h2222222222222222;
        #10;
        $display("CMOVNE (ZF=%d) => valE=0x%016h, Cnd=%d (expected 1)", 
                 execute_inst.ZF, valE_o, Cnd_o);
        
        $display("\n================== Test Complete ==================");
        #10;
        $finish;
    end

endmodule
