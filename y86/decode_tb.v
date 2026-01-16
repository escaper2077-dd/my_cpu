`timescale 1ps/1ps

module decode_tb();

    // 信号声明
    reg [3:0] icode_i;
    reg [3:0] rA_i;
    reg [3:0] rB_i;
    wire [63:0] valA_o;
    wire [63:0] valB_o;

    // 实例化被测试模块
    decode decode_inst (
        .icode_i(icode_i),
        .rA_i(rA_i),
        .rB_i(rB_i),
        .valA_o(valA_o),
        .valB_o(valB_o)
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

    // 测试激励
    initial begin
        $display("========== Decode Stage Testbench ==========");
        
        // 测试用例1: NOP指令 (无需读取寄存器)
        $display("\n[Test 1] NOP instruction");
        icode_i = NOP;
        rA_i = 4'hF;
        rB_i = 4'hF;
        #10;
        $display("icode=%h, rA=%h, rB=%h => valA=%h, valB=%h", icode_i, rA_i, rB_i, valA_o, valB_o);
        
        // 测试用例2: RRMOVL指令 (读取rA_i和rB_i)
        $display("\n[Test 2] RRMOVL instruction (reads rA=1, rB=3)");
        icode_i = RRMOVL;
        rA_i = 4'h1;
        rB_i = 4'h3;
        #10;
        $display("icode=%h, rA=%h, rB=%h => valA=%h, valB=%h", icode_i, rA_i, rB_i, valA_o, valB_o);
        
        // 测试用例3: ALU指令 (读取rA_i和rB_i - ALU有两个寄存器操作数)
        $display("\n[Test 3] ALU instruction (ADDL: rA=2, rB=3)");
        icode_i = ALU;
        rA_i = 4'h2;
        rB_i = 4'h3;
        #10;
        $display("icode=%h, rA=%h, rB=%h => valA=%h (regfile[2]=2), valB=%h (regfile[3]=3)", icode_i, rA_i, rB_i, valA_o, valB_o);
        
        // 测试用例4: PUSHL指令 (读取rA_i和%rsp)
        $display("\n[Test 4] PUSHL instruction (reads rA=5, %%rsp=4)");
        icode_i = PUSHL;
        rA_i = 4'h5;
        rB_i = 4'hF;
        #10;
        $display("icode=%h, rA=%h, rB=%h => valA=%h, valB=%h", icode_i, rA_i, rB_i, valA_o, valB_o);
        
        // 测试用例5: CALL指令 (读取%rsp)
        $display("\n[Test 5] CALL instruction (reads %%rsp=4)");
        icode_i = CALL;
        rA_i = 4'hF;
        rB_i = 4'hF;
        #10;
        $display("icode=%h, rA=%h, rB=%h => valA=%h, valB=%h", icode_i, rA_i, rB_i, valA_o, valB_o);
        
        // 测试用例6: RET指令 (读取%rsp)
        $display("\n[Test 6] RET instruction (reads %%rsp=4)");
        icode_i = RET;
        rA_i = 4'hF;
        rB_i = 4'hF;
        #10;
        $display("icode=%h, rA=%h, rB=%h => valA=%h, valB=%h", icode_i, rA_i, rB_i, valA_o, valB_o);
        
        // 测试用例7: POPL指令 (读取%rsp)
        $display("\n[Test 7] POPL instruction (reads %%rsp=4)");
        icode_i = POPL;
        rA_i = 4'hF;
        rB_i = 4'hF;
        #10;
        $display("icode=%h, rA=%h, rB=%h => valA=%h, valB=%h", icode_i, rA_i, rB_i, valA_o, valB_o);
        
        // 测试用例8: 读取高编号寄存器
        $display("\n[Test 8] RRMOVL with high register numbers");
        icode_i = RRMOVL;
        rA_i = 4'hA;  // %r10
        rB_i = 4'hE;  // %r14
        #10;
        $display("icode=%h, rA=%h, rB=%h => valA=%h, valB=%h", icode_i, rA_i, rB_i, valA_o, valB_o);
        
        $display("\n========== Test Complete ==========");
        $finish;
    end

endmodule
