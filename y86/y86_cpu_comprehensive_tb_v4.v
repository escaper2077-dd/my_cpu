`timescale 1ps/1ps

// 改进版测试：能区分条件满足/不满足的情况
// 策略：
// 1. 条件传送：用不同目标寄存器，初始化为特定值，验证是否被覆盖
// 2. 条件跳转：不跳转时执行一条"标记"指令，跳转时跳过它

module y86_cpu_comprehensive_tb_v4();

    reg clk;
    reg rst_n;
    
    // 实例化 CPU
    y86_cpu uut(
        .clk_i(clk),
        .rst_n_i(rst_n)
    );
    
    // 内部信号监控
    wire [63:0] PC = uut.pc_update_stage.PC_o;
    wire [3:0] icode = uut.fetch_stage.icode_o;
    wire [3:0] ifun = uut.fetch_stage.ifun_o;
    wire [3:0] rA = uut.fetch_stage.rA_o;
    wire [3:0] rB = uut.fetch_stage.rB_o;
    wire [63:0] valC = uut.fetch_stage.valC_o;
    wire [63:0] valP = uut.fetch_stage.valP_o;
    wire [1:0] Stat = uut.writeback_stage.stat_o;
    wire ZF = uut.execute_stage.ZF;
    wire SF = uut.execute_stage.SF;
    wire OF = uut.execute_stage.OF;
    
    // 初始化
    initial begin
        clk = 0;
        rst_n = 0;
    end
    
    // 时钟生成 (20ps 周期)
    always #10 clk = ~clk;
    
    // 超时控制
    initial begin
        #100000 $stop;
    end
    
    // 状态监控
    initial begin
        forever @ (posedge clk) begin
            if (rst_n) begin
                $display("Cycle: PC=0x%02h, icode=%h, ifun=%h, rA=%h, rB=%h, ZF=%b, SF=%b, OF=%b, Stat=%b",
                         PC, icode, ifun, rA, rB, ZF, SF, OF, Stat);
            end
        end
    end
    
    // ============================================================
    // 测试程序设计说明：
    // ============================================================
    // 寄存器用途：
    //   %rax (0) - 通用，测试值
    //   %rbx (3) - 通用，测试值  
    //   %rcx (1) - cmov目标1：条件满足时写入
    //   %rdx (2) - cmov目标2：条件不满足时保持原值
    //   %rsp (4) - 栈指针
    //   %rbp (5) - 标记计数器（记录不跳转时执行的指令数）
    //   %rsi (6) - 源值（用于cmov）
    //   %rdi (7) - 不变值（用于验证）
    // ============================================================
    
    initial begin
        $display("========================================");
        $display("=== Y86-64 Comprehensive Test V4 ===");
        $display("=== 验证条件传送和条件跳转的正确性 ===");
        $display("========================================\n");
        
        // ==================== 加载指令 ====================
        // 指令布局（十进制索引 = 十六进制PC）
        
        // === 初始化阶段 ===
        
        // [0] 0x00: NOP
        uut.fetch_stage.instr_mem[0] = 8'h00;
        
        // [1-10] 0x01: irmovq $200, %rsp - 栈指针
        uut.fetch_stage.instr_mem[1] = 8'h30;
        uut.fetch_stage.instr_mem[2] = 8'hF4;
        uut.fetch_stage.instr_mem[3] = 8'hC8;  // 200
        uut.fetch_stage.instr_mem[4] = 8'h00;
        uut.fetch_stage.instr_mem[5] = 8'h00;
        uut.fetch_stage.instr_mem[6] = 8'h00;
        uut.fetch_stage.instr_mem[7] = 8'h00;
        uut.fetch_stage.instr_mem[8] = 8'h00;
        uut.fetch_stage.instr_mem[9] = 8'h00;
        uut.fetch_stage.instr_mem[10] = 8'h00;
        
        // [11-20] 0x0B: irmovq $0, %rbp - 标记计数器初始化为0
        uut.fetch_stage.instr_mem[11] = 8'h30;
        uut.fetch_stage.instr_mem[12] = 8'hF5;
        uut.fetch_stage.instr_mem[13] = 8'h00;
        uut.fetch_stage.instr_mem[14] = 8'h00;
        uut.fetch_stage.instr_mem[15] = 8'h00;
        uut.fetch_stage.instr_mem[16] = 8'h00;
        uut.fetch_stage.instr_mem[17] = 8'h00;
        uut.fetch_stage.instr_mem[18] = 8'h00;
        uut.fetch_stage.instr_mem[19] = 8'h00;
        uut.fetch_stage.instr_mem[20] = 8'h00;
        
        // [21-30] 0x15: irmovq $99, %rsi - cmov源值
        uut.fetch_stage.instr_mem[21] = 8'h30;
        uut.fetch_stage.instr_mem[22] = 8'hF6;
        uut.fetch_stage.instr_mem[23] = 8'h63;  // 99
        uut.fetch_stage.instr_mem[24] = 8'h00;
        uut.fetch_stage.instr_mem[25] = 8'h00;
        uut.fetch_stage.instr_mem[26] = 8'h00;
        uut.fetch_stage.instr_mem[27] = 8'h00;
        uut.fetch_stage.instr_mem[28] = 8'h00;
        uut.fetch_stage.instr_mem[29] = 8'h00;
        uut.fetch_stage.instr_mem[30] = 8'h00;
        
        // [31-40] 0x1F: irmovq $1, %rdi - 增量值
        uut.fetch_stage.instr_mem[31] = 8'h30;
        uut.fetch_stage.instr_mem[32] = 8'hF7;
        uut.fetch_stage.instr_mem[33] = 8'h01;
        uut.fetch_stage.instr_mem[34] = 8'h00;
        uut.fetch_stage.instr_mem[35] = 8'h00;
        uut.fetch_stage.instr_mem[36] = 8'h00;
        uut.fetch_stage.instr_mem[37] = 8'h00;
        uut.fetch_stage.instr_mem[38] = 8'h00;
        uut.fetch_stage.instr_mem[39] = 8'h00;
        uut.fetch_stage.instr_mem[40] = 8'h00;
        
        // [41-50] 0x29: irmovq $0, %rcx - cmov目标1初始化为0
        uut.fetch_stage.instr_mem[41] = 8'h30;
        uut.fetch_stage.instr_mem[42] = 8'hF1;
        uut.fetch_stage.instr_mem[43] = 8'h00;
        uut.fetch_stage.instr_mem[44] = 8'h00;
        uut.fetch_stage.instr_mem[45] = 8'h00;
        uut.fetch_stage.instr_mem[46] = 8'h00;
        uut.fetch_stage.instr_mem[47] = 8'h00;
        uut.fetch_stage.instr_mem[48] = 8'h00;
        uut.fetch_stage.instr_mem[49] = 8'h00;
        uut.fetch_stage.instr_mem[50] = 8'h00;
        
        // [51-60] 0x33: irmovq $0, %rdx - cmov目标2初始化为0
        uut.fetch_stage.instr_mem[51] = 8'h30;
        uut.fetch_stage.instr_mem[52] = 8'hF2;
        uut.fetch_stage.instr_mem[53] = 8'h00;
        uut.fetch_stage.instr_mem[54] = 8'h00;
        uut.fetch_stage.instr_mem[55] = 8'h00;
        uut.fetch_stage.instr_mem[56] = 8'h00;
        uut.fetch_stage.instr_mem[57] = 8'h00;
        uut.fetch_stage.instr_mem[58] = 8'h00;
        uut.fetch_stage.instr_mem[59] = 8'h00;
        uut.fetch_stage.instr_mem[60] = 8'h00;
        
        // [61-70] 0x3D: irmovq $10, %rax
        uut.fetch_stage.instr_mem[61] = 8'h30;
        uut.fetch_stage.instr_mem[62] = 8'hF0;
        uut.fetch_stage.instr_mem[63] = 8'h0A;  // 10
        uut.fetch_stage.instr_mem[64] = 8'h00;
        uut.fetch_stage.instr_mem[65] = 8'h00;
        uut.fetch_stage.instr_mem[66] = 8'h00;
        uut.fetch_stage.instr_mem[67] = 8'h00;
        uut.fetch_stage.instr_mem[68] = 8'h00;
        uut.fetch_stage.instr_mem[69] = 8'h00;
        uut.fetch_stage.instr_mem[70] = 8'h00;
        
        // [71-80] 0x47: irmovq $10, %rbx
        uut.fetch_stage.instr_mem[71] = 8'h30;
        uut.fetch_stage.instr_mem[72] = 8'hF3;
        uut.fetch_stage.instr_mem[73] = 8'h0A;  // 10
        uut.fetch_stage.instr_mem[74] = 8'h00;
        uut.fetch_stage.instr_mem[75] = 8'h00;
        uut.fetch_stage.instr_mem[76] = 8'h00;
        uut.fetch_stage.instr_mem[77] = 8'h00;
        uut.fetch_stage.instr_mem[78] = 8'h00;
        uut.fetch_stage.instr_mem[79] = 8'h00;
        uut.fetch_stage.instr_mem[80] = 8'h00;
        
        // === 测试1: 设置 ZF=1 (通过 subq 得到0) ===
        // [81-82] 0x51: subq %rbx, %rax -> rax=10-10=0, ZF=1, SF=0, OF=0
        uut.fetch_stage.instr_mem[81] = 8'h61;
        uut.fetch_stage.instr_mem[82] = 8'h30;
        
        // 条件码状态: ZF=1, SF=0, OF=0
        // cmovle: (SF^OF)|ZF = 0|1 = 1 -> 应该移动
        // cmovl:  SF^OF = 0 -> 不应移动
        // cmove:  ZF = 1 -> 应该移动
        // cmovne: ~ZF = 0 -> 不应移动
        // cmovge: ~(SF^OF) = 1 -> 应该移动
        // cmovg:  ~(SF^OF)&~ZF = 1&0 = 0 -> 不应移动
        
        // [83-84] 0x53: cmovle %rsi, %rcx - 应该移动，rcx=99
        uut.fetch_stage.instr_mem[83] = 8'h21;
        uut.fetch_stage.instr_mem[84] = 8'h61;  // rA=6(%rsi), rB=1(%rcx)
        
        // [85-86] 0x55: cmovl %rsi, %rdx - 不应移动，rdx保持0
        uut.fetch_stage.instr_mem[85] = 8'h22;
        uut.fetch_stage.instr_mem[86] = 8'h62;  // rA=6(%rsi), rB=2(%rdx)
        
        // === 测试2: 设置 SF=1 (通过减法得到负数) ===
        // [87-96] 0x57: irmovq $5, %rax
        uut.fetch_stage.instr_mem[87] = 8'h30;
        uut.fetch_stage.instr_mem[88] = 8'hF0;
        uut.fetch_stage.instr_mem[89] = 8'h05;
        uut.fetch_stage.instr_mem[90] = 8'h00;
        uut.fetch_stage.instr_mem[91] = 8'h00;
        uut.fetch_stage.instr_mem[92] = 8'h00;
        uut.fetch_stage.instr_mem[93] = 8'h00;
        uut.fetch_stage.instr_mem[94] = 8'h00;
        uut.fetch_stage.instr_mem[95] = 8'h00;
        uut.fetch_stage.instr_mem[96] = 8'h00;
        
        // [97-98] 0x61: subq %rbx, %rax -> rax=5-10=-5, ZF=0, SF=1, OF=0
        uut.fetch_stage.instr_mem[97] = 8'h61;
        uut.fetch_stage.instr_mem[98] = 8'h30;
        
        // 条件码状态: ZF=0, SF=1, OF=0
        // cmovl:  SF^OF = 1 -> 应该移动
        // cmovge: ~(SF^OF) = 0 -> 不应移动
        
        // [99-100] 0x63: cmovl %rsi, %rdx - 应该移动，rdx=99
        uut.fetch_stage.instr_mem[99] = 8'h22;
        uut.fetch_stage.instr_mem[100] = 8'h62;
        
        // === 测试3: 设置正数 (ZF=0, SF=0) 用于跳转测试 ===
        // [101-110] 0x65: irmovq $20, %rax
        uut.fetch_stage.instr_mem[101] = 8'h30;
        uut.fetch_stage.instr_mem[102] = 8'hF0;
        uut.fetch_stage.instr_mem[103] = 8'h14;  // 20
        uut.fetch_stage.instr_mem[104] = 8'h00;
        uut.fetch_stage.instr_mem[105] = 8'h00;
        uut.fetch_stage.instr_mem[106] = 8'h00;
        uut.fetch_stage.instr_mem[107] = 8'h00;
        uut.fetch_stage.instr_mem[108] = 8'h00;
        uut.fetch_stage.instr_mem[109] = 8'h00;
        uut.fetch_stage.instr_mem[110] = 8'h00;
        
        // [111-112] 0x6F: subq %rbx, %rax -> rax=20-10=10, ZF=0, SF=0, OF=0
        uut.fetch_stage.instr_mem[111] = 8'h61;
        uut.fetch_stage.instr_mem[112] = 8'h30;
        
        // 条件码状态: ZF=0, SF=0, OF=0
        // jle: (SF^OF)|ZF = 0 -> 不跳转
        // jl:  SF^OF = 0 -> 不跳转
        // je:  ZF = 0 -> 不跳转
        // jne: ~ZF = 1 -> 跳转
        // jge: ~(SF^OF) = 1 -> 跳转
        // jg:  ~(SF^OF)&~ZF = 1 -> 跳转
        
        // === 跳转测试 ===
        // 测试 jle (不跳转) - 执行下一条指令增加 rbp
        // [113-121] 0x71: jle target=131 (跳到nop)
        uut.fetch_stage.instr_mem[113] = 8'h71;
        uut.fetch_stage.instr_mem[114] = 8'h83;  // target = 131 = 0x83
        uut.fetch_stage.instr_mem[115] = 8'h00;
        uut.fetch_stage.instr_mem[116] = 8'h00;
        uut.fetch_stage.instr_mem[117] = 8'h00;
        uut.fetch_stage.instr_mem[118] = 8'h00;
        uut.fetch_stage.instr_mem[119] = 8'h00;
        uut.fetch_stage.instr_mem[120] = 8'h00;
        uut.fetch_stage.instr_mem[121] = 8'h00;
        
        // [122-123] 0x7A: addq %rdi, %rbp - 不跳转时执行，rbp++
        uut.fetch_stage.instr_mem[122] = 8'h60;
        uut.fetch_stage.instr_mem[123] = 8'h75;  // rA=7(%rdi), rB=5(%rbp)
        
        // 测试 jl (不跳转) - 执行下一条指令增加 rbp
        // [124-132] 0x7C: jl target=142 (跳到nop)
        uut.fetch_stage.instr_mem[124] = 8'h72;
        uut.fetch_stage.instr_mem[125] = 8'h8E;  // target = 142 = 0x8E
        uut.fetch_stage.instr_mem[126] = 8'h00;
        uut.fetch_stage.instr_mem[127] = 8'h00;
        uut.fetch_stage.instr_mem[128] = 8'h00;
        uut.fetch_stage.instr_mem[129] = 8'h00;
        uut.fetch_stage.instr_mem[130] = 8'h00;
        uut.fetch_stage.instr_mem[131] = 8'h00;
        uut.fetch_stage.instr_mem[132] = 8'h00;
        
        // [133-134] 0x85: addq %rdi, %rbp - 不跳转时执行，rbp++
        uut.fetch_stage.instr_mem[133] = 8'h60;
        uut.fetch_stage.instr_mem[134] = 8'h75;
        
        // 测试 je (不跳转) - 执行下一条指令增加 rbp  
        // [135-143] 0x87: je target=153 (跳到nop)
        uut.fetch_stage.instr_mem[135] = 8'h73;
        uut.fetch_stage.instr_mem[136] = 8'h99;  // target = 153 = 0x99
        uut.fetch_stage.instr_mem[137] = 8'h00;
        uut.fetch_stage.instr_mem[138] = 8'h00;
        uut.fetch_stage.instr_mem[139] = 8'h00;
        uut.fetch_stage.instr_mem[140] = 8'h00;
        uut.fetch_stage.instr_mem[141] = 8'h00;
        uut.fetch_stage.instr_mem[142] = 8'h00;
        uut.fetch_stage.instr_mem[143] = 8'h00;
        
        // [144-145] 0x90: addq %rdi, %rbp - 不跳转时执行，rbp++
        uut.fetch_stage.instr_mem[144] = 8'h60;
        uut.fetch_stage.instr_mem[145] = 8'h75;
        
        // 测试 jne (跳转) - 跳过下一条指令
        // [146-154] 0x92: jne target=157 (跳过addq)
        uut.fetch_stage.instr_mem[146] = 8'h74;
        uut.fetch_stage.instr_mem[147] = 8'h9D;  // target = 157 = 0x9D
        uut.fetch_stage.instr_mem[148] = 8'h00;
        uut.fetch_stage.instr_mem[149] = 8'h00;
        uut.fetch_stage.instr_mem[150] = 8'h00;
        uut.fetch_stage.instr_mem[151] = 8'h00;
        uut.fetch_stage.instr_mem[152] = 8'h00;
        uut.fetch_stage.instr_mem[153] = 8'h00;
        uut.fetch_stage.instr_mem[154] = 8'h00;
        
        // [155-156] 0x9B: addq %rdi, %rbp - 被跳过，不应执行
        uut.fetch_stage.instr_mem[155] = 8'h60;
        uut.fetch_stage.instr_mem[156] = 8'h75;
        
        // [157] 0x9D: 继续点 - nop
        uut.fetch_stage.instr_mem[157] = 8'h00;
        
        // 测试 jge (跳转)
        // [158-166] 0x9E: jge target=169 (跳过addq)
        uut.fetch_stage.instr_mem[158] = 8'h75;
        uut.fetch_stage.instr_mem[159] = 8'hA9;  // target = 169 = 0xA9
        uut.fetch_stage.instr_mem[160] = 8'h00;
        uut.fetch_stage.instr_mem[161] = 8'h00;
        uut.fetch_stage.instr_mem[162] = 8'h00;
        uut.fetch_stage.instr_mem[163] = 8'h00;
        uut.fetch_stage.instr_mem[164] = 8'h00;
        uut.fetch_stage.instr_mem[165] = 8'h00;
        uut.fetch_stage.instr_mem[166] = 8'h00;
        
        // [167-168] 0xA7: addq %rdi, %rbp - 被跳过，不应执行
        uut.fetch_stage.instr_mem[167] = 8'h60;
        uut.fetch_stage.instr_mem[168] = 8'h75;
        
        // [169] 0xA9: 继续点 - nop
        uut.fetch_stage.instr_mem[169] = 8'h00;
        
        // 测试 jg (跳转)
        // [170-178] 0xAA: jg target=181 (跳过addq)
        uut.fetch_stage.instr_mem[170] = 8'h76;
        uut.fetch_stage.instr_mem[171] = 8'hB5;  // target = 181 = 0xB5
        uut.fetch_stage.instr_mem[172] = 8'h00;
        uut.fetch_stage.instr_mem[173] = 8'h00;
        uut.fetch_stage.instr_mem[174] = 8'h00;
        uut.fetch_stage.instr_mem[175] = 8'h00;
        uut.fetch_stage.instr_mem[176] = 8'h00;
        uut.fetch_stage.instr_mem[177] = 8'h00;
        uut.fetch_stage.instr_mem[178] = 8'h00;
        
        // [179-180] 0xB3: addq %rdi, %rbp - 被跳过，不应执行
        uut.fetch_stage.instr_mem[179] = 8'h60;
        uut.fetch_stage.instr_mem[180] = 8'h75;
        
        // [181] 0xB5: 继续点 - nop
        uut.fetch_stage.instr_mem[181] = 8'h00;
        
        // 测试 jmp (无条件跳转)
        // [182-190] 0xB6: jmp target=193 (跳过addq)
        uut.fetch_stage.instr_mem[182] = 8'h70;
        uut.fetch_stage.instr_mem[183] = 8'hC1;  // target = 193 = 0xC1
        uut.fetch_stage.instr_mem[184] = 8'h00;
        uut.fetch_stage.instr_mem[185] = 8'h00;
        uut.fetch_stage.instr_mem[186] = 8'h00;
        uut.fetch_stage.instr_mem[187] = 8'h00;
        uut.fetch_stage.instr_mem[188] = 8'h00;
        uut.fetch_stage.instr_mem[189] = 8'h00;
        uut.fetch_stage.instr_mem[190] = 8'h00;
        
        // [191-192] 0xBF: addq %rdi, %rbp - 被跳过
        uut.fetch_stage.instr_mem[191] = 8'h60;
        uut.fetch_stage.instr_mem[192] = 8'h75;
        
        // === 栈操作测试 ===
        // [193-194] 0xC1: pushq %rax
        uut.fetch_stage.instr_mem[193] = 8'hA0;
        uut.fetch_stage.instr_mem[194] = 8'h0F;
        
        // [195-204] 0xC3: irmovq $77, %rax - 改变rax
        uut.fetch_stage.instr_mem[195] = 8'h30;
        uut.fetch_stage.instr_mem[196] = 8'hF0;
        uut.fetch_stage.instr_mem[197] = 8'h4D;  // 77
        uut.fetch_stage.instr_mem[198] = 8'h00;
        uut.fetch_stage.instr_mem[199] = 8'h00;
        uut.fetch_stage.instr_mem[200] = 8'h00;
        uut.fetch_stage.instr_mem[201] = 8'h00;
        uut.fetch_stage.instr_mem[202] = 8'h00;
        uut.fetch_stage.instr_mem[203] = 8'h00;
        uut.fetch_stage.instr_mem[204] = 8'h00;
        
        // [205-206] 0xCD: popq %rbx - rbx应该得到之前push的10
        uut.fetch_stage.instr_mem[205] = 8'hB0;
        uut.fetch_stage.instr_mem[206] = 8'h3F;
        
        // === CALL/RET 测试 ===
        // [207-215] 0xCF: call target=230
        uut.fetch_stage.instr_mem[207] = 8'h80;
        uut.fetch_stage.instr_mem[208] = 8'hE6;  // target = 230 = 0xE6
        uut.fetch_stage.instr_mem[209] = 8'h00;
        uut.fetch_stage.instr_mem[210] = 8'h00;
        uut.fetch_stage.instr_mem[211] = 8'h00;
        uut.fetch_stage.instr_mem[212] = 8'h00;
        uut.fetch_stage.instr_mem[213] = 8'h00;
        uut.fetch_stage.instr_mem[214] = 8'h00;
        uut.fetch_stage.instr_mem[215] = 8'h00;
        
        // [216] 0xD8: halt - call返回后执行
        uut.fetch_stage.instr_mem[216] = 8'h10;
        
        // [230] 0xE6: ret - 子程序
        uut.fetch_stage.instr_mem[230] = 8'h90;
        
        // 初始化其余内存
        for (integer i = 231; i < 1024; i = i + 1) begin
            uut.fetch_stage.instr_mem[i] = 8'h00;
        end
        
        // ==================== 打印加载的指令 ====================
        $display("\n=== Loaded Key Instructions ===");
        $display("PC=0x51: subq %%rbx,%%rax -> ZF=1,SF=0");
        $display("PC=0x53: cmovle %%rsi,%%rcx (should move)");
        $display("PC=0x55: cmovl %%rsi,%%rdx (should NOT move)");
        $display("PC=0x61: subq %%rbx,%%rax -> ZF=0,SF=1");
        $display("PC=0x63: cmovl %%rsi,%%rdx (should move)");
        $display("PC=0x6F: subq %%rbx,%%rax -> ZF=0,SF=0 (positive)");
        $display("PC=0x71: jle (should NOT jump, rbp++)");
        $display("PC=0x7C: jl (should NOT jump, rbp++)");
        $display("PC=0x87: je (should NOT jump, rbp++)");
        $display("PC=0x92: jne (should jump, skip addq)");
        $display("PC=0x9E: jge (should jump, skip addq)");
        $display("PC=0xAA: jg (should jump, skip addq)");
        $display("PC=0xB6: jmp (unconditional jump)");
        $display("========================================\n");
        
        // ==================== 启动测试 ====================
        #5 rst_n = 1;
        
        #15000;
        
        $display("\n========================================");
        $display("=== Test Complete ===");
        $display("========================================");
        
        $display("\n=== 寄存器状态 ===");
        $display("  %%rax = %d (expected: 77 from irmovq)", uut.decode_stage.regfile[0]);
        $display("  %%rbx = %d (expected: 10 from pop, original push value)", uut.decode_stage.regfile[3]);
        $display("  %%rcx = %d (expected: 99 from cmovle, ZF=1 condition met)", uut.decode_stage.regfile[1]);
        $display("  %%rdx = %d (expected: 99 from cmovl when SF=1)", uut.decode_stage.regfile[2]);
        $display("  %%rbp = %d (expected: 3, count of NOT-taken jumps: jle,jl,je)", uut.decode_stage.regfile[5]);
        $display("  %%rsi = %d (expected: 99 source value)", uut.decode_stage.regfile[6]);
        $display("  %%rdi = %d (expected: 1 increment value)", uut.decode_stage.regfile[7]);
        $display("  %%rsp = %d (expected: 200 after push/pop/call/ret)", uut.decode_stage.regfile[4]);
        
        $display("\n=== 验证结果 ===");
        
        // 验证条件传送
        if (uut.decode_stage.regfile[1] == 99)
            $display("  [PASS] cmovle: ZF=1 时正确移动");
        else
            $display("  [FAIL] cmovle: 期望99, 实际%d", uut.decode_stage.regfile[1]);
            
        if (uut.decode_stage.regfile[2] == 99)
            $display("  [PASS] cmovl: SF=1 时正确移动");
        else
            $display("  [FAIL] cmovl: 期望99, 实际%d", uut.decode_stage.regfile[2]);
        
        // 验证条件跳转
        if (uut.decode_stage.regfile[5] == 3)
            $display("  [PASS] 条件跳转: jle,jl,je 未跳转(执行了3次addq)");
        else
            $display("  [FAIL] 条件跳转: 期望rbp=3, 实际%d", uut.decode_stage.regfile[5]);
        
        // 验证push/pop
        if (uut.decode_stage.regfile[3] == 10)
            $display("  [PASS] push/pop: rbx正确恢复为10");
        else
            $display("  [FAIL] push/pop: 期望rbx=10, 实际%d", uut.decode_stage.regfile[3]);
        
        $display("\nCPU Status: %b (expected: 01 for HALT)", Stat);
        $display("Final PC: 0x%h (expected: 0xD8 = 216)", PC);
        
        $finish;
    end

endmodule
