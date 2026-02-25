`timescale 1ps/1ps

// Y86-64 流水线CPU全覆盖测试
// 基于 y86_cpu_comprehensive_tb_v6.v 改写
// 覆盖所有 icode 和 ifun 组合

module pipelined_y86_comprehensive_tb();

    reg clk;
    reg rst_n;
    wire [1:0] Stat;
    
    // 实例化流水线 CPU
    pipelined_y86_cpu cpu(
        .clk_i(clk),
        .rst_n_i(rst_n),
        .cpu_stat_o(Stat)
    );
    
    // 内部信号监控
    wire [63:0] PC = cpu.f_pc;
    wire [3:0] f_icode = cpu.f_icode;
    wire [3:0] D_icode = cpu.D_icode;
    wire [3:0] E_icode = cpu.E_icode;
    wire [3:0] M_icode = cpu.M_icode;
    wire [3:0] W_icode = cpu.W_icode;
    
    // 初始化
    initial begin
        clk = 0;
        rst_n = 0;
    end
    
    // 时钟生成 (100ps 周期)
    always #50 clk = ~clk;
    
    // 超时控制
    initial begin
        #500000 begin
            $display("\n========================================");
            $display("=== Test TIMEOUT ===");
            $display("PC: 0x%h", PC);
            $display("========================================");
            $stop;
        end
    end
    
    // HALT 检测 - 检测到 HALT 后等待流水线排空
    initial begin
        wait(rst_n == 1);
        wait(Stat == 2'b01);  // HLT status
        #1000;  // 等待流水线完全排空
        
        $display("\n========================================");
        $display("=== Test Complete ===");
        $display("========================================");
        
        $display("\n=== 寄存器状态 ===");
        $display("  %%rax = %d", cpu.decode_stage.reg_file[0]);
        $display("  %%rcx = %d", cpu.decode_stage.reg_file[1]);
        $display("  %%rdx = %d (should be 10, from rrmovq)", cpu.decode_stage.reg_file[2]);
        $display("  %%rbx = %d", cpu.decode_stage.reg_file[3]);
        $display("  %%rsp = %d", cpu.decode_stage.reg_file[4]);
        $display("  %%rbp = %d (should be 3, count of NOT-taken jumps)", cpu.decode_stage.reg_file[5]);
        $display("  %%rsi = %d (should be 123)", cpu.decode_stage.reg_file[6]);
        $display("  %%rdi = %d (should be 99, from mrmovq)", cpu.decode_stage.reg_file[7]);
        $display("  %%r8  = %d (should be 99, cmovle MOVED)", cpu.decode_stage.reg_file[8]);
        $display("  %%r9  = %d (should be 0x109=265, cmovl NOT moved)", cpu.decode_stage.reg_file[9]);
        $display("  %%r10 = %d (should be 99, cmove MOVED)", cpu.decode_stage.reg_file[10]);
        $display("  %%r11 = %d (should be 0x10B=267, cmovne NOT moved)", cpu.decode_stage.reg_file[11]);
        $display("  %%r12 = %d (should be 99, cmovge MOVED)", cpu.decode_stage.reg_file[12]);
        $display("  %%r13 = %d (should be 0x10D=269, cmovg NOT moved)", cpu.decode_stage.reg_file[13]);
        $display("  %%r14 = %d (should be 99, from popq)", cpu.decode_stage.reg_file[14]);
        
        $display("\n=== 验证结果 ===");
        if (cpu.decode_stage.reg_file[2] == 10) $display("  [PASS] rrmovq: rdx=10");
        else $display("  [FAIL] rrmovq: expected 10, got %d", cpu.decode_stage.reg_file[2]);
        
        if (cpu.decode_stage.reg_file[8] == 99) $display("  [PASS] cmovle (ifun=1): r8=99 (MOVED)");
        else $display("  [FAIL] cmovle: expected 99, got %d", cpu.decode_stage.reg_file[8]);
        
        if (cpu.decode_stage.reg_file[9] == 265) $display("  [PASS] cmovl (ifun=2): r9=265 (NOT moved)");
        else $display("  [FAIL] cmovl: expected 265 (0x109), got %d", cpu.decode_stage.reg_file[9]);
        
        if (cpu.decode_stage.reg_file[10] == 99) $display("  [PASS] cmove (ifun=3): r10=99 (MOVED)");
        else $display("  [FAIL] cmove: expected 99, got %d", cpu.decode_stage.reg_file[10]);
        
        if (cpu.decode_stage.reg_file[11] == 267) $display("  [PASS] cmovne (ifun=4): r11=267 (NOT moved)");
        else $display("  [FAIL] cmovne: expected 267 (0x10B), got %d", cpu.decode_stage.reg_file[11]);
        
        if (cpu.decode_stage.reg_file[12] == 99) $display("  [PASS] cmovge (ifun=5): r12=99 (MOVED)");
        else $display("  [FAIL] cmovge: expected 99, got %d", cpu.decode_stage.reg_file[12]);
        
        if (cpu.decode_stage.reg_file[13] == 269) $display("  [PASS] cmovg (ifun=6): r13=269 (NOT moved)");
        else $display("  [FAIL] cmovg: expected 269 (0x10D), got %d", cpu.decode_stage.reg_file[13]);
        
        if (cpu.decode_stage.reg_file[7] == 99) $display("  [PASS] rmmovq/mrmovq: rdi=99");
        else $display("  [FAIL] rmmovq/mrmovq: expected 99, got %d", cpu.decode_stage.reg_file[7]);
        
        if (cpu.decode_stage.reg_file[5] == 3) $display("  [PASS] JXX: rbp=3 (jle,jl,je NOT taken)");
        else $display("  [FAIL] JXX: expected rbp=3, got %d", cpu.decode_stage.reg_file[5]);
        
        if (cpu.decode_stage.reg_file[14] == 99) $display("  [PASS] pushq/popq: r14=99");
        else $display("  [FAIL] pushq/popq: expected 99, got %d", cpu.decode_stage.reg_file[14]);
        
        $display("\nCPU Status: %b (expected: 01 for HALT)", Stat);
        $display("Final PC: 0x%h", PC);
        $finish;
    end
    
    // ============================================================
    // 测试程序加载
    // ============================================================
    
    integer i;
    
    initial begin
        $display("========================================");
        $display("=== Y86-64 Pipelined CPU Comprehensive Test ===");
        $display("========================================\n");
        
        // 初始化指令内存为全0
        for (i = 0; i < 1024; i = i + 1) begin
            cpu.fetch_stage.imem[i] = 8'h00;
        end
        
        // ==================== 加载指令 ====================
        
        // === 阶段1：初始化所有寄存器 ===
        
        // [0] 0x00: NOP
        cpu.fetch_stage.imem[0] = 8'h00;
        
        // [1-10] 0x01: irmovq $200, %rsp
        cpu.fetch_stage.imem[1] = 8'h30;
        cpu.fetch_stage.imem[2] = 8'hF4;
        cpu.fetch_stage.imem[3] = 8'hC8;  // 200
        cpu.fetch_stage.imem[4] = 8'h00;
        cpu.fetch_stage.imem[5] = 8'h00;
        cpu.fetch_stage.imem[6] = 8'h00;
        cpu.fetch_stage.imem[7] = 8'h00;
        cpu.fetch_stage.imem[8] = 8'h00;
        cpu.fetch_stage.imem[9] = 8'h00;
        cpu.fetch_stage.imem[10] = 8'h00;
        
        // [11-20] 0x0B: irmovq $10, %rax
        cpu.fetch_stage.imem[11] = 8'h30;
        cpu.fetch_stage.imem[12] = 8'hF0;
        cpu.fetch_stage.imem[13] = 8'h0A;  // 10
        cpu.fetch_stage.imem[14] = 8'h00;
        cpu.fetch_stage.imem[15] = 8'h00;
        cpu.fetch_stage.imem[16] = 8'h00;
        cpu.fetch_stage.imem[17] = 8'h00;
        cpu.fetch_stage.imem[18] = 8'h00;
        cpu.fetch_stage.imem[19] = 8'h00;
        cpu.fetch_stage.imem[20] = 8'h00;
        
        // [21-30] 0x15: irmovq $20, %rbx
        cpu.fetch_stage.imem[21] = 8'h30;
        cpu.fetch_stage.imem[22] = 8'hF3;
        cpu.fetch_stage.imem[23] = 8'h14;  // 20
        cpu.fetch_stage.imem[24] = 8'h00;
        cpu.fetch_stage.imem[25] = 8'h00;
        cpu.fetch_stage.imem[26] = 8'h00;
        cpu.fetch_stage.imem[27] = 8'h00;
        cpu.fetch_stage.imem[28] = 8'h00;
        cpu.fetch_stage.imem[29] = 8'h00;
        cpu.fetch_stage.imem[30] = 8'h00;
        
        // [31-40] 0x1F: irmovq $5, %rcx
        cpu.fetch_stage.imem[31] = 8'h30;
        cpu.fetch_stage.imem[32] = 8'hF1;
        cpu.fetch_stage.imem[33] = 8'h05;  // 5
        cpu.fetch_stage.imem[34] = 8'h00;
        cpu.fetch_stage.imem[35] = 8'h00;
        cpu.fetch_stage.imem[36] = 8'h00;
        cpu.fetch_stage.imem[37] = 8'h00;
        cpu.fetch_stage.imem[38] = 8'h00;
        cpu.fetch_stage.imem[39] = 8'h00;
        cpu.fetch_stage.imem[40] = 8'h00;
        
        // [41-50] 0x29: irmovq $99, %rsi - cmov源值
        cpu.fetch_stage.imem[41] = 8'h30;
        cpu.fetch_stage.imem[42] = 8'hF6;
        cpu.fetch_stage.imem[43] = 8'h63;  // 99
        cpu.fetch_stage.imem[44] = 8'h00;
        cpu.fetch_stage.imem[45] = 8'h00;
        cpu.fetch_stage.imem[46] = 8'h00;
        cpu.fetch_stage.imem[47] = 8'h00;
        cpu.fetch_stage.imem[48] = 8'h00;
        cpu.fetch_stage.imem[49] = 8'h00;
        cpu.fetch_stage.imem[50] = 8'h00;
        
        // [51-60] 0x33: irmovq $0x108, %r8 (264)
        cpu.fetch_stage.imem[51] = 8'h30;
        cpu.fetch_stage.imem[52] = 8'hF8;
        cpu.fetch_stage.imem[53] = 8'h08;
        cpu.fetch_stage.imem[54] = 8'h01;
        cpu.fetch_stage.imem[55] = 8'h00;
        cpu.fetch_stage.imem[56] = 8'h00;
        cpu.fetch_stage.imem[57] = 8'h00;
        cpu.fetch_stage.imem[58] = 8'h00;
        cpu.fetch_stage.imem[59] = 8'h00;
        cpu.fetch_stage.imem[60] = 8'h00;
        
        // [61-70] 0x3D: irmovq $0x109, %r9 (265)
        cpu.fetch_stage.imem[61] = 8'h30;
        cpu.fetch_stage.imem[62] = 8'hF9;
        cpu.fetch_stage.imem[63] = 8'h09;
        cpu.fetch_stage.imem[64] = 8'h01;
        cpu.fetch_stage.imem[65] = 8'h00;
        cpu.fetch_stage.imem[66] = 8'h00;
        cpu.fetch_stage.imem[67] = 8'h00;
        cpu.fetch_stage.imem[68] = 8'h00;
        cpu.fetch_stage.imem[69] = 8'h00;
        cpu.fetch_stage.imem[70] = 8'h00;
        
        // [71-80] 0x47: irmovq $0x10A, %r10 (266)
        cpu.fetch_stage.imem[71] = 8'h30;
        cpu.fetch_stage.imem[72] = 8'hFA;
        cpu.fetch_stage.imem[73] = 8'h0A;
        cpu.fetch_stage.imem[74] = 8'h01;
        cpu.fetch_stage.imem[75] = 8'h00;
        cpu.fetch_stage.imem[76] = 8'h00;
        cpu.fetch_stage.imem[77] = 8'h00;
        cpu.fetch_stage.imem[78] = 8'h00;
        cpu.fetch_stage.imem[79] = 8'h00;
        cpu.fetch_stage.imem[80] = 8'h00;
        
        // [81-90] 0x51: irmovq $0x10B, %r11 (267)
        cpu.fetch_stage.imem[81] = 8'h30;
        cpu.fetch_stage.imem[82] = 8'hFB;
        cpu.fetch_stage.imem[83] = 8'h0B;
        cpu.fetch_stage.imem[84] = 8'h01;
        cpu.fetch_stage.imem[85] = 8'h00;
        cpu.fetch_stage.imem[86] = 8'h00;
        cpu.fetch_stage.imem[87] = 8'h00;
        cpu.fetch_stage.imem[88] = 8'h00;
        cpu.fetch_stage.imem[89] = 8'h00;
        cpu.fetch_stage.imem[90] = 8'h00;
        
        // [91-100] 0x5B: irmovq $0x10C, %r12 (268)
        cpu.fetch_stage.imem[91] = 8'h30;
        cpu.fetch_stage.imem[92] = 8'hFC;
        cpu.fetch_stage.imem[93] = 8'h0C;
        cpu.fetch_stage.imem[94] = 8'h01;
        cpu.fetch_stage.imem[95] = 8'h00;
        cpu.fetch_stage.imem[96] = 8'h00;
        cpu.fetch_stage.imem[97] = 8'h00;
        cpu.fetch_stage.imem[98] = 8'h00;
        cpu.fetch_stage.imem[5] = 8'h00;
        cpu.fetch_stage.imem[6] = 8'h00;
        cpu.fetch_stage.imem[7] = 8'h00;
        cpu.fetch_stage.imem[8] = 8'h00;
        cpu.fetch_stage.imem[9] = 8'h00;
        cpu.fetch_stage.imem[10] = 8'h00;
        
        // [11-20] 0x0B: irmovq $10, %rax
        cpu.fetch_stage.imem[11] = 8'h30;
        cpu.fetch_stage.imem[12] = 8'hF0;
        cpu.fetch_stage.imem[13] = 8'h0A;  // 10
        cpu.fetch_stage.imem[14] = 8'h00;
        cpu.fetch_stage.imem[15] = 8'h00;
        cpu.fetch_stage.imem[16] = 8'h00;
        cpu.fetch_stage.imem[17] = 8'h00;
        cpu.fetch_stage.imem[18] = 8'h00;
        cpu.fetch_stage.imem[19] = 8'h00;
        cpu.fetch_stage.imem[20] = 8'h00;
        
        // [21-30] 0x15: irmovq $20, %rbx
        cpu.fetch_stage.imem[21] = 8'h30;
        cpu.fetch_stage.imem[22] = 8'hF3;
        cpu.fetch_stage.imem[23] = 8'h14;  // 20
        cpu.fetch_stage.imem[24] = 8'h00;
        cpu.fetch_stage.imem[25] = 8'h00;
        cpu.fetch_stage.imem[26] = 8'h00;
        cpu.fetch_stage.imem[27] = 8'h00;
        cpu.fetch_stage.imem[28] = 8'h00;
        cpu.fetch_stage.imem[29] = 8'h00;
        cpu.fetch_stage.imem[30] = 8'h00;
        
        // [31-40] 0x1F: irmovq $5, %rcx
        cpu.fetch_stage.imem[31] = 8'h30;
        cpu.fetch_stage.imem[32] = 8'hF1;
        cpu.fetch_stage.imem[33] = 8'h05;  // 5
        cpu.fetch_stage.imem[34] = 8'h00;
        cpu.fetch_stage.imem[35] = 8'h00;
        cpu.fetch_stage.imem[36] = 8'h00;
        cpu.fetch_stage.imem[37] = 8'h00;
        cpu.fetch_stage.imem[38] = 8'h00;
        cpu.fetch_stage.imem[39] = 8'h00;
        cpu.fetch_stage.imem[40] = 8'h00;
        
        // [41-50] 0x29: irmovq $99, %rsi - cmov源值
        cpu.fetch_stage.imem[41] = 8'h30;
        cpu.fetch_stage.imem[42] = 8'hF6;
        cpu.fetch_stage.imem[43] = 8'h63;  // 99
        cpu.fetch_stage.imem[44] = 8'h00;
        cpu.fetch_stage.imem[45] = 8'h00;
        cpu.fetch_stage.imem[46] = 8'h00;
        cpu.fetch_stage.imem[47] = 8'h00;
        cpu.fetch_stage.imem[48] = 8'h00;
        cpu.fetch_stage.imem[49] = 8'h00;
        cpu.fetch_stage.imem[50] = 8'h00;
        
        // [51-60] 0x33: irmovq $0x108, %r8 (264)
        cpu.fetch_stage.imem[51] = 8'h30;
        cpu.fetch_stage.imem[52] = 8'hF8;
        cpu.fetch_stage.imem[53] = 8'h08;
        cpu.fetch_stage.imem[54] = 8'h01;
        cpu.fetch_stage.imem[55] = 8'h00;
        cpu.fetch_stage.imem[56] = 8'h00;
        cpu.fetch_stage.imem[57] = 8'h00;
        cpu.fetch_stage.imem[58] = 8'h00;
        cpu.fetch_stage.imem[59] = 8'h00;
        cpu.fetch_stage.imem[60] = 8'h00;
        
        // [61-70] 0x3D: irmovq $0x109, %r9 (265)
        cpu.fetch_stage.imem[61] = 8'h30;
        cpu.fetch_stage.imem[62] = 8'hF9;
        cpu.fetch_stage.imem[63] = 8'h09;
        cpu.fetch_stage.imem[64] = 8'h01;
        cpu.fetch_stage.imem[65] = 8'h00;
        cpu.fetch_stage.imem[66] = 8'h00;
        cpu.fetch_stage.imem[67] = 8'h00;
        cpu.fetch_stage.imem[68] = 8'h00;
        cpu.fetch_stage.imem[69] = 8'h00;
        cpu.fetch_stage.imem[70] = 8'h00;
        
        // [71-80] 0x47: irmovq $0x10A, %r10 (266)
        cpu.fetch_stage.imem[71] = 8'h30;
        cpu.fetch_stage.imem[72] = 8'hFA;
        cpu.fetch_stage.imem[73] = 8'h0A;
        cpu.fetch_stage.imem[74] = 8'h01;
        cpu.fetch_stage.imem[75] = 8'h00;
        cpu.fetch_stage.imem[76] = 8'h00;
        cpu.fetch_stage.imem[77] = 8'h00;
        cpu.fetch_stage.imem[78] = 8'h00;
        cpu.fetch_stage.imem[79] = 8'h00;
        cpu.fetch_stage.imem[80] = 8'h00;
        
        // [81-90] 0x51: irmovq $0x10B, %r11 (267)
        cpu.fetch_stage.imem[81] = 8'h30;
        cpu.fetch_stage.imem[82] = 8'hFB;
        cpu.fetch_stage.imem[83] = 8'h0B;
        cpu.fetch_stage.imem[84] = 8'h01;
        cpu.fetch_stage.imem[85] = 8'h00;
        cpu.fetch_stage.imem[86] = 8'h00;
        cpu.fetch_stage.imem[87] = 8'h00;
        cpu.fetch_stage.imem[88] = 8'h00;
        cpu.fetch_stage.imem[89] = 8'h00;
        cpu.fetch_stage.imem[90] = 8'h00;
        
        // [91-100] 0x5B: irmovq $0x10C, %r12 (268)
        cpu.fetch_stage.imem[91] = 8'h30;
        cpu.fetch_stage.imem[92] = 8'hFC;
        cpu.fetch_stage.imem[93] = 8'h0C;
        cpu.fetch_stage.imem[94] = 8'h01;
        cpu.fetch_stage.imem[95] = 8'h00;
        cpu.fetch_stage.imem[96] = 8'h00;
        cpu.fetch_stage.imem[97] = 8'h00;
        cpu.fetch_stage.imem[98] = 8'h00;
        cpu.fetch_stage.imem[99] = 8'h00;
        cpu.fetch_stage.imem[100] = 8'h00;
        
        // [101-110] 0x65: irmovq $0x10D, %r13 (269)
        cpu.fetch_stage.imem[101] = 8'h30;
        cpu.fetch_stage.imem[102] = 8'hFD;
        cpu.fetch_stage.imem[103] = 8'h0D;
        cpu.fetch_stage.imem[104] = 8'h01;
        cpu.fetch_stage.imem[105] = 8'h00;
        cpu.fetch_stage.imem[106] = 8'h00;
        cpu.fetch_stage.imem[107] = 8'h00;
        cpu.fetch_stage.imem[108] = 8'h00;
        cpu.fetch_stage.imem[109] = 8'h00;
        cpu.fetch_stage.imem[110] = 8'h00;
        
        // === 阶段2：RRMOVL ifun=0 ===
        // [111-112] 0x6F: rrmovq %rax, %rdx
        cpu.fetch_stage.imem[111] = 8'h20;
        cpu.fetch_stage.imem[112] = 8'h02;  // rA=0(%rax), rB=2(%rdx)
        
        // === 阶段3：ALU 全部 ifun (0-3) ===
        // [113-114] 0x71: addq %rbx, %rax - rax=10+20=30
        cpu.fetch_stage.imem[113] = 8'h60;
        cpu.fetch_stage.imem[114] = 8'h30;
        
        // [115-116] 0x73: subq %rcx, %rax - rax=30-5=25
        cpu.fetch_stage.imem[115] = 8'h61;
        cpu.fetch_stage.imem[116] = 8'h10;
        
        // [117-118] 0x75: andq %rbx, %rax - rax=25&20=16
        cpu.fetch_stage.imem[117] = 8'h62;
        cpu.fetch_stage.imem[118] = 8'h30;
        
        // [119-120] 0x77: xorq %rax, %rax - rax=0, ZF=1
        cpu.fetch_stage.imem[119] = 8'h63;
        cpu.fetch_stage.imem[120] = 8'h00;
        
        // === 阶段4：CMOVxx 测试 ZF=1 ===
        // 条件码：ZF=1, SF=0, OF=0
        // [121-122] 0x79: cmovle %rsi, %r8 - 应移动
        cpu.fetch_stage.imem[121] = 8'h21;
        cpu.fetch_stage.imem[122] = 8'h68;
        
        // [123-124] 0x7B: cmovl %rsi, %r9 - 不移动
        cpu.fetch_stage.imem[123] = 8'h22;
        cpu.fetch_stage.imem[124] = 8'h69;
        
        // [125-126] 0x7D: cmove %rsi, %r10 - 应移动
        cpu.fetch_stage.imem[125] = 8'h23;
        cpu.fetch_stage.imem[126] = 8'h6A;
        
        // [127-128] 0x7F: cmovne %rsi, %r11 - 不移动
        cpu.fetch_stage.imem[127] = 8'h24;
        cpu.fetch_stage.imem[128] = 8'h6B;
        
        // [129-130] 0x81: cmovge %rsi, %r12 - 应移动
        cpu.fetch_stage.imem[129] = 8'h25;
        cpu.fetch_stage.imem[130] = 8'h6C;
        
        // [131-132] 0x83: cmovg %rsi, %r13 - 不移动
        cpu.fetch_stage.imem[131] = 8'h26;
        cpu.fetch_stage.imem[132] = 8'h6D;
        
        // === 阶段5：RMMOVL & MRMOVL ===
        // [133-142] 0x85: rmmovq %rsi, 16(%rsp)
        cpu.fetch_stage.imem[133] = 8'h40;
        cpu.fetch_stage.imem[134] = 8'h64;
        cpu.fetch_stage.imem[135] = 8'h10;
        cpu.fetch_stage.imem[136] = 8'h00;
        cpu.fetch_stage.imem[137] = 8'h00;
        cpu.fetch_stage.imem[138] = 8'h00;
        cpu.fetch_stage.imem[139] = 8'h00;
        cpu.fetch_stage.imem[140] = 8'h00;
        cpu.fetch_stage.imem[141] = 8'h00;
        cpu.fetch_stage.imem[142] = 8'h00;
        
        // [143-152] 0x8F: mrmovq 16(%rsp), %rdi
        cpu.fetch_stage.imem[143] = 8'h50;
        cpu.fetch_stage.imem[144] = 8'h74;
        cpu.fetch_stage.imem[145] = 8'h10;
        cpu.fetch_stage.imem[146] = 8'h00;
        cpu.fetch_stage.imem[147] = 8'h00;
        cpu.fetch_stage.imem[148] = 8'h00;
        cpu.fetch_stage.imem[149] = 8'h00;
        cpu.fetch_stage.imem[150] = 8'h00;
        cpu.fetch_stage.imem[151] = 8'h00;
        cpu.fetch_stage.imem[152] = 8'h00;
        
        // === 阶段6：设置跳转测试条件 ===
        // [153-162] 0x99: irmovq $0, %rbp
        cpu.fetch_stage.imem[153] = 8'h30;
        cpu.fetch_stage.imem[154] = 8'hF5;
        cpu.fetch_stage.imem[155] = 8'h00;
        cpu.fetch_stage.imem[156] = 8'h00;
        cpu.fetch_stage.imem[157] = 8'h00;
        cpu.fetch_stage.imem[158] = 8'h00;
        cpu.fetch_stage.imem[159] = 8'h00;
        cpu.fetch_stage.imem[160] = 8'h00;
        cpu.fetch_stage.imem[161] = 8'h00;
        cpu.fetch_stage.imem[162] = 8'h00;
        
        // [163-172] 0xA3: irmovq $1, %r14
        cpu.fetch_stage.imem[163] = 8'h30;
        cpu.fetch_stage.imem[164] = 8'hFE;
        cpu.fetch_stage.imem[165] = 8'h01;
        cpu.fetch_stage.imem[166] = 8'h00;
        cpu.fetch_stage.imem[167] = 8'h00;
        cpu.fetch_stage.imem[168] = 8'h00;
        cpu.fetch_stage.imem[169] = 8'h00;
        cpu.fetch_stage.imem[170] = 8'h00;
        cpu.fetch_stage.imem[171] = 8'h00;
        cpu.fetch_stage.imem[172] = 8'h00;
        
        // [173-182] 0xAD: irmovq $30, %rax
        cpu.fetch_stage.imem[173] = 8'h30;
        cpu.fetch_stage.imem[174] = 8'hF0;
        cpu.fetch_stage.imem[175] = 8'h1E;
        cpu.fetch_stage.imem[176] = 8'h00;
        cpu.fetch_stage.imem[177] = 8'h00;
        cpu.fetch_stage.imem[178] = 8'h00;
        cpu.fetch_stage.imem[179] = 8'h00;
        cpu.fetch_stage.imem[180] = 8'h00;
        cpu.fetch_stage.imem[181] = 8'h00;
        cpu.fetch_stage.imem[182] = 8'h00;
        
        // [183-184] 0xB7: subq %rbx, %rax -> rax=10, ZF=0,SF=0
        cpu.fetch_stage.imem[183] = 8'h61;
        cpu.fetch_stage.imem[184] = 8'h30;
        
        // === 阶段7：JXX 全部 ifun (0-6) ===
        // 条件码：ZF=0, SF=0, OF=0
        // jle, jl, je 不跳转；jne, jge, jg, jmp 跳转
        
        // [185-193] 0xB9: jle target -> 不跳转
        cpu.fetch_stage.imem[185] = 8'h71;
        cpu.fetch_stage.imem[186] = 8'hC4;  // target=196
        cpu.fetch_stage.imem[187] = 8'h00;
        cpu.fetch_stage.imem[188] = 8'h00;
        cpu.fetch_stage.imem[189] = 8'h00;
        cpu.fetch_stage.imem[190] = 8'h00;
        cpu.fetch_stage.imem[191] = 8'h00;
        cpu.fetch_stage.imem[192] = 8'h00;
        cpu.fetch_stage.imem[193] = 8'h00;
        
        // [194-195] 0xC2: addq %r14, %rbp - rbp++
        cpu.fetch_stage.imem[194] = 8'h60;
        cpu.fetch_stage.imem[195] = 8'hE5;
        
        // [196-204] 0xC4: jl target -> 不跳转
        cpu.fetch_stage.imem[196] = 8'h72;
        cpu.fetch_stage.imem[197] = 8'hCF;  // target=207
        cpu.fetch_stage.imem[198] = 8'h00;
        cpu.fetch_stage.imem[199] = 8'h00;
        cpu.fetch_stage.imem[200] = 8'h00;
        cpu.fetch_stage.imem[201] = 8'h00;
        cpu.fetch_stage.imem[202] = 8'h00;
        cpu.fetch_stage.imem[203] = 8'h00;
        cpu.fetch_stage.imem[204] = 8'h00;
        
        // [205-206] 0xCD: addq %r14, %rbp - rbp++
        cpu.fetch_stage.imem[205] = 8'h60;
        cpu.fetch_stage.imem[206] = 8'hE5;
        
        // [207-215] 0xCF: je target -> 不跳转
        cpu.fetch_stage.imem[207] = 8'h73;
        cpu.fetch_stage.imem[208] = 8'hDA;  // target=218
        cpu.fetch_stage.imem[209] = 8'h00;
        cpu.fetch_stage.imem[210] = 8'h00;
        cpu.fetch_stage.imem[211] = 8'h00;
        cpu.fetch_stage.imem[212] = 8'h00;
        cpu.fetch_stage.imem[213] = 8'h00;
        cpu.fetch_stage.imem[214] = 8'h00;
        cpu.fetch_stage.imem[215] = 8'h00;
        
        // [216-217] 0xD8: addq %r14, %rbp - rbp++
        cpu.fetch_stage.imem[216] = 8'h60;
        cpu.fetch_stage.imem[217] = 8'hE5;
        
        // [218-226] 0xDA: jne target -> 跳转
        cpu.fetch_stage.imem[218] = 8'h74;
        cpu.fetch_stage.imem[219] = 8'hE5;  // target=229
        cpu.fetch_stage.imem[220] = 8'h00;
        cpu.fetch_stage.imem[221] = 8'h00;
        cpu.fetch_stage.imem[222] = 8'h00;
        cpu.fetch_stage.imem[223] = 8'h00;
        cpu.fetch_stage.imem[224] = 8'h00;
        cpu.fetch_stage.imem[225] = 8'h00;
        cpu.fetch_stage.imem[226] = 8'h00;
        
        // [227-228] 0xE3: addq (skipped)
        cpu.fetch_stage.imem[227] = 8'h60;
        cpu.fetch_stage.imem[228] = 8'hE5;
        
        // [229-237] 0xE5: jge target -> 跳转
        cpu.fetch_stage.imem[229] = 8'h75;
        cpu.fetch_stage.imem[230] = 8'hF0;  // target=240
        cpu.fetch_stage.imem[231] = 8'h00;
        cpu.fetch_stage.imem[232] = 8'h00;
        cpu.fetch_stage.imem[233] = 8'h00;
        cpu.fetch_stage.imem[234] = 8'h00;
        cpu.fetch_stage.imem[235] = 8'h00;
        cpu.fetch_stage.imem[236] = 8'h00;
        cpu.fetch_stage.imem[237] = 8'h00;
        
        // [238-239] 0xEE: addq (skipped)
        cpu.fetch_stage.imem[238] = 8'h60;
        cpu.fetch_stage.imem[239] = 8'hE5;
        
        // [240-248] 0xF0: jg target -> 跳转
        cpu.fetch_stage.imem[240] = 8'h76;
        cpu.fetch_stage.imem[241] = 8'hFB;  // target=251
        cpu.fetch_stage.imem[242] = 8'h00;
        cpu.fetch_stage.imem[243] = 8'h00;
        cpu.fetch_stage.imem[244] = 8'h00;
        cpu.fetch_stage.imem[245] = 8'h00;
        cpu.fetch_stage.imem[246] = 8'h00;
        cpu.fetch_stage.imem[247] = 8'h00;
        cpu.fetch_stage.imem[248] = 8'h00;
        
        // [249-250] 0xF9: addq (skipped)
        cpu.fetch_stage.imem[249] = 8'h60;
        cpu.fetch_stage.imem[250] = 8'hE5;
        
        // [251-259] 0xFB: jmp target -> 无条件跳转
        cpu.fetch_stage.imem[251] = 8'h70;
        cpu.fetch_stage.imem[252] = 8'h06;  // target=262 (0x106)
        cpu.fetch_stage.imem[253] = 8'h01;  // 高字节
        cpu.fetch_stage.imem[254] = 8'h00;
        cpu.fetch_stage.imem[255] = 8'h00;
        cpu.fetch_stage.imem[256] = 8'h00;
        cpu.fetch_stage.imem[257] = 8'h00;
        cpu.fetch_stage.imem[258] = 8'h00;
        cpu.fetch_stage.imem[259] = 8'h00;
        
        // [260-261] 0x104: addq (skipped)
        cpu.fetch_stage.imem[260] = 8'h60;
        cpu.fetch_stage.imem[261] = 8'hE5;
        
        // === 阶段8：PUSHL & POPL ===
        // [262-263] 0x106: pushq %rsi
        cpu.fetch_stage.imem[262] = 8'hA0;
        cpu.fetch_stage.imem[263] = 8'h6F;
        
        // [264-273] 0x108: irmovq $123, %rsi
        cpu.fetch_stage.imem[264] = 8'h30;
        cpu.fetch_stage.imem[265] = 8'hF6;
        cpu.fetch_stage.imem[266] = 8'h7B;  // 123
        cpu.fetch_stage.imem[267] = 8'h00;
        cpu.fetch_stage.imem[268] = 8'h00;
        cpu.fetch_stage.imem[269] = 8'h00;
        cpu.fetch_stage.imem[270] = 8'h00;
        cpu.fetch_stage.imem[271] = 8'h00;
        cpu.fetch_stage.imem[272] = 8'h00;
        cpu.fetch_stage.imem[273] = 8'h00;
        
        // [274-275] 0x112: popq %r14
        cpu.fetch_stage.imem[274] = 8'hB0;
        cpu.fetch_stage.imem[275] = 8'hEF;
        
        // === 阶段9：CALL & RET ===
        // [276-284] 0x114: call target
        cpu.fetch_stage.imem[276] = 8'h80;
        cpu.fetch_stage.imem[277] = 8'h20;  // target=288 (0x120)
        cpu.fetch_stage.imem[278] = 8'h01;
        cpu.fetch_stage.imem[279] = 8'h00;
        cpu.fetch_stage.imem[280] = 8'h00;
        cpu.fetch_stage.imem[281] = 8'h00;
        cpu.fetch_stage.imem[282] = 8'h00;
        cpu.fetch_stage.imem[283] = 8'h00;
        cpu.fetch_stage.imem[284] = 8'h00;
        
        // [285] 0x11D: halt (call返回后)
        cpu.fetch_stage.imem[285] = 8'h10;
        
        // [288] 0x120: ret
        cpu.fetch_stage.imem[288] = 8'h90;
        
        // ==================== 打印加载的完整指令 ====================
        $display("\n========================================");
        $display("=== Loaded Instructions ===");
        $display("Total: 289 bytes (0x000 ~ 0x120)");
        $display("  - Register init: 13 irmovq instructions");
        $display("  - RRMOVL test: 1 instruction");
        $display("  - ALU ops: 4 instructions (addq, subq, andq, xorq)");
        $display("  - CMOVxx: 6 conditional moves");
        $display("  - Memory: 2 instructions (rmmovq, mrmovq)");
        $display("  - JXX: 7 jump instructions");
        $display("  - CALL/RET: 2 instructions");
        $display("  - PUSH/POP: 2 instructions");
        $display("  - HALT: 1 instruction");
        $display("========================================\n");
        
        // ==================== 启动测试 ====================
        #100 rst_n = 1;
    end

endmodule
