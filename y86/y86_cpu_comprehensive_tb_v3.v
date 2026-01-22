`timescale 1ps/1ps

module y86_cpu_comprehensive_tb();

    reg clk;
    reg rst_n;
    
    // 实例化 CPU
    y86_cpu uut(
        .clk_i(clk),
        .rst_n_i(rst_n)
    );
    
    // 内部信号监控
    wire [63:0] PC = uut.pc_update_stage.PC_o;
    wire [63:0] npc = uut.pc_update_stage.new_PC;
    wire [3:0] icode = uut.fetch_stage.icode_o;
    wire [3:0] ifun = uut.fetch_stage.ifun_o;
    wire [3:0] rA = uut.fetch_stage.rA_o;
    wire [3:0] rB = uut.fetch_stage.rB_o;
    wire [63:0] valC = uut.fetch_stage.valC_o;
    wire [63:0] valP = uut.fetch_stage.valP_o;
    wire [63:0] valA = uut.decode_stage.valA_o;
    wire [63:0] valB = uut.decode_stage.valB_o;
    wire [63:0] valE_exe = uut.execute_stage.valE_o;
    wire [63:0] valM_mem = uut.memory_stage.valM_o;
    wire [63:0] valE_wb = uut.writeback_stage.valE_o;
    wire [63:0] valM_wb = uut.writeback_stage.valM_o;
    wire [1:0] Stat = uut.writeback_stage.stat_o;
    
    // 初始化
    initial begin
        clk = 0;
        rst_n = 0;
    end
    
    // 时钟生成 (20ps 周期)
    always #10 clk = ~clk;
    
    // 超时控制
    initial begin
        #50000 $stop;
    end
    
    // 状态监控和显示
    initial begin
        forever @ (posedge clk) begin
            if (rst_n) begin
                $display("Cycle: PC=0x%02h, icode=%h, ifun=%h, rA=%h, rB=%h, valC=0x%h, valP=0x%h, Stat=%b",
                         PC, icode, ifun, rA, rB, valC, valP, Stat);
            end
        end
    end
    
    // 测试程序 - 使用十进制数组索引，注释中标注十六进制PC地址
    // 地址对照：0=0x00, 11=0x0B, 21=0x15, 31=0x1F, 33=0x21, 35=0x23, 37=0x25, 39=0x27
    //           41=0x29, 51=0x33, 53=0x35, 55=0x37, 57=0x39, 59=0x3B, 61=0x3D
    //           63=0x3F, 73=0x49, 83=0x53, 85=0x55, 94=0x5E
    initial begin
        $display("========================================");
        $display("=== Y86-64 Comprehensive CPU Test ===");
        $display("========================================\n");
        
        // ==================== 加载指令到内存 ====================
        // 使用十进制索引，注释中给出十六进制PC值
        
        // [0] 0x00: NOP (1字节)
        uut.fetch_stage.instr_mem[0] = 8'h00;
        
        // [1-10] 0x01: irmovq $100, %rsp (10字节) - 初始化栈指针
        uut.fetch_stage.instr_mem[1] = 8'h30;
        uut.fetch_stage.instr_mem[2] = 8'hF4;
        uut.fetch_stage.instr_mem[3] = 8'h64;  // 100
        uut.fetch_stage.instr_mem[4] = 8'h00;
        uut.fetch_stage.instr_mem[5] = 8'h00;
        uut.fetch_stage.instr_mem[6] = 8'h00;
        uut.fetch_stage.instr_mem[7] = 8'h00;
        uut.fetch_stage.instr_mem[8] = 8'h00;
        uut.fetch_stage.instr_mem[9] = 8'h00;
        uut.fetch_stage.instr_mem[10] = 8'h00;
        
        // [11-20] 0x0B: irmovq $10, %rax (10字节)
        uut.fetch_stage.instr_mem[11] = 8'h30;
        uut.fetch_stage.instr_mem[12] = 8'hF0;
        uut.fetch_stage.instr_mem[13] = 8'h0A;  // 10
        uut.fetch_stage.instr_mem[14] = 8'h00;
        uut.fetch_stage.instr_mem[15] = 8'h00;
        uut.fetch_stage.instr_mem[16] = 8'h00;
        uut.fetch_stage.instr_mem[17] = 8'h00;
        uut.fetch_stage.instr_mem[18] = 8'h00;
        uut.fetch_stage.instr_mem[19] = 8'h00;
        uut.fetch_stage.instr_mem[20] = 8'h00;
        
        // [21-30] 0x15: irmovq $20, %rbx (10字节)
        uut.fetch_stage.instr_mem[21] = 8'h30;
        uut.fetch_stage.instr_mem[22] = 8'hF3;
        uut.fetch_stage.instr_mem[23] = 8'h14;  // 20
        uut.fetch_stage.instr_mem[24] = 8'h00;
        uut.fetch_stage.instr_mem[25] = 8'h00;
        uut.fetch_stage.instr_mem[26] = 8'h00;
        uut.fetch_stage.instr_mem[27] = 8'h00;
        uut.fetch_stage.instr_mem[28] = 8'h00;
        uut.fetch_stage.instr_mem[29] = 8'h00;
        uut.fetch_stage.instr_mem[30] = 8'h00;
        
        // [31-32] 0x1F: rrmovq %rax, %rcx (2字节) - RRMOVL ifun=0
        uut.fetch_stage.instr_mem[31] = 8'h20;
        uut.fetch_stage.instr_mem[32] = 8'h01;
        
        // [33-34] 0x21: addq %rbx, %rax (2字节) - ALU ifun=0, rax=30
        uut.fetch_stage.instr_mem[33] = 8'h60;
        uut.fetch_stage.instr_mem[34] = 8'h30;
        
        // [35-36] 0x23: subq %rbx, %rax (2字节) - ALU ifun=1, rax=10
        uut.fetch_stage.instr_mem[35] = 8'h61;
        uut.fetch_stage.instr_mem[36] = 8'h30;
        
        // [37-38] 0x25: andq %rbx, %rax (2字节) - ALU ifun=2
        uut.fetch_stage.instr_mem[37] = 8'h62;
        uut.fetch_stage.instr_mem[38] = 8'h30;
        
        // [39-40] 0x27: xorq %rbx, %rax (2字节) - ALU ifun=3, 设置ZF=1
        uut.fetch_stage.instr_mem[39] = 8'h63;
        uut.fetch_stage.instr_mem[40] = 8'h30;
        
        // [41-50] 0x29: irmovq $5, %rax (10字节) - 注意：irmovq不改变条件码！
        uut.fetch_stage.instr_mem[41] = 8'h30;
        uut.fetch_stage.instr_mem[42] = 8'hF0;
        uut.fetch_stage.instr_mem[43] = 8'h05;
        uut.fetch_stage.instr_mem[44] = 8'h00;
        uut.fetch_stage.instr_mem[45] = 8'h00;
        uut.fetch_stage.instr_mem[46] = 8'h00;
        uut.fetch_stage.instr_mem[47] = 8'h00;
        uut.fetch_stage.instr_mem[48] = 8'h00;
        uut.fetch_stage.instr_mem[49] = 8'h00;
        uut.fetch_stage.instr_mem[50] = 8'h00;
        
        // [51-52] 0x33: cmovle %rbx, %rdx (2字节) - RRMOVL ifun=1
        uut.fetch_stage.instr_mem[51] = 8'h21;
        uut.fetch_stage.instr_mem[52] = 8'h32;
        
        // [53-54] 0x35: cmovl %rbx, %rdx (2字节) - RRMOVL ifun=2
        uut.fetch_stage.instr_mem[53] = 8'h22;
        uut.fetch_stage.instr_mem[54] = 8'h32;
        
        // [55-56] 0x37: cmove %rbx, %rdx (2字节) - RRMOVL ifun=3
        uut.fetch_stage.instr_mem[55] = 8'h23;
        uut.fetch_stage.instr_mem[56] = 8'h32;
        
        // [57-58] 0x39: cmovne %rbx, %rdx (2字节) - RRMOVL ifun=4
        uut.fetch_stage.instr_mem[57] = 8'h24;
        uut.fetch_stage.instr_mem[58] = 8'h32;
        
        // [59-60] 0x3B: cmovge %rbx, %rdx (2字节) - RRMOVL ifun=5
        uut.fetch_stage.instr_mem[59] = 8'h25;
        uut.fetch_stage.instr_mem[60] = 8'h32;
        
        // [61-62] 0x3D: cmovg %rbx, %rdx (2字节) - RRMOVL ifun=6
        uut.fetch_stage.instr_mem[61] = 8'h26;
        uut.fetch_stage.instr_mem[62] = 8'h32;
        
        // [63-72] 0x3F: rmmovq %rax, 16(%rsp) (10字节) - RMMOVL
        uut.fetch_stage.instr_mem[63] = 8'h40;
        uut.fetch_stage.instr_mem[64] = 8'h04;
        uut.fetch_stage.instr_mem[65] = 8'h10;  // offset = 16
        uut.fetch_stage.instr_mem[66] = 8'h00;
        uut.fetch_stage.instr_mem[67] = 8'h00;
        uut.fetch_stage.instr_mem[68] = 8'h00;
        uut.fetch_stage.instr_mem[69] = 8'h00;
        uut.fetch_stage.instr_mem[70] = 8'h00;
        uut.fetch_stage.instr_mem[71] = 8'h00;
        uut.fetch_stage.instr_mem[72] = 8'h00;
        
        // [73-82] 0x49: mrmovq 16(%rsp), %rcx (10字节) - MRMOVL
        uut.fetch_stage.instr_mem[73] = 8'h50;
        uut.fetch_stage.instr_mem[74] = 8'h14;
        uut.fetch_stage.instr_mem[75] = 8'h10;
        uut.fetch_stage.instr_mem[76] = 8'h00;
        uut.fetch_stage.instr_mem[77] = 8'h00;
        uut.fetch_stage.instr_mem[78] = 8'h00;
        uut.fetch_stage.instr_mem[79] = 8'h00;
        uut.fetch_stage.instr_mem[80] = 8'h00;
        uut.fetch_stage.instr_mem[81] = 8'h00;
        uut.fetch_stage.instr_mem[82] = 8'h00;
        
        // [83-84] 0x53: addq %rcx, %rax (2字节) - 清除ZF (5+5=10, ZF=0, SF=0)
        uut.fetch_stage.instr_mem[83] = 8'h60;
        uut.fetch_stage.instr_mem[84] = 8'h10;
        
        // [85-93] 0x55: jle target=94 (9字节) - JXX ifun=1, 不跳转(ZF=0,SF=0,OF=0)
        // valP = 85+9 = 94
        uut.fetch_stage.instr_mem[85] = 8'h71;
        uut.fetch_stage.instr_mem[86] = 8'h5E;  // target = 94 = 0x5E
        uut.fetch_stage.instr_mem[87] = 8'h00;
        uut.fetch_stage.instr_mem[88] = 8'h00;
        uut.fetch_stage.instr_mem[89] = 8'h00;
        uut.fetch_stage.instr_mem[90] = 8'h00;
        uut.fetch_stage.instr_mem[91] = 8'h00;
        uut.fetch_stage.instr_mem[92] = 8'h00;
        uut.fetch_stage.instr_mem[93] = 8'h00;
        
        // [94-102] 0x5E: jl target=103 (9字节) - JXX ifun=2, 不跳转
        // valP = 94+9 = 103
        uut.fetch_stage.instr_mem[94] = 8'h72;
        uut.fetch_stage.instr_mem[95] = 8'h67;  // target = 103 = 0x67
        uut.fetch_stage.instr_mem[96] = 8'h00;
        uut.fetch_stage.instr_mem[97] = 8'h00;
        uut.fetch_stage.instr_mem[98] = 8'h00;
        uut.fetch_stage.instr_mem[99] = 8'h00;
        uut.fetch_stage.instr_mem[100] = 8'h00;
        uut.fetch_stage.instr_mem[101] = 8'h00;
        uut.fetch_stage.instr_mem[102] = 8'h00;
        
        // [103-111] 0x67: je target=112 (9字节) - JXX ifun=3, 不跳转(ZF=0)
        // valP = 103+9 = 112
        uut.fetch_stage.instr_mem[103] = 8'h73;
        uut.fetch_stage.instr_mem[104] = 8'h70;  // target = 112 = 0x70
        uut.fetch_stage.instr_mem[105] = 8'h00;
        uut.fetch_stage.instr_mem[106] = 8'h00;
        uut.fetch_stage.instr_mem[107] = 8'h00;
        uut.fetch_stage.instr_mem[108] = 8'h00;
        uut.fetch_stage.instr_mem[109] = 8'h00;
        uut.fetch_stage.instr_mem[110] = 8'h00;
        uut.fetch_stage.instr_mem[111] = 8'h00;
        
        // [112-120] 0x70: jne target=130 (9字节) - JXX ifun=4, 应该跳转(ZF=0)
        // valP = 112+9 = 121, 但跳转到130
        uut.fetch_stage.instr_mem[112] = 8'h74;
        uut.fetch_stage.instr_mem[113] = 8'h82;  // target = 130 = 0x82
        uut.fetch_stage.instr_mem[114] = 8'h00;
        uut.fetch_stage.instr_mem[115] = 8'h00;
        uut.fetch_stage.instr_mem[116] = 8'h00;
        uut.fetch_stage.instr_mem[117] = 8'h00;
        uut.fetch_stage.instr_mem[118] = 8'h00;
        uut.fetch_stage.instr_mem[119] = 8'h00;
        uut.fetch_stage.instr_mem[120] = 8'h00;
        
        // [121-129] 跳过（被jne跳过）
        
        // [130-138] 0x82: jge target=148 (9字节) - JXX ifun=5, 应该跳转(SF^OF=0)
        // valP = 130+9 = 139, 但跳转到148
        uut.fetch_stage.instr_mem[130] = 8'h75;
        uut.fetch_stage.instr_mem[131] = 8'h94;  // target = 148 = 0x94
        uut.fetch_stage.instr_mem[132] = 8'h00;
        uut.fetch_stage.instr_mem[133] = 8'h00;
        uut.fetch_stage.instr_mem[134] = 8'h00;
        uut.fetch_stage.instr_mem[135] = 8'h00;
        uut.fetch_stage.instr_mem[136] = 8'h00;
        uut.fetch_stage.instr_mem[137] = 8'h00;
        uut.fetch_stage.instr_mem[138] = 8'h00;
        
        // [139-147] 跳过（被jge跳过）
        
        // [148-156] 0x94: jg target=166 (9字节) - JXX ifun=6, 应该跳转(~(SF^OF)&~ZF)
        // valP = 148+9 = 157, 但跳转到166
        uut.fetch_stage.instr_mem[148] = 8'h76;
        uut.fetch_stage.instr_mem[149] = 8'hA6;  // target = 166 = 0xA6
        uut.fetch_stage.instr_mem[150] = 8'h00;
        uut.fetch_stage.instr_mem[151] = 8'h00;
        uut.fetch_stage.instr_mem[152] = 8'h00;
        uut.fetch_stage.instr_mem[153] = 8'h00;
        uut.fetch_stage.instr_mem[154] = 8'h00;
        uut.fetch_stage.instr_mem[155] = 8'h00;
        uut.fetch_stage.instr_mem[156] = 8'h00;
        
        // [157-165] 跳过（被jg跳过）
        
        // [166-174] 0xA6: jmp target=184 (9字节) - JXX ifun=0, 无条件跳转
        // valP = 166+9 = 175, 但跳转到184
        uut.fetch_stage.instr_mem[166] = 8'h70;
        uut.fetch_stage.instr_mem[167] = 8'hB8;  // target = 184 = 0xB8
        uut.fetch_stage.instr_mem[168] = 8'h00;
        uut.fetch_stage.instr_mem[169] = 8'h00;
        uut.fetch_stage.instr_mem[170] = 8'h00;
        uut.fetch_stage.instr_mem[171] = 8'h00;
        uut.fetch_stage.instr_mem[172] = 8'h00;
        uut.fetch_stage.instr_mem[173] = 8'h00;
        uut.fetch_stage.instr_mem[174] = 8'h00;
        
        // [175-183] 跳过（被jmp跳过）
        
        // [184-185] 0xB8: pushq %rax (2字节) - PUSHL
        uut.fetch_stage.instr_mem[184] = 8'hA0;
        uut.fetch_stage.instr_mem[185] = 8'hF0;
        
        // [186-195] 0xBA: irmovq $30, %rax (10字节)
        uut.fetch_stage.instr_mem[186] = 8'h30;
        uut.fetch_stage.instr_mem[187] = 8'hF0;
        uut.fetch_stage.instr_mem[188] = 8'h1E;  // 30
        uut.fetch_stage.instr_mem[189] = 8'h00;
        uut.fetch_stage.instr_mem[190] = 8'h00;
        uut.fetch_stage.instr_mem[191] = 8'h00;
        uut.fetch_stage.instr_mem[192] = 8'h00;
        uut.fetch_stage.instr_mem[193] = 8'h00;
        uut.fetch_stage.instr_mem[194] = 8'h00;
        uut.fetch_stage.instr_mem[195] = 8'h00;
        
        // [196-197] 0xC4: popq %rbx (2字节) - POPL
        uut.fetch_stage.instr_mem[196] = 8'hB0;
        uut.fetch_stage.instr_mem[197] = 8'hF3;
        
        // [198-206] 0xC6: call target=220 (9字节) - CALL
        // 返回地址 = 198+9 = 207 = 0xCF
        uut.fetch_stage.instr_mem[198] = 8'h80;
        uut.fetch_stage.instr_mem[199] = 8'hDC;  // target = 220 = 0xDC
        uut.fetch_stage.instr_mem[200] = 8'h00;
        uut.fetch_stage.instr_mem[201] = 8'h00;
        uut.fetch_stage.instr_mem[202] = 8'h00;
        uut.fetch_stage.instr_mem[203] = 8'h00;
        uut.fetch_stage.instr_mem[204] = 8'h00;
        uut.fetch_stage.instr_mem[205] = 8'h00;
        uut.fetch_stage.instr_mem[206] = 8'h00;
        
        // [207] 0xCF: halt (1字节) - 从call返回后停止
        uut.fetch_stage.instr_mem[207] = 8'h10;
        
        // [220] 0xDC: ret (1字节) - RET，返回到207
        uut.fetch_stage.instr_mem[220] = 8'h90;
        
        // 初始化其他内存位置为NOP
        for (integer i = 221; i < 1024; i = i + 1) begin
            uut.fetch_stage.instr_mem[i] = 8'h00;
        end
        
        // ==================== 打印加载的指令 ====================
        $display("\n========================================");
        $display("=== Loaded Instructions ===");
        $display("========================================");
        
        // PC=0x00: NOP
        $display("PC=0x00: %02h          -> NOP", uut.fetch_stage.instr_mem[0]);
        
        // PC=0x01: irmovq $100, %rsp
        $display("PC=0x01: %02h %02h %02h%02h%02h%02h%02h%02h%02h%02h -> irmovq $100, %%rsp",
            uut.fetch_stage.instr_mem[1], uut.fetch_stage.instr_mem[2],
            uut.fetch_stage.instr_mem[10], uut.fetch_stage.instr_mem[9], uut.fetch_stage.instr_mem[8], uut.fetch_stage.instr_mem[7],
            uut.fetch_stage.instr_mem[6], uut.fetch_stage.instr_mem[5], uut.fetch_stage.instr_mem[4], uut.fetch_stage.instr_mem[3]);
        
        // PC=0x0B: irmovq $10, %rax
        $display("PC=0x0B: %02h %02h %02h%02h%02h%02h%02h%02h%02h%02h -> irmovq $10, %%rax",
            uut.fetch_stage.instr_mem[11], uut.fetch_stage.instr_mem[12],
            uut.fetch_stage.instr_mem[20], uut.fetch_stage.instr_mem[19], uut.fetch_stage.instr_mem[18], uut.fetch_stage.instr_mem[17],
            uut.fetch_stage.instr_mem[16], uut.fetch_stage.instr_mem[15], uut.fetch_stage.instr_mem[14], uut.fetch_stage.instr_mem[13]);
        
        // PC=0x15: irmovq $20, %rbx
        $display("PC=0x15: %02h %02h %02h%02h%02h%02h%02h%02h%02h%02h -> irmovq $20, %%rbx",
            uut.fetch_stage.instr_mem[21], uut.fetch_stage.instr_mem[22],
            uut.fetch_stage.instr_mem[30], uut.fetch_stage.instr_mem[29], uut.fetch_stage.instr_mem[28], uut.fetch_stage.instr_mem[27],
            uut.fetch_stage.instr_mem[26], uut.fetch_stage.instr_mem[25], uut.fetch_stage.instr_mem[24], uut.fetch_stage.instr_mem[23]);
        
        // PC=0x1F: rrmovq %rax, %rdx
        $display("PC=0x1F: %02h %02h       -> rrmovq %%rax, %%rdx",
            uut.fetch_stage.instr_mem[31], uut.fetch_stage.instr_mem[32]);
        
        // PC=0x21: addq %rbx, %rax
        $display("PC=0x21: %02h %02h       -> addq %%rbx, %%rax",
            uut.fetch_stage.instr_mem[33], uut.fetch_stage.instr_mem[34]);
        
        // PC=0x23: subq %rax, %rbx
        $display("PC=0x23: %02h %02h       -> subq %%rax, %%rbx",
            uut.fetch_stage.instr_mem[35], uut.fetch_stage.instr_mem[36]);
        
        // PC=0x25: andq %rdx, %rcx
        $display("PC=0x25: %02h %02h       -> andq %%rdx, %%rcx",
            uut.fetch_stage.instr_mem[37], uut.fetch_stage.instr_mem[38]);
        
        // PC=0x27: xorq %rcx, %rcx
        $display("PC=0x27: %02h %02h       -> xorq %%rcx, %%rcx",
            uut.fetch_stage.instr_mem[39], uut.fetch_stage.instr_mem[40]);
        
        // PC=0x29: irmovq $5, %rax
        $display("PC=0x29: %02h %02h %02h%02h%02h%02h%02h%02h%02h%02h -> irmovq $5, %%rax",
            uut.fetch_stage.instr_mem[41], uut.fetch_stage.instr_mem[42],
            uut.fetch_stage.instr_mem[50], uut.fetch_stage.instr_mem[49], uut.fetch_stage.instr_mem[48], uut.fetch_stage.instr_mem[47],
            uut.fetch_stage.instr_mem[46], uut.fetch_stage.instr_mem[45], uut.fetch_stage.instr_mem[44], uut.fetch_stage.instr_mem[43]);
        
        // PC=0x33: cmovle
        $display("PC=0x33: %02h %02h       -> cmovle %%rdx, %%rcx (ifun=1)",
            uut.fetch_stage.instr_mem[51], uut.fetch_stage.instr_mem[52]);
        
        // PC=0x35: cmovl
        $display("PC=0x35: %02h %02h       -> cmovl %%rdx, %%rcx (ifun=2)",
            uut.fetch_stage.instr_mem[53], uut.fetch_stage.instr_mem[54]);
        
        // PC=0x37: cmove
        $display("PC=0x37: %02h %02h       -> cmove %%rdx, %%rcx (ifun=3)",
            uut.fetch_stage.instr_mem[55], uut.fetch_stage.instr_mem[56]);
        
        // PC=0x39: cmovne
        $display("PC=0x39: %02h %02h       -> cmovne %%rdx, %%rcx (ifun=4)",
            uut.fetch_stage.instr_mem[57], uut.fetch_stage.instr_mem[58]);
        
        // PC=0x3B: cmovge
        $display("PC=0x3B: %02h %02h       -> cmovge %%rdx, %%rcx (ifun=5)",
            uut.fetch_stage.instr_mem[59], uut.fetch_stage.instr_mem[60]);
        
        // PC=0x3D: cmovg
        $display("PC=0x3D: %02h %02h       -> cmovg %%rdx, %%rcx (ifun=6)",
            uut.fetch_stage.instr_mem[61], uut.fetch_stage.instr_mem[62]);
        
        // PC=0x3F: rmmovq %rax, 0(%rbx)
        $display("PC=0x3F: %02h %02h %02h%02h%02h%02h%02h%02h%02h%02h -> rmmovq %%rax, 0(%%rbx)",
            uut.fetch_stage.instr_mem[63], uut.fetch_stage.instr_mem[64],
            uut.fetch_stage.instr_mem[72], uut.fetch_stage.instr_mem[71], uut.fetch_stage.instr_mem[70], uut.fetch_stage.instr_mem[69],
            uut.fetch_stage.instr_mem[68], uut.fetch_stage.instr_mem[67], uut.fetch_stage.instr_mem[66], uut.fetch_stage.instr_mem[65]);
        
        // PC=0x49: mrmovq 0(%rbx), %rcx
        $display("PC=0x49: %02h %02h %02h%02h%02h%02h%02h%02h%02h%02h -> mrmovq 0(%%rbx), %%rcx",
            uut.fetch_stage.instr_mem[73], uut.fetch_stage.instr_mem[74],
            uut.fetch_stage.instr_mem[82], uut.fetch_stage.instr_mem[81], uut.fetch_stage.instr_mem[80], uut.fetch_stage.instr_mem[79],
            uut.fetch_stage.instr_mem[78], uut.fetch_stage.instr_mem[77], uut.fetch_stage.instr_mem[76], uut.fetch_stage.instr_mem[75]);
        
        // PC=0x53: addq %rcx, %rax
        $display("PC=0x53: %02h %02h       -> addq %%rcx, %%rax (clear ZF)",
            uut.fetch_stage.instr_mem[83], uut.fetch_stage.instr_mem[84]);
        
        // PC=0x55: jle target=94
        $display("PC=0x55: %02h %02h%02h%02h%02h%02h%02h%02h%02h -> jle target=94 (ifun=1)",
            uut.fetch_stage.instr_mem[85], 
            uut.fetch_stage.instr_mem[93], uut.fetch_stage.instr_mem[92], uut.fetch_stage.instr_mem[91], uut.fetch_stage.instr_mem[90],
            uut.fetch_stage.instr_mem[89], uut.fetch_stage.instr_mem[88], uut.fetch_stage.instr_mem[87], uut.fetch_stage.instr_mem[86]);
        
        // PC=0x5E: jl target=103
        $display("PC=0x5E: %02h %02h%02h%02h%02h%02h%02h%02h%02h -> jl target=103 (ifun=2)",
            uut.fetch_stage.instr_mem[94], 
            uut.fetch_stage.instr_mem[102], uut.fetch_stage.instr_mem[101], uut.fetch_stage.instr_mem[100], uut.fetch_stage.instr_mem[99],
            uut.fetch_stage.instr_mem[98], uut.fetch_stage.instr_mem[97], uut.fetch_stage.instr_mem[96], uut.fetch_stage.instr_mem[95]);
        
        // PC=0x67: je target=112
        $display("PC=0x67: %02h %02h%02h%02h%02h%02h%02h%02h%02h -> je target=112 (ifun=3)",
            uut.fetch_stage.instr_mem[103], 
            uut.fetch_stage.instr_mem[111], uut.fetch_stage.instr_mem[110], uut.fetch_stage.instr_mem[109], uut.fetch_stage.instr_mem[108],
            uut.fetch_stage.instr_mem[107], uut.fetch_stage.instr_mem[106], uut.fetch_stage.instr_mem[105], uut.fetch_stage.instr_mem[104]);
        
        // PC=0x70: jne target=130
        $display("PC=0x70: %02h %02h%02h%02h%02h%02h%02h%02h%02h -> jne target=130 (ifun=4)",
            uut.fetch_stage.instr_mem[112], 
            uut.fetch_stage.instr_mem[120], uut.fetch_stage.instr_mem[119], uut.fetch_stage.instr_mem[118], uut.fetch_stage.instr_mem[117],
            uut.fetch_stage.instr_mem[116], uut.fetch_stage.instr_mem[115], uut.fetch_stage.instr_mem[114], uut.fetch_stage.instr_mem[113]);
        
        // PC=0x82: jge target=148
        $display("PC=0x82: %02h %02h%02h%02h%02h%02h%02h%02h%02h -> jge target=148 (ifun=5)",
            uut.fetch_stage.instr_mem[130], 
            uut.fetch_stage.instr_mem[138], uut.fetch_stage.instr_mem[137], uut.fetch_stage.instr_mem[136], uut.fetch_stage.instr_mem[135],
            uut.fetch_stage.instr_mem[134], uut.fetch_stage.instr_mem[133], uut.fetch_stage.instr_mem[132], uut.fetch_stage.instr_mem[131]);
        
        // PC=0x94: jg target=166
        $display("PC=0x94: %02h %02h%02h%02h%02h%02h%02h%02h%02h -> jg target=166 (ifun=6)",
            uut.fetch_stage.instr_mem[148], 
            uut.fetch_stage.instr_mem[156], uut.fetch_stage.instr_mem[155], uut.fetch_stage.instr_mem[154], uut.fetch_stage.instr_mem[153],
            uut.fetch_stage.instr_mem[152], uut.fetch_stage.instr_mem[151], uut.fetch_stage.instr_mem[150], uut.fetch_stage.instr_mem[149]);
        
        // PC=0xA6: jmp target=184
        $display("PC=0xA6: %02h %02h%02h%02h%02h%02h%02h%02h%02h -> jmp target=184 (ifun=0)",
            uut.fetch_stage.instr_mem[166], 
            uut.fetch_stage.instr_mem[174], uut.fetch_stage.instr_mem[173], uut.fetch_stage.instr_mem[172], uut.fetch_stage.instr_mem[171],
            uut.fetch_stage.instr_mem[170], uut.fetch_stage.instr_mem[169], uut.fetch_stage.instr_mem[168], uut.fetch_stage.instr_mem[167]);
        
        // PC=0xB8: pushq %rax
        $display("PC=0xB8: %02h %02h       -> pushq %%rax",
            uut.fetch_stage.instr_mem[184], uut.fetch_stage.instr_mem[185]);
        
        // PC=0xBA: irmovq $30, %rax
        $display("PC=0xBA: %02h %02h %02h%02h%02h%02h%02h%02h%02h%02h -> irmovq $30, %%rax",
            uut.fetch_stage.instr_mem[186], uut.fetch_stage.instr_mem[187],
            uut.fetch_stage.instr_mem[195], uut.fetch_stage.instr_mem[194], uut.fetch_stage.instr_mem[193], uut.fetch_stage.instr_mem[192],
            uut.fetch_stage.instr_mem[191], uut.fetch_stage.instr_mem[190], uut.fetch_stage.instr_mem[189], uut.fetch_stage.instr_mem[188]);
        
        // PC=0xC4: popq %rbx
        $display("PC=0xC4: %02h %02h       -> popq %%rbx",
            uut.fetch_stage.instr_mem[196], uut.fetch_stage.instr_mem[197]);
        
        // PC=0xC6: call target=220
        $display("PC=0xC6: %02h %02h%02h%02h%02h%02h%02h%02h%02h -> call target=220",
            uut.fetch_stage.instr_mem[198], 
            uut.fetch_stage.instr_mem[206], uut.fetch_stage.instr_mem[205], uut.fetch_stage.instr_mem[204], uut.fetch_stage.instr_mem[203],
            uut.fetch_stage.instr_mem[202], uut.fetch_stage.instr_mem[201], uut.fetch_stage.instr_mem[200], uut.fetch_stage.instr_mem[199]);
        
        // PC=0xCF: halt
        $display("PC=0xCF: %02h          -> halt",
            uut.fetch_stage.instr_mem[207]);
        
        // PC=0xDC: ret
        $display("PC=0xDC: %02h          -> ret",
            uut.fetch_stage.instr_mem[220]);
        
        $display("========================================\n");
        
        // ==================== 启动测试 ====================
        
        #5 rst_n = 1;
        
        // 等待足够的周期让所有指令执行完成
        #10000;
        
        $display("\n========================================");
        $display("=== Test Complete ===");
        $display("========================================");
        
        $display("\n寄存器状态:");
        $display("  %%rax = 0x%h", uut.decode_stage.regfile[0]);
        $display("  %%rbx = 0x%h", uut.decode_stage.regfile[3]);
        $display("  %%rcx = 0x%h", uut.decode_stage.regfile[1]);
        $display("  %%rdx = 0x%h", uut.decode_stage.regfile[2]);
        $display("  %%rsp = 0x%h", uut.decode_stage.regfile[4]);
        
        $display("\nCPU Status: %b (expected: 01 for HALT)", Stat);
        $display("Final PC: 0x%h (expected: 0xCF = 207)", PC);
        
        $finish;
    end

endmodule
