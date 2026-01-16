`timescale 1ps/1ps

module cpu_tb();

    // 信号声明
    reg [63:0] PC_i;
    
    // Fetch输出
    wire [3:0] icode_o;
    wire [3:0] ifun_o;
    wire [3:0] rA_o;
    wire [3:0] rB_o;
    wire [63:0] valC_o;
    wire [63:0] valP_o;
    wire instr_valid_o;
    wire imem_error_o;
    
    // Decode输出
    wire [63:0] valA_decode;
    wire [63:0] valB_decode;

    // 实例化被测试模块
    fetch fetch_inst (
        .PC_i(PC_i),
        .icode_o(icode_o),
        .ifun_o(ifun_o),
        .rA_o(rA_o),
        .rB_o(rB_o),
        .valC_o(valC_o),
        .valP_o(valP_o),
        .instr_valid_o(instr_valid_o),
        .imem_error_o(imem_error_o)
    );
    
    decode decode_inst (
        .icode_i(icode_o),
        .rA_i(rA_o),
        .rB_i(rB_o),
        .valA_o(valA_decode),
        .valB_o(valB_decode)
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
        $display("========== CPU Fetch & Decode Testbench ==========");
        
        // 初始化指令内存
        // 测试用例1: NOP指令 (icode=0x0, ifun=0x0) - 1字节
        fetch_inst.instr_mem[0] = 8'h00;
        
        // 测试用例2: HALT指令 (icode=0x1, ifun=0x0) - 1字节
        fetch_inst.instr_mem[1] = 8'h10;
        
        // 测试用例3: RRMOVQ指令 (icode=0x2, ifun=0x0, rA=3, rB=4) - 2字节
        fetch_inst.instr_mem[2] = 8'h20;      // icode=2, ifun=0
        fetch_inst.instr_mem[3] = 8'h34;      // rA=3, rB=4
        
        // 测试用例4: IRMOVQ指令 (icode=0x3, ifun=0x0, rA=0xF, rB=0xd=%r13, valC=0x0123456789ABCDEF)
        fetch_inst.instr_mem[4] = 8'h30;      // icode=3, ifun=0
        fetch_inst.instr_mem[5] = 8'hFd;      // rA=F, rB=d (%r13)
        fetch_inst.instr_mem[6] = 8'hEF;      // valC byte 0
        fetch_inst.instr_mem[7] = 8'hCD;      // valC byte 1
        fetch_inst.instr_mem[8] = 8'hAB;      // valC byte 2
        fetch_inst.instr_mem[9] = 8'h89;      // valC byte 3
        fetch_inst.instr_mem[10] = 8'h67;     // valC byte 4
        fetch_inst.instr_mem[11] = 8'h45;     // valC byte 5
        fetch_inst.instr_mem[12] = 8'h23;     // valC byte 6
        fetch_inst.instr_mem[13] = 8'h01;     // valC byte 7
        
        // 测试用例5: ADDL指令 (ALU操作)
        fetch_inst.instr_mem[14] = 8'h60;     // icode=6 (ALU), ifun=0 (ADDL)
        fetch_inst.instr_mem[15] = 8'h23;     // rA=2, rB=3
        
        // 测试用例5b-5d: 其他ALU操作
        fetch_inst.instr_mem[28] = 8'h61;     // icode=6 (ALU), ifun=1 (SUBL)
        fetch_inst.instr_mem[29] = 8'h23;     // rA=2, rB=3
        
        fetch_inst.instr_mem[30] = 8'h62;     // icode=6 (ALU), ifun=2 (ANDL)
        fetch_inst.instr_mem[31] = 8'h23;     // rA=2, rB=3
        
        fetch_inst.instr_mem[32] = 8'h63;     // icode=6 (ALU), ifun=3 (XORL)
        fetch_inst.instr_mem[33] = 8'h23;     // rA=2, rB=3
        
        // 测试用例6: CMOVLE指令 (条件移动)
        fetch_inst.instr_mem[34] = 8'h21;     // icode=2, ifun=1 (CMOVLE)
        fetch_inst.instr_mem[35] = 8'h45;     // rA=4, rB=5
        
        // 测试用例6b-6e: 其他条件移动
        fetch_inst.instr_mem[36] = 8'h22;     // icode=2, ifun=2 (CMOVL)
        fetch_inst.instr_mem[37] = 8'h45;     // rA=4, rB=5
        
        fetch_inst.instr_mem[38] = 8'h23;     // icode=2, ifun=3 (CMOVE)
        fetch_inst.instr_mem[39] = 8'h45;     // rA=4, rB=5
        
        fetch_inst.instr_mem[40] = 8'h24;     // icode=2, ifun=4 (CMOVNE)
        fetch_inst.instr_mem[41] = 8'h45;     // rA=4, rB=5
        
        fetch_inst.instr_mem[42] = 8'h25;     // icode=2, ifun=5 (CMOVGE)
        fetch_inst.instr_mem[43] = 8'h45;     // rA=4, rB=5
        
        fetch_inst.instr_mem[44] = 8'h26;     // icode=2, ifun=6 (CMOVG)
        fetch_inst.instr_mem[45] = 8'h45;     // rA=4, rB=5
        
        // 测试用例7: JMP指令 (JXX操作)
        fetch_inst.instr_mem[46] = 8'h70;     // icode=7 (JXX), ifun=0 (JMP)
        fetch_inst.instr_mem[47] = 8'h00;     // valC byte 0
        fetch_inst.instr_mem[48] = 8'h20;     // valC byte 1
        fetch_inst.instr_mem[49] = 8'h00;
        fetch_inst.instr_mem[50] = 8'h00;
        fetch_inst.instr_mem[51] = 8'h00;
        fetch_inst.instr_mem[52] = 8'h00;
        fetch_inst.instr_mem[53] = 8'h00;
        fetch_inst.instr_mem[54] = 8'h00;
        
        // 测试用例7b-7h: 其他JXX操作
        fetch_inst.instr_mem[55] = 8'h71;     // icode=7 (JXX), ifun=1 (JLE)
        fetch_inst.instr_mem[56] = 8'h00;     // valC bytes
        fetch_inst.instr_mem[57] = 8'h20;
        fetch_inst.instr_mem[58] = 8'h00;
        fetch_inst.instr_mem[59] = 8'h00;
        fetch_inst.instr_mem[60] = 8'h00;
        fetch_inst.instr_mem[61] = 8'h00;
        fetch_inst.instr_mem[62] = 8'h00;
        fetch_inst.instr_mem[63] = 8'h00;
        
        fetch_inst.instr_mem[64] = 8'h72;     // icode=7 (JXX), ifun=2 (JL)
        fetch_inst.instr_mem[65] = 8'h00;
        fetch_inst.instr_mem[66] = 8'h30;
        
        fetch_inst.instr_mem[67] = 8'h73;     // icode=7 (JXX), ifun=3 (JE)
        fetch_inst.instr_mem[68] = 8'h00;
        fetch_inst.instr_mem[69] = 8'h40;
        
        fetch_inst.instr_mem[70] = 8'h74;     // icode=7 (JXX), ifun=4 (JNE)
        fetch_inst.instr_mem[71] = 8'h00;
        fetch_inst.instr_mem[72] = 8'h50;
        
        fetch_inst.instr_mem[73] = 8'h75;     // icode=7 (JXX), ifun=5 (JGE)
        fetch_inst.instr_mem[74] = 8'h00;
        fetch_inst.instr_mem[75] = 8'h60;
        
        fetch_inst.instr_mem[76] = 8'h76;     // icode=7 (JXX), ifun=6 (JG)
        fetch_inst.instr_mem[77] = 8'h00;
        fetch_inst.instr_mem[78] = 8'h70;
        
        // 测试用例8: PUSHL %rax指令 (PUSHL)
        fetch_inst.instr_mem[79] = 8'hA0;     // icode=A (PUSHL), ifun=0
        fetch_inst.instr_mem[80] = 8'h0F;     // rA=0, rB=F
        
        // 测试用例9: CALL指令
        fetch_inst.instr_mem[81] = 8'h80;     // icode=8 (CALL), ifun=0
        fetch_inst.instr_mem[82] = 8'h00;     // 寄存器字节
        fetch_inst.instr_mem[83] = 8'h00;     // valC byte 0
        fetch_inst.instr_mem[84] = 8'h10;     // valC byte 1
        fetch_inst.instr_mem[85] = 8'h00;
        fetch_inst.instr_mem[86] = 8'h00;
        fetch_inst.instr_mem[87] = 8'h00;
        fetch_inst.instr_mem[88] = 8'h00;
        fetch_inst.instr_mem[89] = 8'h00;
        fetch_inst.instr_mem[90] = 8'h00;
        
        // Test 1: NOP
        $display("\n[Test 1] NOP at PC=0");
        PC_i = 64'd0;
        #10;
        $display("icode=%h, ifun=%h, valid=%b => valA=%h, valB=%h", 
                 icode_o, ifun_o, instr_valid_o, valA_decode, valB_decode);
        
        // Test 2: HALT
        $display("\n[Test 2] HALT at PC=1");
        PC_i = 64'd1;
        #10;
        $display("icode=%h, ifun=%h, valid=%b => valA=%h, valB=%h", 
                 icode_o, ifun_o, instr_valid_o, valA_decode, valB_decode);
        
        // Test 3: RRMOVL %rbx, %rsp
        $display("\n[Test 3] RRMOVL %%rbx, %%rsp at PC=2 (rA=3, rB=4)");
        PC_i = 64'd2;
        #10;
        $display("icode=%h, rA=%h, rB=%h => valA=%h (should be 3), valB=%h (should be 4)", 
                 icode_o, rA_o, rB_o, valA_decode, valB_decode);
        
        // Test 4: IRMOVL
        $display("\n[Test 4] IRMOVL $0x0123456789ABCDEF, %%r13 at PC=4");
        PC_i = 64'd4;
        #10;
        $display("icode=%h, rB=%h, valC=%h, valP=%h (10 bytes: 1+1+8)", icode_o, rB_o, valC_o, valP_o);
        
        // Test 5: ADDL
        $display("\n[Test 5] ADDL (icode=6, ifun=0) at PC=14");
        PC_i = 64'd14;
        #10;
        $display("icode=%h, ifun=%h, rA=%h, rB=%h => valA=%h, valB=%h", 
                 icode_o, ifun_o, rA_o, rB_o, valA_decode, valB_decode);
        
        // Test 5b-5d: ALU operations
        $display("\n[Test 5b] SUBL (icode=6, ifun=1) at PC=28");
        PC_i = 64'd28;
        #10;
        $display("icode=%h, ifun=%h, rA=%h, rB=%h => valA=%h, valB=%h", 
                 icode_o, ifun_o, rA_o, rB_o, valA_decode, valB_decode);
        
        $display("\n[Test 5c] ANDL (icode=6, ifun=2) at PC=30");
        PC_i = 64'd30;
        #10;
        $display("icode=%h, ifun=%h, rA=%h, rB=%h => valA=%h, valB=%h", 
                 icode_o, ifun_o, rA_o, rB_o, valA_decode, valB_decode);
        
        $display("\n[Test 5d] XORL (icode=6, ifun=3) at PC=32");
        PC_i = 64'd32;
        #10;
        $display("icode=%h, ifun=%h, rA=%h, rB=%h => valA=%h, valB=%h", 
                 icode_o, ifun_o, rA_o, rB_o, valA_decode, valB_decode);
        
        // Test 6: Conditional moves (RRMOVL variants)
        $display("\n[Test 6] CMOVLE (icode=2, ifun=1) at PC=34");
        PC_i = 64'd34;
        #10;
        $display("icode=%h, ifun=%h, rA=%h, rB=%h => valA=%h, valB=%h", 
                 icode_o, ifun_o, rA_o, rB_o, valA_decode, valB_decode);
        
        $display("\n[Test 6b] CMOVL (icode=2, ifun=2) at PC=36");
        PC_i = 64'd36;
        #10;
        $display("icode=%h, ifun=%h, rA=%h, rB=%h => valA=%h, valB=%h", 
                 icode_o, ifun_o, rA_o, rB_o, valA_decode, valB_decode);
        
        $display("\n[Test 6c] CMOVE (icode=2, ifun=3) at PC=38");
        PC_i = 64'd38;
        #10;
        $display("icode=%h, ifun=%h, rA=%h, rB=%h => valA=%h, valB=%h", 
                 icode_o, ifun_o, rA_o, rB_o, valA_decode, valB_decode);
        
        $display("\n[Test 6d] CMOVNE (icode=2, ifun=4) at PC=40");
        PC_i = 64'd40;
        #10;
        $display("icode=%h, ifun=%h, rA=%h, rB=%h => valA=%h, valB=%h", 
                 icode_o, ifun_o, rA_o, rB_o, valA_decode, valB_decode);
        
        $display("\n[Test 6e] CMOVGE (icode=2, ifun=5) at PC=42");
        PC_i = 64'd42;
        #10;
        $display("icode=%h, ifun=%h, rA=%h, rB=%h => valA=%h, valB=%h", 
                 icode_o, ifun_o, rA_o, rB_o, valA_decode, valB_decode);
        
        $display("\n[Test 6f] CMOVG (icode=2, ifun=6) at PC=44");
        PC_i = 64'd44;
        #10;
        $display("icode=%h, ifun=%h, rA=%h, rB=%h => valA=%h, valB=%h", 
                 icode_o, ifun_o, rA_o, rB_o, valA_decode, valB_decode);
        
        // Test 7: JXX operations
        $display("\n[Test 7] JMP (icode=7, ifun=0) at PC=46");
        PC_i = 64'd46;
        #10;
        $display("icode=%h, ifun=%h, valC=%h, valP=%h", 
                 icode_o, ifun_o, valC_o, valP_o);
        
        $display("\n[Test 7b] JLE (icode=7, ifun=1) at PC=55");
        PC_i = 64'd55;
        #10;
        $display("icode=%h, ifun=%h, valC=%h, valP=%h", 
                 icode_o, ifun_o, valC_o, valP_o);
        
        $display("\n[Test 7c] JL (icode=7, ifun=2) at PC=64");
        PC_i = 64'd64;
        #10;
        $display("icode=%h, ifun=%h, valC=%h, valP=%h", 
                 icode_o, ifun_o, valC_o, valP_o);
        
        $display("\n[Test 7d] JE (icode=7, ifun=3) at PC=67");
        PC_i = 64'd67;
        #10;
        $display("icode=%h, ifun=%h, valC=%h, valP=%h", 
                 icode_o, ifun_o, valC_o, valP_o);
        
        $display("\n[Test 7e] JNE (icode=7, ifun=4) at PC=70");
        PC_i = 64'd70;
        #10;
        $display("icode=%h, ifun=%h, valC=%h, valP=%h", 
                 icode_o, ifun_o, valC_o, valP_o);
        
        $display("\n[Test 7f] JGE (icode=7, ifun=5) at PC=73");
        PC_i = 64'd73;
        #10;
        $display("icode=%h, ifun=%h, valC=%h, valP=%h", 
                 icode_o, ifun_o, valC_o, valP_o);
        
        $display("\n[Test 7g] JG (icode=7, ifun=6) at PC=76");
        PC_i = 64'd76;
        #10;
        $display("icode=%h, ifun=%h, valC=%h, valP=%h", 
                 icode_o, ifun_o, valC_o, valP_o);
        
        // Test 8: PUSHL
        $display("\n[Test 8] PUSHL %%rax (icode=A, ifun=0) at PC=79");
        PC_i = 64'd79;
        #10;
        $display("icode=%h, ifun=%h, rA=%h => valA=%h", 
                 icode_o, ifun_o, rA_o, valA_decode);
        
        // Test 9: CALL
        $display("\n[Test 9] CALL (icode=8, ifun=0) at PC=81");
        PC_i = 64'd81;
        #10;
        $display("icode=%h, ifun=%h, valC=%h, valP=%h", 
                 icode_o, ifun_o, valC_o, valP_o);
        
        $display("\n========== Test Complete ==========");
        $finish;
    end

endmodule
