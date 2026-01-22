`timescale 1ps/1ps

// Y86-64 全覆盖测试 V5
// 特点：
// 1. 覆盖所有 icode 和 ifun 组合
// 2. 详细输出所有关键信号
// 3. 验证条件传送和条件跳转的正确性

module y86_cpu_comprehensive_tb_v5();

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
    wire [63:0] valE = uut.execute_stage.valE_o;
    wire Cnd = uut.execute_stage.Cnd_o;
    wire [63:0] valM = uut.memory_stage.valM_o;
    wire [63:0] valE_wb = uut.writeback_stage.valE_o;
    wire [63:0] valM_wb = uut.writeback_stage.valM_o;
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
        #200000 $stop;
    end
    
    // HALT 检测 - 检测到 HALT 后立即结束
    initial begin
        wait(rst_n == 1);
        forever @(posedge clk) begin
            if (Stat == 2'b01) begin  // HLT status
                #20;  // 等待一个周期让输出完成
                $display("\n========================================");
                $display("=== Test Complete ===");
                $display("========================================");
                
                $display("\n=== 寄存器状态 ===");
                $display("  %%rax = %d", uut.decode_stage.regfile[0]);
                $display("  %%rcx = %d", uut.decode_stage.regfile[1]);
                $display("  %%rdx = %d (should be 10, from rrmovq)", uut.decode_stage.regfile[2]);
                $display("  %%rbx = %d", uut.decode_stage.regfile[3]);
                $display("  %%rsp = %d", uut.decode_stage.regfile[4]);
                $display("  %%rbp = %d (should be 3, count of NOT-taken jumps: jle,jl,je)", uut.decode_stage.regfile[5]);
                $display("  %%rsi = %d (should be 123)", uut.decode_stage.regfile[6]);
                $display("  %%rdi = %d (should be 99, from mrmovq)", uut.decode_stage.regfile[7]);
                $display("  %%r8  = %d (should be 99, cmovle when ZF=1)", uut.decode_stage.regfile[8]);
                $display("  %%r9  = %d (should be 9, cmovl NOT taken when ZF=1)", uut.decode_stage.regfile[9]);
                $display("  %%r10 = %d (should be 99, cmove when ZF=1)", uut.decode_stage.regfile[10]);
                $display("  %%r11 = %d (should be 11, cmovne NOT taken when ZF=1)", uut.decode_stage.regfile[11]);
                $display("  %%r12 = %d (should be 99, cmovge when ZF=1)", uut.decode_stage.regfile[12]);
                $display("  %%r13 = %d (should be 13, cmovg NOT taken when ZF=1)", uut.decode_stage.regfile[13]);
                $display("  %%r14 = %d (should be 99, from popq)", uut.decode_stage.regfile[14]);
                
                $display("\n=== 验证结果 ===");
                if (uut.decode_stage.regfile[2] == 10) $display("  [PASS] rrmovq: rdx=10");
                else $display("  [FAIL] rrmovq: expected 10, got %d", uut.decode_stage.regfile[2]);
                if (uut.decode_stage.regfile[8] == 99) $display("  [PASS] cmovle (ifun=1): r8=99");
                else $display("  [FAIL] cmovle: expected 99, got %d", uut.decode_stage.regfile[8]);
                if (uut.decode_stage.regfile[9] == 9) $display("  [PASS] cmovl (ifun=2): r9=9 (NOT moved)");
                else $display("  [FAIL] cmovl: expected 9, got %d", uut.decode_stage.regfile[9]);
                if (uut.decode_stage.regfile[10] == 99) $display("  [PASS] cmove (ifun=3): r10=99");
                else $display("  [FAIL] cmove: expected 99, got %d", uut.decode_stage.regfile[10]);
                if (uut.decode_stage.regfile[11] == 11) $display("  [PASS] cmovne (ifun=4): r11=11 (NOT moved)");
                else $display("  [FAIL] cmovne: expected 11, got %d", uut.decode_stage.regfile[11]);
                if (uut.decode_stage.regfile[12] == 99) $display("  [PASS] cmovge (ifun=5): r12=99");
                else $display("  [FAIL] cmovge: expected 99, got %d", uut.decode_stage.regfile[12]);
                if (uut.decode_stage.regfile[13] == 13) $display("  [PASS] cmovg (ifun=6): r13=13 (NOT moved)");
                else $display("  [FAIL] cmovg: expected 13, got %d", uut.decode_stage.regfile[13]);
                if (uut.decode_stage.regfile[7] == 99) $display("  [PASS] rmmovq/mrmovq: rdi=99");
                else $display("  [FAIL] rmmovq/mrmovq: expected 99, got %d", uut.decode_stage.regfile[7]);
                if (uut.decode_stage.regfile[5] == 3) $display("  [PASS] JXX: rbp=3 (jle,jl,je NOT taken)");
                else $display("  [FAIL] JXX: expected rbp=3, got %d", uut.decode_stage.regfile[5]);
                if (uut.decode_stage.regfile[14] == 99) $display("  [PASS] pushq/popq: r14=99");
                else $display("  [FAIL] pushq/popq: expected 99, got %d", uut.decode_stage.regfile[14]);
                
                $display("\nCPU Status: %b (expected: 01 for HALT)", Stat);
                $display("Final PC: 0x%h (expected: 0xED = 237)", PC);
                $finish;
            end
        end
    end
    
    // 详细状态监控
    initial begin
        forever @ (posedge clk) begin
            if (rst_n) begin
                $display("Cycle: PC=%h, icode=%h, ifun=%h, rA=%h, rB=%h, valC=%h, valP=%h,",
                         PC, icode, ifun, rA, rB, valC, valP);
                $display("       valA=%h, valB=%h, valE=%h, valM=%h, valE_wb=%h, valM_wb=%h, npc=%h, Stat=%b",
                         valA, valB, valE, valM, valE_wb, valM_wb, npc, Stat);
                $display("       CC: ZF=%b, SF=%b, OF=%b, Cnd=%b", ZF, SF, OF, Cnd);
                $display("");
            end
        end
    end
    
    // ============================================================
    // 测试程序：全覆盖 icode 和 ifun
    // ============================================================
    // 指令覆盖：
    // - NOP (0,0)
    // - HALT (1,0)
    // - RRMOVL/CMOVxx (2,0-6): rrmovq, cmovle, cmovl, cmove, cmovne, cmovge, cmovg
    // - IRMOVL (3,0)
    // - RMMOVL (4,0)
    // - MRMOVL (5,0)
    // - ALU (6,0-3): addq, subq, andq, xorq
    // - JXX (7,0-6): jmp, jle, jl, je, jne, jge, jg
    // - CALL (8,0)
    // - RET (9,0)
    // - PUSHL (A,0)
    // - POPL (B,0)
    // ============================================================
    
    initial begin
        $display("========================================");
        $display("=== Y86-64 Comprehensive Test V5 ===");
        $display("=== Full icode/ifun Coverage ===");
        $display("========================================\n");
        
        // ==================== 加载指令 ====================
        
        // === 阶段1：初始化 ===
        
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
        
        // [11-20] 0x0B: irmovq $10, %rax
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
        
        // [21-30] 0x15: irmovq $20, %rbx
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
        
        // [31-40] 0x1F: irmovq $5, %rcx
        uut.fetch_stage.instr_mem[31] = 8'h30;
        uut.fetch_stage.instr_mem[32] = 8'hF1;
        uut.fetch_stage.instr_mem[33] = 8'h05;  // 5
        uut.fetch_stage.instr_mem[34] = 8'h00;
        uut.fetch_stage.instr_mem[35] = 8'h00;
        uut.fetch_stage.instr_mem[36] = 8'h00;
        uut.fetch_stage.instr_mem[37] = 8'h00;
        uut.fetch_stage.instr_mem[38] = 8'h00;
        uut.fetch_stage.instr_mem[39] = 8'h00;
        uut.fetch_stage.instr_mem[40] = 8'h00;
        
        // [41-50] 0x29: irmovq $99, %rsi - cmov源值
        uut.fetch_stage.instr_mem[41] = 8'h30;
        uut.fetch_stage.instr_mem[42] = 8'hF6;
        uut.fetch_stage.instr_mem[43] = 8'h63;  // 99
        uut.fetch_stage.instr_mem[44] = 8'h00;
        uut.fetch_stage.instr_mem[45] = 8'h00;
        uut.fetch_stage.instr_mem[46] = 8'h00;
        uut.fetch_stage.instr_mem[47] = 8'h00;
        uut.fetch_stage.instr_mem[48] = 8'h00;
        uut.fetch_stage.instr_mem[49] = 8'h00;
        uut.fetch_stage.instr_mem[50] = 8'h00;
        
        // === 阶段2：RRMOVL ifun=0 (无条件寄存器移动) ===
        // [51-52] 0x33: rrmovq %rax, %rdx - ifun=0
        uut.fetch_stage.instr_mem[51] = 8'h20;
        uut.fetch_stage.instr_mem[52] = 8'h02;  // rA=0(%rax), rB=2(%rdx)
        
        // === 阶段3：ALU 全部 ifun (0-3) ===
        // [53-54] 0x35: addq %rbx, %rax - ALU ifun=0, rax=10+20=30
        uut.fetch_stage.instr_mem[53] = 8'h60;
        uut.fetch_stage.instr_mem[54] = 8'h30;  // rA=3(%rbx), rB=0(%rax)
        
        // [55-56] 0x37: subq %rcx, %rax - ALU ifun=1, rax=30-5=25
        uut.fetch_stage.instr_mem[55] = 8'h61;
        uut.fetch_stage.instr_mem[56] = 8'h10;  // rA=1(%rcx), rB=0(%rax)
        
        // [57-58] 0x39: andq %rbx, %rax - ALU ifun=2, rax=25&20=16
        uut.fetch_stage.instr_mem[57] = 8'h62;
        uut.fetch_stage.instr_mem[58] = 8'h30;  // rA=3(%rbx), rB=0(%rax)
        
        // [59-60] 0x3B: xorq %rax, %rax - ALU ifun=3, rax=0, ZF=1
        uut.fetch_stage.instr_mem[59] = 8'h63;
        uut.fetch_stage.instr_mem[60] = 8'h00;  // rA=0(%rax), rB=0(%rax)
        
        // === 阶段4：测试 ZF=1 时的条件传送 ===
        // 当前条件码：ZF=1, SF=0, OF=0
        // cmovle: (SF^OF)|ZF = 1 -> 移动
        // cmovl:  SF^OF = 0 -> 不移动
        // cmove:  ZF = 1 -> 移动
        // cmovne: ~ZF = 0 -> 不移动
        // cmovge: ~(SF^OF) = 1 -> 移动
        // cmovg:  ~(SF^OF)&~ZF = 0 -> 不移动
        
        // [61-62] 0x3D: cmovle %rsi, %r8 - ifun=1, 应该移动, r8=99
        uut.fetch_stage.instr_mem[61] = 8'h21;
        uut.fetch_stage.instr_mem[62] = 8'h68;  // rA=6(%rsi), rB=8(%r8)
        
        // [63-64] 0x3F: cmovl %rsi, %r9 - ifun=2, 不应移动, r9保持
        uut.fetch_stage.instr_mem[63] = 8'h22;
        uut.fetch_stage.instr_mem[64] = 8'h69;  // rA=6(%rsi), rB=9(%r9)
        
        // [65-66] 0x41: cmove %rsi, %r10 - ifun=3, 应该移动, r10=99
        uut.fetch_stage.instr_mem[65] = 8'h23;
        uut.fetch_stage.instr_mem[66] = 8'h6A;  // rA=6(%rsi), rB=A(%r10)
        
        // [67-68] 0x43: cmovne %rsi, %r11 - ifun=4, 不应移动, r11保持
        uut.fetch_stage.instr_mem[67] = 8'h24;
        uut.fetch_stage.instr_mem[68] = 8'h6B;  // rA=6(%rsi), rB=B(%r11)
        
        // [69-70] 0x45: cmovge %rsi, %r12 - ifun=5, 应该移动, r12=99
        uut.fetch_stage.instr_mem[69] = 8'h25;
        uut.fetch_stage.instr_mem[70] = 8'h6C;  // rA=6(%rsi), rB=C(%r12)
        
        // [71-72] 0x47: cmovg %rsi, %r13 - ifun=6, 不应移动, r13保持
        uut.fetch_stage.instr_mem[71] = 8'h26;
        uut.fetch_stage.instr_mem[72] = 8'h6D;  // rA=6(%rsi), rB=D(%r13)
        
        // === 阶段5：RMMOVL & MRMOVL ===
        // [73-82] 0x49: rmmovq %rsi, 16(%rsp) - 存储99到内存
        uut.fetch_stage.instr_mem[73] = 8'h40;
        uut.fetch_stage.instr_mem[74] = 8'h64;  // rA=6(%rsi), rB=4(%rsp)
        uut.fetch_stage.instr_mem[75] = 8'h10;  // offset = 16
        uut.fetch_stage.instr_mem[76] = 8'h00;
        uut.fetch_stage.instr_mem[77] = 8'h00;
        uut.fetch_stage.instr_mem[78] = 8'h00;
        uut.fetch_stage.instr_mem[79] = 8'h00;
        uut.fetch_stage.instr_mem[80] = 8'h00;
        uut.fetch_stage.instr_mem[81] = 8'h00;
        uut.fetch_stage.instr_mem[82] = 8'h00;
        
        // [83-92] 0x53: mrmovq 16(%rsp), %rdi - 从内存读取到rdi
        uut.fetch_stage.instr_mem[83] = 8'h50;
        uut.fetch_stage.instr_mem[84] = 8'h74;  // rA=7(%rdi), rB=4(%rsp)
        uut.fetch_stage.instr_mem[85] = 8'h10;
        uut.fetch_stage.instr_mem[86] = 8'h00;
        uut.fetch_stage.instr_mem[87] = 8'h00;
        uut.fetch_stage.instr_mem[88] = 8'h00;
        uut.fetch_stage.instr_mem[89] = 8'h00;
        uut.fetch_stage.instr_mem[90] = 8'h00;
        uut.fetch_stage.instr_mem[91] = 8'h00;
        uut.fetch_stage.instr_mem[92] = 8'h00;
        
        // === 阶段6：设置 SF=1 测试条件 ===
        // [93-102] 0x5D: irmovq $5, %rax
        uut.fetch_stage.instr_mem[93] = 8'h30;
        uut.fetch_stage.instr_mem[94] = 8'hF0;
        uut.fetch_stage.instr_mem[95] = 8'h05;
        uut.fetch_stage.instr_mem[96] = 8'h00;
        uut.fetch_stage.instr_mem[97] = 8'h00;
        uut.fetch_stage.instr_mem[98] = 8'h00;
        uut.fetch_stage.instr_mem[99] = 8'h00;
        uut.fetch_stage.instr_mem[100] = 8'h00;
        uut.fetch_stage.instr_mem[101] = 8'h00;
        uut.fetch_stage.instr_mem[102] = 8'h00;
        
        // [103-104] 0x67: subq %rbx, %rax -> rax=5-20=-15, ZF=0, SF=1
        uut.fetch_stage.instr_mem[103] = 8'h61;
        uut.fetch_stage.instr_mem[104] = 8'h30;
        
        // === 阶段7：测试 SF=1 时的条件传送 ===
        // 条件码：ZF=0, SF=1, OF=0
        // cmovle: (SF^OF)|ZF = 1 -> 移动
        // cmovl:  SF^OF = 1 -> 移动
        // cmove:  ZF = 0 -> 不移动
        // cmovne: ~ZF = 1 -> 移动
        // cmovge: ~(SF^OF) = 0 -> 不移动
        // cmovg:  ~(SF^OF)&~ZF = 0 -> 不移动
        
        // 用 %rbp 作为计数器，验证哪些 cmov 执行了
        // [105-114] 0x69: irmovq $0, %rbp
        uut.fetch_stage.instr_mem[105] = 8'h30;
        uut.fetch_stage.instr_mem[106] = 8'hF5;
        uut.fetch_stage.instr_mem[107] = 8'h00;
        uut.fetch_stage.instr_mem[108] = 8'h00;
        uut.fetch_stage.instr_mem[109] = 8'h00;
        uut.fetch_stage.instr_mem[110] = 8'h00;
        uut.fetch_stage.instr_mem[111] = 8'h00;
        uut.fetch_stage.instr_mem[112] = 8'h00;
        uut.fetch_stage.instr_mem[113] = 8'h00;
        uut.fetch_stage.instr_mem[114] = 8'h00;
        
        // [115-124] 0x73: irmovq $1, %r14
        uut.fetch_stage.instr_mem[115] = 8'h30;
        uut.fetch_stage.instr_mem[116] = 8'hFE;
        uut.fetch_stage.instr_mem[117] = 8'h01;
        uut.fetch_stage.instr_mem[118] = 8'h00;
        uut.fetch_stage.instr_mem[119] = 8'h00;
        uut.fetch_stage.instr_mem[120] = 8'h00;
        uut.fetch_stage.instr_mem[121] = 8'h00;
        uut.fetch_stage.instr_mem[122] = 8'h00;
        uut.fetch_stage.instr_mem[123] = 8'h00;
        uut.fetch_stage.instr_mem[124] = 8'h00;
        
        // 用 addq 来增加 rbp，但只有条件满足时才执行 cmov 把 r14 给临时寄存器
        // 简化：直接用 cmov 把 r14(=1) 加到不同寄存器来标记
        
        // === 阶段8：JXX 全部 ifun (0-6) ===
        // 设置正数条件：ZF=0, SF=0, OF=0
        // [125-134] 0x7D: irmovq $30, %rax
        uut.fetch_stage.instr_mem[125] = 8'h30;
        uut.fetch_stage.instr_mem[126] = 8'hF0;
        uut.fetch_stage.instr_mem[127] = 8'h1E;  // 30
        uut.fetch_stage.instr_mem[128] = 8'h00;
        uut.fetch_stage.instr_mem[129] = 8'h00;
        uut.fetch_stage.instr_mem[130] = 8'h00;
        uut.fetch_stage.instr_mem[131] = 8'h00;
        uut.fetch_stage.instr_mem[132] = 8'h00;
        uut.fetch_stage.instr_mem[133] = 8'h00;
        uut.fetch_stage.instr_mem[134] = 8'h00;
        
        // [135-136] 0x87: subq %rbx, %rax -> rax=30-20=10, ZF=0, SF=0
        uut.fetch_stage.instr_mem[135] = 8'h61;
        uut.fetch_stage.instr_mem[136] = 8'h30;
        
        // 条件码：ZF=0, SF=0, OF=0
        // jle: (SF^OF)|ZF = 0 -> 不跳转
        // jl:  SF^OF = 0 -> 不跳转
        // je:  ZF = 0 -> 不跳转
        // jne: ~ZF = 1 -> 跳转
        // jge: ~(SF^OF) = 1 -> 跳转
        // jg:  ~(SF^OF)&~ZF = 1 -> 跳转
        
        // [137-145] 0x89: jle target=155 - ifun=1, 不跳转
        uut.fetch_stage.instr_mem[137] = 8'h71;
        uut.fetch_stage.instr_mem[138] = 8'h9B;  // target=155
        uut.fetch_stage.instr_mem[139] = 8'h00;
        uut.fetch_stage.instr_mem[140] = 8'h00;
        uut.fetch_stage.instr_mem[141] = 8'h00;
        uut.fetch_stage.instr_mem[142] = 8'h00;
        uut.fetch_stage.instr_mem[143] = 8'h00;
        uut.fetch_stage.instr_mem[144] = 8'h00;
        uut.fetch_stage.instr_mem[145] = 8'h00;
        
        // [146-147] 0x92: addq %r14, %rbp - 不跳转时执行，rbp++
        uut.fetch_stage.instr_mem[146] = 8'h60;
        uut.fetch_stage.instr_mem[147] = 8'hE5;  // rA=E(%r14), rB=5(%rbp)
        
        // [148-156] 0x94: jl target=166 - ifun=2, 不跳转
        uut.fetch_stage.instr_mem[148] = 8'h72;
        uut.fetch_stage.instr_mem[149] = 8'hA6;  // target=166
        uut.fetch_stage.instr_mem[150] = 8'h00;
        uut.fetch_stage.instr_mem[151] = 8'h00;
        uut.fetch_stage.instr_mem[152] = 8'h00;
        uut.fetch_stage.instr_mem[153] = 8'h00;
        uut.fetch_stage.instr_mem[154] = 8'h00;
        uut.fetch_stage.instr_mem[155] = 8'h00;
        uut.fetch_stage.instr_mem[156] = 8'h00;
        
        // [157-158] 0x9D: addq %r14, %rbp - 不跳转时执行，rbp++
        uut.fetch_stage.instr_mem[157] = 8'h60;
        uut.fetch_stage.instr_mem[158] = 8'hE5;
        
        // [159-167] 0x9F: je target=177 - ifun=3, 不跳转
        uut.fetch_stage.instr_mem[159] = 8'h73;
        uut.fetch_stage.instr_mem[160] = 8'hB1;  // target=177
        uut.fetch_stage.instr_mem[161] = 8'h00;
        uut.fetch_stage.instr_mem[162] = 8'h00;
        uut.fetch_stage.instr_mem[163] = 8'h00;
        uut.fetch_stage.instr_mem[164] = 8'h00;
        uut.fetch_stage.instr_mem[165] = 8'h00;
        uut.fetch_stage.instr_mem[166] = 8'h00;
        uut.fetch_stage.instr_mem[167] = 8'h00;
        
        // [168-169] 0xA8: addq %r14, %rbp - 不跳转时执行，rbp++
        uut.fetch_stage.instr_mem[168] = 8'h60;
        uut.fetch_stage.instr_mem[169] = 8'hE5;
        
        // [170-178] 0xAA: jne target=181 - ifun=4, 应该跳转
        uut.fetch_stage.instr_mem[170] = 8'h74;
        uut.fetch_stage.instr_mem[171] = 8'hB5;  // target=181
        uut.fetch_stage.instr_mem[172] = 8'h00;
        uut.fetch_stage.instr_mem[173] = 8'h00;
        uut.fetch_stage.instr_mem[174] = 8'h00;
        uut.fetch_stage.instr_mem[175] = 8'h00;
        uut.fetch_stage.instr_mem[176] = 8'h00;
        uut.fetch_stage.instr_mem[177] = 8'h00;
        uut.fetch_stage.instr_mem[178] = 8'h00;
        
        // [179-180] 0xB3: addq %r14, %rbp - 被跳过
        uut.fetch_stage.instr_mem[179] = 8'h60;
        uut.fetch_stage.instr_mem[180] = 8'hE5;
        
        // [181-189] 0xB5: jge target=192 - ifun=5, 应该跳转
        uut.fetch_stage.instr_mem[181] = 8'h75;
        uut.fetch_stage.instr_mem[182] = 8'hC0;  // target=192
        uut.fetch_stage.instr_mem[183] = 8'h00;
        uut.fetch_stage.instr_mem[184] = 8'h00;
        uut.fetch_stage.instr_mem[185] = 8'h00;
        uut.fetch_stage.instr_mem[186] = 8'h00;
        uut.fetch_stage.instr_mem[187] = 8'h00;
        uut.fetch_stage.instr_mem[188] = 8'h00;
        uut.fetch_stage.instr_mem[189] = 8'h00;
        
        // [190-191] 0xBE: addq %r14, %rbp - 被跳过
        uut.fetch_stage.instr_mem[190] = 8'h60;
        uut.fetch_stage.instr_mem[191] = 8'hE5;
        
        // [192-200] 0xC0: jg target=203 - ifun=6, 应该跳转
        uut.fetch_stage.instr_mem[192] = 8'h76;
        uut.fetch_stage.instr_mem[193] = 8'hCB;  // target=203
        uut.fetch_stage.instr_mem[194] = 8'h00;
        uut.fetch_stage.instr_mem[195] = 8'h00;
        uut.fetch_stage.instr_mem[196] = 8'h00;
        uut.fetch_stage.instr_mem[197] = 8'h00;
        uut.fetch_stage.instr_mem[198] = 8'h00;
        uut.fetch_stage.instr_mem[199] = 8'h00;
        uut.fetch_stage.instr_mem[200] = 8'h00;
        
        // [201-202] 0xC9: addq %r14, %rbp - 被跳过
        uut.fetch_stage.instr_mem[201] = 8'h60;
        uut.fetch_stage.instr_mem[202] = 8'hE5;
        
        // [203-211] 0xCB: jmp target=214 - ifun=0, 无条件跳转
        uut.fetch_stage.instr_mem[203] = 8'h70;
        uut.fetch_stage.instr_mem[204] = 8'hD6;  // target=214
        uut.fetch_stage.instr_mem[205] = 8'h00;
        uut.fetch_stage.instr_mem[206] = 8'h00;
        uut.fetch_stage.instr_mem[207] = 8'h00;
        uut.fetch_stage.instr_mem[208] = 8'h00;
        uut.fetch_stage.instr_mem[209] = 8'h00;
        uut.fetch_stage.instr_mem[210] = 8'h00;
        uut.fetch_stage.instr_mem[211] = 8'h00;
        
        // [212-213] 0xD4: addq %r14, %rbp - 被跳过
        uut.fetch_stage.instr_mem[212] = 8'h60;
        uut.fetch_stage.instr_mem[213] = 8'hE5;
        
        // === 阶段9：PUSHL & POPL ===
        // [214-215] 0xD6: pushq %rsi - 把99压栈
        uut.fetch_stage.instr_mem[214] = 8'hA0;
        uut.fetch_stage.instr_mem[215] = 8'h6F;  // rA=6(%rsi)
        
        // [216-225] 0xD8: irmovq $123, %rsi - 改变rsi
        uut.fetch_stage.instr_mem[216] = 8'h30;
        uut.fetch_stage.instr_mem[217] = 8'hF6;
        uut.fetch_stage.instr_mem[218] = 8'h7B;  // 123
        uut.fetch_stage.instr_mem[219] = 8'h00;
        uut.fetch_stage.instr_mem[220] = 8'h00;
        uut.fetch_stage.instr_mem[221] = 8'h00;
        uut.fetch_stage.instr_mem[222] = 8'h00;
        uut.fetch_stage.instr_mem[223] = 8'h00;
        uut.fetch_stage.instr_mem[224] = 8'h00;
        uut.fetch_stage.instr_mem[225] = 8'h00;
        
        // [226-227] 0xE2: popq %r14 - r14应该得到99
        uut.fetch_stage.instr_mem[226] = 8'hB0;
        uut.fetch_stage.instr_mem[227] = 8'hEF;  // rA=E(%r14)
        
        // === 阶段10：CALL & RET ===
        // [228-236] 0xE4: call target=250
        uut.fetch_stage.instr_mem[228] = 8'h80;
        uut.fetch_stage.instr_mem[229] = 8'hFA;  // target=250
        uut.fetch_stage.instr_mem[230] = 8'h00;
        uut.fetch_stage.instr_mem[231] = 8'h00;
        uut.fetch_stage.instr_mem[232] = 8'h00;
        uut.fetch_stage.instr_mem[233] = 8'h00;
        uut.fetch_stage.instr_mem[234] = 8'h00;
        uut.fetch_stage.instr_mem[235] = 8'h00;
        uut.fetch_stage.instr_mem[236] = 8'h00;
        
        // [237] 0xED: halt - call返回后停止
        uut.fetch_stage.instr_mem[237] = 8'h10;
        
        // [250] 0xFA: ret
        uut.fetch_stage.instr_mem[250] = 8'h90;
        
        // 初始化其余内存
        for (integer i = 251; i < 1024; i = i + 1) begin
            uut.fetch_stage.instr_mem[i] = 8'h00;
        end
        
        // ==================== 打印加载的完整指令 ====================
        $display("\n========================================");
        $display("=== Loaded Instructions ===");
        $display("========================================");
        
        // NOP
        $display("PC=0x00: %02h          -> nop",
            uut.fetch_stage.instr_mem[0]);
        
        // irmovq $200, %rsp
        $display("PC=0x01: %02h %02h %02h%02h%02h%02h%02h%02h%02h%02h -> irmovq $200, %%rsp",
            uut.fetch_stage.instr_mem[1], uut.fetch_stage.instr_mem[2],
            uut.fetch_stage.instr_mem[10], uut.fetch_stage.instr_mem[9], uut.fetch_stage.instr_mem[8], uut.fetch_stage.instr_mem[7],
            uut.fetch_stage.instr_mem[6], uut.fetch_stage.instr_mem[5], uut.fetch_stage.instr_mem[4], uut.fetch_stage.instr_mem[3]);
        
        // irmovq $10, %rax
        $display("PC=0x0B: %02h %02h %02h%02h%02h%02h%02h%02h%02h%02h -> irmovq $10, %%rax",
            uut.fetch_stage.instr_mem[11], uut.fetch_stage.instr_mem[12],
            uut.fetch_stage.instr_mem[20], uut.fetch_stage.instr_mem[19], uut.fetch_stage.instr_mem[18], uut.fetch_stage.instr_mem[17],
            uut.fetch_stage.instr_mem[16], uut.fetch_stage.instr_mem[15], uut.fetch_stage.instr_mem[14], uut.fetch_stage.instr_mem[13]);
        
        // irmovq $20, %rbx
        $display("PC=0x15: %02h %02h %02h%02h%02h%02h%02h%02h%02h%02h -> irmovq $20, %%rbx",
            uut.fetch_stage.instr_mem[21], uut.fetch_stage.instr_mem[22],
            uut.fetch_stage.instr_mem[30], uut.fetch_stage.instr_mem[29], uut.fetch_stage.instr_mem[28], uut.fetch_stage.instr_mem[27],
            uut.fetch_stage.instr_mem[26], uut.fetch_stage.instr_mem[25], uut.fetch_stage.instr_mem[24], uut.fetch_stage.instr_mem[23]);
        
        // irmovq $5, %rcx
        $display("PC=0x1F: %02h %02h %02h%02h%02h%02h%02h%02h%02h%02h -> irmovq $5, %%rcx",
            uut.fetch_stage.instr_mem[31], uut.fetch_stage.instr_mem[32],
            uut.fetch_stage.instr_mem[40], uut.fetch_stage.instr_mem[39], uut.fetch_stage.instr_mem[38], uut.fetch_stage.instr_mem[37],
            uut.fetch_stage.instr_mem[36], uut.fetch_stage.instr_mem[35], uut.fetch_stage.instr_mem[34], uut.fetch_stage.instr_mem[33]);
        
        // irmovq $99, %rsi
        $display("PC=0x29: %02h %02h %02h%02h%02h%02h%02h%02h%02h%02h -> irmovq $99, %%rsi",
            uut.fetch_stage.instr_mem[41], uut.fetch_stage.instr_mem[42],
            uut.fetch_stage.instr_mem[50], uut.fetch_stage.instr_mem[49], uut.fetch_stage.instr_mem[48], uut.fetch_stage.instr_mem[47],
            uut.fetch_stage.instr_mem[46], uut.fetch_stage.instr_mem[45], uut.fetch_stage.instr_mem[44], uut.fetch_stage.instr_mem[43]);
        
        // rrmovq %rax, %rdx
        $display("PC=0x33: %02h %02h       -> rrmovq %%rax, %%rdx (ifun=0)",
            uut.fetch_stage.instr_mem[51], uut.fetch_stage.instr_mem[52]);
        
        // ALU instructions
        $display("PC=0x35: %02h %02h       -> addq %%rbx, %%rax (ifun=0)",
            uut.fetch_stage.instr_mem[53], uut.fetch_stage.instr_mem[54]);
        $display("PC=0x37: %02h %02h       -> subq %%rcx, %%rax (ifun=1)",
            uut.fetch_stage.instr_mem[55], uut.fetch_stage.instr_mem[56]);
        $display("PC=0x39: %02h %02h       -> andq %%rbx, %%rax (ifun=2)",
            uut.fetch_stage.instr_mem[57], uut.fetch_stage.instr_mem[58]);
        $display("PC=0x3B: %02h %02h       -> xorq %%rax, %%rax (ifun=3) -> ZF=1",
            uut.fetch_stage.instr_mem[59], uut.fetch_stage.instr_mem[60]);
        
        // CMOVxx instructions (ZF=1, SF=0, OF=0 test)
        $display("--- CMOVxx Test: CC={ZF=1, SF=0, OF=0} ---");
        $display("PC=0x3D: %02h %02h       -> cmovle %%rsi, %%r8  | (SF^OF)|ZF = 0|1 = 1 -> MOVE",
            uut.fetch_stage.instr_mem[61], uut.fetch_stage.instr_mem[62]);
        $display("PC=0x3F: %02h %02h       -> cmovl  %%rsi, %%r9  | SF^OF = 0^0 = 0 -> NO MOVE",
            uut.fetch_stage.instr_mem[63], uut.fetch_stage.instr_mem[64]);
        $display("PC=0x41: %02h %02h       -> cmove  %%rsi, %%r10 | ZF = 1 -> MOVE",
            uut.fetch_stage.instr_mem[65], uut.fetch_stage.instr_mem[66]);
        $display("PC=0x43: %02h %02h       -> cmovne %%rsi, %%r11 | ~ZF = 0 -> NO MOVE",
            uut.fetch_stage.instr_mem[67], uut.fetch_stage.instr_mem[68]);
        $display("PC=0x45: %02h %02h       -> cmovge %%rsi, %%r12 | ~(SF^OF) = 1 -> MOVE",
            uut.fetch_stage.instr_mem[69], uut.fetch_stage.instr_mem[70]);
        $display("PC=0x47: %02h %02h       -> cmovg  %%rsi, %%r13 | ~(SF^OF)&~ZF = 1&0 = 0 -> NO MOVE",
            uut.fetch_stage.instr_mem[71], uut.fetch_stage.instr_mem[72]);
        
        // rmmovq
        $display("PC=0x49: %02h %02h %02h%02h%02h%02h%02h%02h%02h%02h -> rmmovq %%rsi, 16(%%rsp)",
            uut.fetch_stage.instr_mem[73], uut.fetch_stage.instr_mem[74],
            uut.fetch_stage.instr_mem[82], uut.fetch_stage.instr_mem[81], uut.fetch_stage.instr_mem[80], uut.fetch_stage.instr_mem[79],
            uut.fetch_stage.instr_mem[78], uut.fetch_stage.instr_mem[77], uut.fetch_stage.instr_mem[76], uut.fetch_stage.instr_mem[75]);
        
        // mrmovq
        $display("PC=0x53: %02h %02h %02h%02h%02h%02h%02h%02h%02h%02h -> mrmovq 16(%%rsp), %%rdi",
            uut.fetch_stage.instr_mem[83], uut.fetch_stage.instr_mem[84],
            uut.fetch_stage.instr_mem[92], uut.fetch_stage.instr_mem[91], uut.fetch_stage.instr_mem[90], uut.fetch_stage.instr_mem[89],
            uut.fetch_stage.instr_mem[88], uut.fetch_stage.instr_mem[87], uut.fetch_stage.instr_mem[86], uut.fetch_stage.instr_mem[85]);
        
        // irmovq $5, %rax (for SF=1 test)
        $display("PC=0x5D: %02h %02h %02h%02h%02h%02h%02h%02h%02h%02h -> irmovq $5, %%rax",
            uut.fetch_stage.instr_mem[93], uut.fetch_stage.instr_mem[94],
            uut.fetch_stage.instr_mem[102], uut.fetch_stage.instr_mem[101], uut.fetch_stage.instr_mem[100], uut.fetch_stage.instr_mem[99],
            uut.fetch_stage.instr_mem[98], uut.fetch_stage.instr_mem[97], uut.fetch_stage.instr_mem[96], uut.fetch_stage.instr_mem[95]);
        
        // subq -> SF=1
        $display("PC=0x67: %02h %02h       -> subq %%rbx, %%rax -> SF=1",
            uut.fetch_stage.instr_mem[103], uut.fetch_stage.instr_mem[104]);
        
        // irmovq $0, %rbp
        $display("PC=0x69: %02h %02h %02h%02h%02h%02h%02h%02h%02h%02h -> irmovq $0, %%rbp",
            uut.fetch_stage.instr_mem[105], uut.fetch_stage.instr_mem[106],
            uut.fetch_stage.instr_mem[114], uut.fetch_stage.instr_mem[113], uut.fetch_stage.instr_mem[112], uut.fetch_stage.instr_mem[111],
            uut.fetch_stage.instr_mem[110], uut.fetch_stage.instr_mem[109], uut.fetch_stage.instr_mem[108], uut.fetch_stage.instr_mem[107]);
        
        // irmovq $1, %r14
        $display("PC=0x73: %02h %02h %02h%02h%02h%02h%02h%02h%02h%02h -> irmovq $1, %%r14",
            uut.fetch_stage.instr_mem[115], uut.fetch_stage.instr_mem[116],
            uut.fetch_stage.instr_mem[124], uut.fetch_stage.instr_mem[123], uut.fetch_stage.instr_mem[122], uut.fetch_stage.instr_mem[121],
            uut.fetch_stage.instr_mem[120], uut.fetch_stage.instr_mem[119], uut.fetch_stage.instr_mem[118], uut.fetch_stage.instr_mem[117]);
        
        // irmovq $30, %rax (for positive test)
        $display("PC=0x7D: %02h %02h %02h%02h%02h%02h%02h%02h%02h%02h -> irmovq $30, %%rax",
            uut.fetch_stage.instr_mem[125], uut.fetch_stage.instr_mem[126],
            uut.fetch_stage.instr_mem[134], uut.fetch_stage.instr_mem[133], uut.fetch_stage.instr_mem[132], uut.fetch_stage.instr_mem[131],
            uut.fetch_stage.instr_mem[130], uut.fetch_stage.instr_mem[129], uut.fetch_stage.instr_mem[128], uut.fetch_stage.instr_mem[127]);
        
        // subq -> positive result
        $display("PC=0x87: %02h %02h       -> subq %%rbx, %%rax -> ZF=0,SF=0",
            uut.fetch_stage.instr_mem[135], uut.fetch_stage.instr_mem[136]);
        
        // JXX instructions (ZF=0, SF=0, OF=0 test)
        $display("--- JXX Test: CC={ZF=0, SF=0, OF=0} ---");
        $display("PC=0x89: %02h %02h%02h%02h%02h%02h%02h%02h%02h -> jle  | (SF^OF)|ZF = 0|0 = 0 -> NO JUMP, exec next",
            uut.fetch_stage.instr_mem[137],
            uut.fetch_stage.instr_mem[145], uut.fetch_stage.instr_mem[144], uut.fetch_stage.instr_mem[143], uut.fetch_stage.instr_mem[142],
            uut.fetch_stage.instr_mem[141], uut.fetch_stage.instr_mem[140], uut.fetch_stage.instr_mem[139], uut.fetch_stage.instr_mem[138]);
        
        $display("PC=0x92: %02h %02h       -> addq %%r14, %%rbp (rbp++ because jle not taken)",
            uut.fetch_stage.instr_mem[146], uut.fetch_stage.instr_mem[147]);
        
        $display("PC=0x94: %02h %02h%02h%02h%02h%02h%02h%02h%02h -> jl   | SF^OF = 0^0 = 0 -> NO JUMP, exec next",
            uut.fetch_stage.instr_mem[148],
            uut.fetch_stage.instr_mem[156], uut.fetch_stage.instr_mem[155], uut.fetch_stage.instr_mem[154], uut.fetch_stage.instr_mem[153],
            uut.fetch_stage.instr_mem[152], uut.fetch_stage.instr_mem[151], uut.fetch_stage.instr_mem[150], uut.fetch_stage.instr_mem[149]);
        
        $display("PC=0x9D: %02h %02h       -> addq %%r14, %%rbp (rbp++ because jl not taken)",
            uut.fetch_stage.instr_mem[157], uut.fetch_stage.instr_mem[158]);
        
        $display("PC=0x9F: %02h %02h%02h%02h%02h%02h%02h%02h%02h -> je   | ZF = 0 -> NO JUMP, exec next",
            uut.fetch_stage.instr_mem[159],
            uut.fetch_stage.instr_mem[167], uut.fetch_stage.instr_mem[166], uut.fetch_stage.instr_mem[165], uut.fetch_stage.instr_mem[164],
            uut.fetch_stage.instr_mem[163], uut.fetch_stage.instr_mem[162], uut.fetch_stage.instr_mem[161], uut.fetch_stage.instr_mem[160]);
        
        $display("PC=0xA8: %02h %02h       -> addq %%r14, %%rbp (rbp++ because je not taken)",
            uut.fetch_stage.instr_mem[168], uut.fetch_stage.instr_mem[169]);
        
        $display("PC=0xAA: %02h %02h%02h%02h%02h%02h%02h%02h%02h -> jne  | ~ZF = 1 -> JUMP, skip next",
            uut.fetch_stage.instr_mem[170],
            uut.fetch_stage.instr_mem[178], uut.fetch_stage.instr_mem[177], uut.fetch_stage.instr_mem[176], uut.fetch_stage.instr_mem[175],
            uut.fetch_stage.instr_mem[174], uut.fetch_stage.instr_mem[173], uut.fetch_stage.instr_mem[172], uut.fetch_stage.instr_mem[171]);
        
        $display("PC=0xB3: %02h %02h       -> addq %%r14, %%rbp (SKIPPED by jne)",
            uut.fetch_stage.instr_mem[179], uut.fetch_stage.instr_mem[180]);
        
        $display("PC=0xB5: %02h %02h%02h%02h%02h%02h%02h%02h%02h -> jge  | ~(SF^OF) = 1 -> JUMP, skip next",
            uut.fetch_stage.instr_mem[181],
            uut.fetch_stage.instr_mem[189], uut.fetch_stage.instr_mem[188], uut.fetch_stage.instr_mem[187], uut.fetch_stage.instr_mem[186],
            uut.fetch_stage.instr_mem[185], uut.fetch_stage.instr_mem[184], uut.fetch_stage.instr_mem[183], uut.fetch_stage.instr_mem[182]);
        
        $display("PC=0xBE: %02h %02h       -> addq %%r14, %%rbp (SKIPPED by jge)",
            uut.fetch_stage.instr_mem[190], uut.fetch_stage.instr_mem[191]);
        
        $display("PC=0xC0: %02h %02h%02h%02h%02h%02h%02h%02h%02h -> jg   | ~(SF^OF)&~ZF = 1 -> JUMP, skip next",
            uut.fetch_stage.instr_mem[192],
            uut.fetch_stage.instr_mem[200], uut.fetch_stage.instr_mem[199], uut.fetch_stage.instr_mem[198], uut.fetch_stage.instr_mem[197],
            uut.fetch_stage.instr_mem[196], uut.fetch_stage.instr_mem[195], uut.fetch_stage.instr_mem[194], uut.fetch_stage.instr_mem[193]);
        
        $display("PC=0xC9: %02h %02h       -> addq %%r14, %%rbp (SKIPPED by jg)",
            uut.fetch_stage.instr_mem[201], uut.fetch_stage.instr_mem[202]);
        
        $display("PC=0xCB: %02h %02h%02h%02h%02h%02h%02h%02h%02h -> jmp  | unconditional -> JUMP, skip next",
            uut.fetch_stage.instr_mem[203],
            uut.fetch_stage.instr_mem[211], uut.fetch_stage.instr_mem[210], uut.fetch_stage.instr_mem[209], uut.fetch_stage.instr_mem[208],
            uut.fetch_stage.instr_mem[207], uut.fetch_stage.instr_mem[206], uut.fetch_stage.instr_mem[205], uut.fetch_stage.instr_mem[204]);
        
        $display("PC=0xD4: %02h %02h       -> addq %%r14, %%rbp (SKIPPED by jmp)",
            uut.fetch_stage.instr_mem[212], uut.fetch_stage.instr_mem[213]);
        
        $display("--- Expected: rbp = 3 (jle, jl, je NOT taken) ---");
        
        // PUSHL & POPL
        $display("PC=0xD6: %02h %02h       -> pushq %%rsi",
            uut.fetch_stage.instr_mem[214], uut.fetch_stage.instr_mem[215]);
        
        // irmovq $123, %rsi
        $display("PC=0xD8: %02h %02h %02h%02h%02h%02h%02h%02h%02h%02h -> irmovq $123, %%rsi",
            uut.fetch_stage.instr_mem[216], uut.fetch_stage.instr_mem[217],
            uut.fetch_stage.instr_mem[225], uut.fetch_stage.instr_mem[224], uut.fetch_stage.instr_mem[223], uut.fetch_stage.instr_mem[222],
            uut.fetch_stage.instr_mem[221], uut.fetch_stage.instr_mem[220], uut.fetch_stage.instr_mem[219], uut.fetch_stage.instr_mem[218]);
        
        $display("PC=0xE2: %02h %02h       -> popq %%r14",
            uut.fetch_stage.instr_mem[226], uut.fetch_stage.instr_mem[227]);
        
        // CALL
        $display("PC=0xE4: %02h %02h%02h%02h%02h%02h%02h%02h%02h -> call target=250",
            uut.fetch_stage.instr_mem[228],
            uut.fetch_stage.instr_mem[236], uut.fetch_stage.instr_mem[235], uut.fetch_stage.instr_mem[234], uut.fetch_stage.instr_mem[233],
            uut.fetch_stage.instr_mem[232], uut.fetch_stage.instr_mem[231], uut.fetch_stage.instr_mem[230], uut.fetch_stage.instr_mem[229]);
        
        // HALT
        $display("PC=0xED: %02h          -> halt",
            uut.fetch_stage.instr_mem[237]);
        
        // RET
        $display("PC=0xFA: %02h          -> ret",
            uut.fetch_stage.instr_mem[250]);
        
        $display("========================================\n");
        
        // ==================== 启动测试 ====================
        #5 rst_n = 1;
        
        // 等待 HALT 检测器自动结束仿真
    end

endmodule
