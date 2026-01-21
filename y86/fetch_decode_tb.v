`timescale 1ps/1ps

module fetch_decode_tb();

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

    initial begin
        // ==================== 指令初始化 ====================
        // 按PC顺序排列，完整编码所有指令
        
        // PC=0: NOP (1字节)
        fetch_inst.instr_mem[0] = 8'h00;
        
        // PC=1: HALT (1字节)
        fetch_inst.instr_mem[1] = 8'h10;
        
        // PC=2: RRMOVL (2字节) - Test 2_0: RRMOVL %rax, %rcx
        fetch_inst.instr_mem[2] = 8'h20;
        fetch_inst.instr_mem[3] = 8'h34;     // rA=3(%rbx), rB=4(%rcx)
        
        // PC=4: IRMOVL (10字节) - Test 3
        fetch_inst.instr_mem[4] = 8'h30;
        fetch_inst.instr_mem[5] = 8'hFd;
        fetch_inst.instr_mem[6] = 8'hef;
        fetch_inst.instr_mem[7] = 8'hcd;
        fetch_inst.instr_mem[8] = 8'hab;
        fetch_inst.instr_mem[9] = 8'h89;
        fetch_inst.instr_mem[10] = 8'h67;
        fetch_inst.instr_mem[11] = 8'h45;
        fetch_inst.instr_mem[12] = 8'h23;
        fetch_inst.instr_mem[13] = 8'h01;
        
        // PC=14: RMMOVL (10字节) - Test 4: RMMOVL %rax, 0x100(%rbx)
        fetch_inst.instr_mem[14] = 8'h40;
        fetch_inst.instr_mem[15] = 8'h03;
        fetch_inst.instr_mem[16] = 8'h00;
        fetch_inst.instr_mem[17] = 8'h01;
        fetch_inst.instr_mem[18] = 8'h00;
        fetch_inst.instr_mem[19] = 8'h00;
        fetch_inst.instr_mem[20] = 8'h00;
        fetch_inst.instr_mem[21] = 8'h00;
        fetch_inst.instr_mem[22] = 8'h00;
        fetch_inst.instr_mem[23] = 8'h00;
        
        // PC=24: MRMOVL (10字节) - Test 5: MRMOVL 0x200(%rcx), %rdx
        fetch_inst.instr_mem[24] = 8'h50;
        fetch_inst.instr_mem[25] = 8'h12;
        fetch_inst.instr_mem[26] = 8'h00;
        fetch_inst.instr_mem[27] = 8'h02;
        fetch_inst.instr_mem[28] = 8'h00;
        fetch_inst.instr_mem[29] = 8'h00;
        fetch_inst.instr_mem[30] = 8'h00;
        fetch_inst.instr_mem[31] = 8'h00;
        fetch_inst.instr_mem[32] = 8'h00;
        fetch_inst.instr_mem[33] = 8'h00;
        
        // PC=34: ADDL (2字节) - Test 6_0
        fetch_inst.instr_mem[34] = 8'h60;
        fetch_inst.instr_mem[35] = 8'h23;
        
        // PC=36: SUBL (2字节) - Test 6_1
        fetch_inst.instr_mem[36] = 8'h61;
        fetch_inst.instr_mem[37] = 8'h23;
        
        // PC=38: ANDL (2字节) - Test 6_2
        fetch_inst.instr_mem[38] = 8'h62;
        fetch_inst.instr_mem[39] = 8'h23;
        
        // PC=40: XORL (2字节) - Test 6_3
        fetch_inst.instr_mem[40] = 8'h63;
        fetch_inst.instr_mem[41] = 8'h23;
        
        // PC=42: CMOVLE (2字节) - Test 2_1
        fetch_inst.instr_mem[42] = 8'h21;
        fetch_inst.instr_mem[43] = 8'h34;
        
        // PC=44: CMOVL (2字节) - Test 2_2
        fetch_inst.instr_mem[44] = 8'h22;
        fetch_inst.instr_mem[45] = 8'h34;
        
        // PC=46: CMOVE (2字节) - Test 2_3
        fetch_inst.instr_mem[46] = 8'h23;
        fetch_inst.instr_mem[47] = 8'h34;
        
        // PC=48: CMOVNE (2字节) - Test 2_4
        fetch_inst.instr_mem[48] = 8'h24;
        fetch_inst.instr_mem[49] = 8'h34;
        
        // PC=50: CMOVGE (2字节) - Test 2_5
        fetch_inst.instr_mem[50] = 8'h25;
        fetch_inst.instr_mem[51] = 8'h34;
        
        // PC=52: CMOVG (2字节) - Test 2_6
        fetch_inst.instr_mem[52] = 8'h26;
        fetch_inst.instr_mem[53] = 8'h34;
        
        // PC=54: JMP (9字节) - Test 7_0
        fetch_inst.instr_mem[54] = 8'h70;
        fetch_inst.instr_mem[55] = 8'h00;
        fetch_inst.instr_mem[56] = 8'h20;
        fetch_inst.instr_mem[57] = 8'h00;
        fetch_inst.instr_mem[58] = 8'h00;
        fetch_inst.instr_mem[59] = 8'h00;
        fetch_inst.instr_mem[60] = 8'h00;
        fetch_inst.instr_mem[61] = 8'h00;
        fetch_inst.instr_mem[62] = 8'h00;
        
        // PC=63: JLE (9字节) - Test 7_1
        fetch_inst.instr_mem[63] = 8'h71;
        fetch_inst.instr_mem[64] = 8'h00;
        fetch_inst.instr_mem[65] = 8'h20;
        fetch_inst.instr_mem[66] = 8'h00;
        fetch_inst.instr_mem[67] = 8'h00;
        fetch_inst.instr_mem[68] = 8'h00;
        fetch_inst.instr_mem[69] = 8'h00;
        fetch_inst.instr_mem[70] = 8'h00;
        fetch_inst.instr_mem[71] = 8'h00;
        
        // PC=72: JL (3字节) - Test 7_2
        fetch_inst.instr_mem[72] = 8'h72;
        fetch_inst.instr_mem[73] = 8'h00;
        fetch_inst.instr_mem[74] = 8'h30;
        
        // PC=75: JE (3字节) - Test 7_3
        fetch_inst.instr_mem[75] = 8'h73;
        fetch_inst.instr_mem[76] = 8'h00;
        fetch_inst.instr_mem[77] = 8'h40;
        
        // PC=78: JNE (3字节) - Test 7_4
        fetch_inst.instr_mem[78] = 8'h74;
        fetch_inst.instr_mem[79] = 8'h00;
        fetch_inst.instr_mem[80] = 8'h50;
        
        // PC=81: JGE (3字节) - Test 7_5
        fetch_inst.instr_mem[81] = 8'h75;
        fetch_inst.instr_mem[82] = 8'h00;
        fetch_inst.instr_mem[83] = 8'h60;
        
        // PC=84: JG (3字节) - Test 7_6
        fetch_inst.instr_mem[84] = 8'h76;
        fetch_inst.instr_mem[85] = 8'h00;
        fetch_inst.instr_mem[86] = 8'h70;
        
        // PC=87: CALL (10字节) - Test 8
        fetch_inst.instr_mem[87] = 8'h80;
        fetch_inst.instr_mem[88] = 8'h00;
        fetch_inst.instr_mem[89] = 8'h00;
        fetch_inst.instr_mem[90] = 8'h10;
        fetch_inst.instr_mem[91] = 8'h00;
        fetch_inst.instr_mem[92] = 8'h00;
        fetch_inst.instr_mem[93] = 8'h00;
        fetch_inst.instr_mem[94] = 8'h00;
        fetch_inst.instr_mem[95] = 8'h00;
        fetch_inst.instr_mem[96] = 8'h00;
        
        // PC=97: RET (1字节) - Test 9
        fetch_inst.instr_mem[97] = 8'h90;
        
        // PC=98: POPL (2字节) - Test B: POPL %rbp
        fetch_inst.instr_mem[98] = 8'hB0;   // icode=B, ifun=0
        fetch_inst.instr_mem[99] = 8'h5F;   // rA=5(%rbp), rB=F(→%rsp)
        
        // PC=100: PUSHL (2字节) - Test A: PUSHL %rax
        fetch_inst.instr_mem[100] = 8'hA0;
        fetch_inst.instr_mem[101] = 8'h0F;
        
        // 打印表头
        $display("PC       | icode | ifun | rA | rB | valC             | valP     | valid | error | Operands");
        $display("---------|-------|------|----|----|------------------|----------|-------|-------|------------------");
        
        // Test 0: NOP
        PC_i = 64'd0;
        #10;
        $display("%016h |   %h   |  %h  | %h  | %h  | %016h | %016h |   %d   |   %d   |", 
                 PC_i, icode_o, ifun_o, rA_o, rB_o, valC_o, valP_o, instr_valid_o, imem_error_o);
        
        // Test 1: HALT
        PC_i = 64'd1;
        #10;
        $display("%016h |   %h   |  %h  | %h  | %h  | %016h | %016h |   %d   |   %d   |", 
                 PC_i, icode_o, ifun_o, rA_o, rB_o, valC_o, valP_o, instr_valid_o, imem_error_o);
        
        // ========== RRMOVL系列 (icode=2, ifun=0-6) ==========
        $display("\n===== RRMOVL Conditional Move Series (icode=2, ifun=0-6) =====");
        
        // Test 2_0: RRMOVL (ifun=0)
        PC_i = 64'd2;
        #10;
        $display("%016h |   %h   |  %h  | %h  | %h  | %016h | %016h |   %d   |   %d   | => valA=%016h, valB=%016h", 
                 PC_i, icode_o, ifun_o, rA_o, rB_o, valC_o, valP_o, instr_valid_o, imem_error_o, valA_decode, valB_decode);
        
        // Test 2_1: CMOVLE (ifun=1)
        PC_i = 64'd42;
        #10;
        $display("%016h |   %h   |  %h  | %h  | %h  | %016h | %016h |   %d   |   %d   | => valA=%016h, valB=%016h", 
                 PC_i, icode_o, ifun_o, rA_o, rB_o, valC_o, valP_o, instr_valid_o, imem_error_o, valA_decode, valB_decode);
        
        // Test 2_2: CMOVL (ifun=2)
        PC_i = 64'd44;
        #10;
        $display("%016h |   %h   |  %h  | %h  | %h  | %016h | %016h |   %d   |   %d   | => valA=%016h, valB=%016h", 
                 PC_i, icode_o, ifun_o, rA_o, rB_o, valC_o, valP_o, instr_valid_o, imem_error_o, valA_decode, valB_decode);
        
        // Test 2_3: CMOVE (ifun=3)
        PC_i = 64'd46;
        #10;
        $display("%016h |   %h   |  %h  | %h  | %h  | %016h | %016h |   %d   |   %d   | => valA=%016h, valB=%016h", 
                 PC_i, icode_o, ifun_o, rA_o, rB_o, valC_o, valP_o, instr_valid_o, imem_error_o, valA_decode, valB_decode);
        
        // Test 2_4: CMOVNE (ifun=4)
        PC_i = 64'd48;
        #10;
        $display("%016h |   %h   |  %h  | %h  | %h  | %016h | %016h |   %d   |   %d   | => valA=%016h, valB=%016h", 
                 PC_i, icode_o, ifun_o, rA_o, rB_o, valC_o, valP_o, instr_valid_o, imem_error_o, valA_decode, valB_decode);
        
        // Test 2_5: CMOVGE (ifun=5)
        PC_i = 64'd50;
        #10;
        $display("%016h |   %h   |  %h  | %h  | %h  | %016h | %016h |   %d   |   %d   | => valA=%016h, valB=%016h", 
                 PC_i, icode_o, ifun_o, rA_o, rB_o, valC_o, valP_o, instr_valid_o, imem_error_o, valA_decode, valB_decode);
        
        // Test 2_6: CMOVG (ifun=6)
        PC_i = 64'd52;
        #10;
        $display("%016h |   %h   |  %h  | %h  | %h  | %016h | %016h |   %d   |   %d   | => valA=%016h, valB=%016h", 
                 PC_i, icode_o, ifun_o, rA_o, rB_o, valC_o, valP_o, instr_valid_o, imem_error_o, valA_decode, valB_decode);
        
        // Test 3: IRMOVL
        $display("\n===== IRMOVL (icode=3, ifun=0) =====");
        PC_i = 64'd4;
        #10;
        $display("%016h |   %h   |  %h  | %h  | %h  | %016h | %016h |   %d   |   %d   | => valA=%016h, valB=%016h", 
                 PC_i, icode_o, ifun_o, rA_o, rB_o, valC_o, valP_o, instr_valid_o, imem_error_o, valA_decode, valB_decode);
        
        // Test 4: RMMOVL
        $display("\n===== RMMOVL (icode=4, ifun=0) =====");
        PC_i = 64'd14;
        #10;
        $display("%016h |   %h   |  %h  | %h  | %h  | %016h | %016h |   %d   |   %d   | => valA=%016h, valB=%016h", 
                 PC_i, icode_o, ifun_o, rA_o, rB_o, valC_o, valP_o, instr_valid_o, imem_error_o, valA_decode, valB_decode);
        
        // Test 5: MRMOVL
        $display("\n===== MRMOVL (icode=5, ifun=0) =====");
        PC_i = 64'd24;
        #10;
        $display("%016h |   %h   |  %h  | %h  | %h  | %016h | %016h |   %d   |   %d   | => valA=%016h, valB=%016h", 
                 PC_i, icode_o, ifun_o, rA_o, rB_o, valC_o, valP_o, instr_valid_o, imem_error_o, valA_decode, valB_decode);
        
        // ========== ALU系列 (icode=6, ifun=0-3) ==========
        $display("\n===== ALU Series (icode=6, ifun=0-3) =====");
        
        // Test 6_0: ADDL (ifun=0)
        PC_i = 64'd34;
        #10;
        $display("%016h |   %h   |  %h  | %h  | %h  | %016h | %016h |   %d   |   %d   | => valA=%016h, valB=%016h", 
                 PC_i, icode_o, ifun_o, rA_o, rB_o, valC_o, valP_o, instr_valid_o, imem_error_o, valA_decode, valB_decode);
        
        // Test 6_1: SUBL (ifun=1)
        PC_i = 64'd36;
        #10;
        $display("%016h |   %h   |  %h  | %h  | %h  | %016h | %016h |   %d   |   %d   | => valA=%016h, valB=%016h", 
                 PC_i, icode_o, ifun_o, rA_o, rB_o, valC_o, valP_o, instr_valid_o, imem_error_o, valA_decode, valB_decode);
        
        // Test 6_2: ANDL (ifun=2)
        PC_i = 64'd38;
        #10;
        $display("%016h |   %h   |  %h  | %h  | %h  | %016h | %016h |   %d   |   %d   | => valA=%016h, valB=%016h", 
                 PC_i, icode_o, ifun_o, rA_o, rB_o, valC_o, valP_o, instr_valid_o, imem_error_o, valA_decode, valB_decode);
        
        // Test 6_3: XORL (ifun=3)
        PC_i = 64'd40;
        #10;
        $display("%016h |   %h   |  %h  | %h  | %h  | %016h | %016h |   %d   |   %d   | => valA=%016h, valB=%016h", 
                 PC_i, icode_o, ifun_o, rA_o, rB_o, valC_o, valP_o, instr_valid_o, imem_error_o, valA_decode, valB_decode);
        
        // ========== JXX系列 (icode=7, ifun=0-6) ==========
        $display("\n===== JXX Conditional Jump Series (icode=7, ifun=0-6) =====");
        
        // Test 7_0: JMP (ifun=0)
        PC_i = 64'd54;
        #10;
        $display("%016h |   %h   |  %h  | %h  | %h  | %016h | %016h |   %d   |   %d   |", 
                 PC_i, icode_o, ifun_o, rA_o, rB_o, valC_o, valP_o, instr_valid_o, imem_error_o);
        
        // Test 7_1: JLE (ifun=1)
        PC_i = 64'd63;
        #10;
        $display("%016h |   %h   |  %h  | %h  | %h  | %016h | %016h |   %d   |   %d   |", 
                 PC_i, icode_o, ifun_o, rA_o, rB_o, valC_o, valP_o, instr_valid_o, imem_error_o);
        
        // Test 7_2: JL (ifun=2)
        PC_i = 64'd72;
        #10;
        $display("%016h |   %h   |  %h  | %h  | %h  | %016h | %016h |   %d   |   %d   |", 
                 PC_i, icode_o, ifun_o, rA_o, rB_o, valC_o, valP_o, instr_valid_o, imem_error_o);
        
        // Test 7_3: JE (ifun=3)
        PC_i = 64'd75;
        #10;
        $display("%016h |   %h   |  %h  | %h  | %h  | %016h | %016h |   %d   |   %d   |", 
                 PC_i, icode_o, ifun_o, rA_o, rB_o, valC_o, valP_o, instr_valid_o, imem_error_o);
        
        // Test 7_4: JNE (ifun=4)
        PC_i = 64'd78;
        #10;
        $display("%016h |   %h   |  %h  | %h  | %h  | %016h | %016h |   %d   |   %d   |", 
                 PC_i, icode_o, ifun_o, rA_o, rB_o, valC_o, valP_o, instr_valid_o, imem_error_o);
        
        // Test 7_5: JGE (ifun=5)
        PC_i = 64'd81;
        #10;
        $display("%016h |   %h   |  %h  | %h  | %h  | %016h | %016h |   %d   |   %d   |", 
                 PC_i, icode_o, ifun_o, rA_o, rB_o, valC_o, valP_o, instr_valid_o, imem_error_o);
        
        // Test 7_6: JG (ifun=6)
        PC_i = 64'd84;
        #10;
        $display("%016h |   %h   |  %h  | %h  | %h  | %016h | %016h |   %d   |   %d   |", 
                 PC_i, icode_o, ifun_o, rA_o, rB_o, valC_o, valP_o, instr_valid_o, imem_error_o);
        
        // ========== 其他指令 ==========
        $display("\n===== Other Instructions =====");
        
        // Test 8: CALL
        PC_i = 64'd87;
        #10;
        $display("%016h |   %h   |  %h  | %h  | %h  | %016h | %016h |   %d   |   %d   |", 
                 PC_i, icode_o, ifun_o, rA_o, rB_o, valC_o, valP_o, instr_valid_o, imem_error_o);

        // Test 9: RET
        PC_i = 64'd97;
        #10;
        $display("%016h |   %h   |  %h  | %h  | %h  | %016h | %016h |   %d   |   %d   |", 
                 PC_i, icode_o, ifun_o, rA_o, rB_o, valC_o, valP_o, instr_valid_o, imem_error_o);

        // Test A: PUSHL
        PC_i = 64'd100;
        #10;
        $display("%016h |   %h   |  %h  | %h  | %h  | %016h | %016h |   %d   |   %d   | => valA=%016h, valB=%016h (rB_F=%%rsp)", 
                 PC_i, icode_o, ifun_o, rA_o, rB_o, valC_o, valP_o, instr_valid_o, imem_error_o, valA_decode, valB_decode);

        // Test B: POPL
        PC_i = 64'd98;
        #10;
        $display("%016h |   %h   |  %h  | %h  | %h  | %016h | %016h |   %d   |   %d   | => valA=%016h, valB=%016h (rB_F=%%rsp)", 
                 PC_i, icode_o, ifun_o, rA_o, rB_o, valC_o, valP_o, instr_valid_o, imem_error_o, valA_decode, valB_decode);
        
        $display("\n======================================================================");
        $display("========== 总计30个测试 (0, 1, 2_0~2_6, 3~5, 6_0~6_3, 7_0~7_6, 8, 9, A, B) ==========");
        $finish;
    end

endmodule
