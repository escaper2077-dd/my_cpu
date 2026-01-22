`timescale 1ps/1ps

// Y86-64 全覆盖测试 V6
// 改进：
// 1. 寄存器初始化为0，测试程序显式初始化所有需要的寄存器
// 2. r8-r13 初始化为 0x100+编号，避免与寄存器编号混淆
// 3. 完整覆盖所有 icode 和 ifun 组合

module y86_cpu_comprehensive_tb_v6();

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
                $display("  %%rbp = %d (should be 3, count of NOT-taken jumps)", uut.decode_stage.regfile[5]);
                $display("  %%rsi = %d (should be 123)", uut.decode_stage.regfile[6]);
                $display("  %%rdi = %d (should be 99, from mrmovq)", uut.decode_stage.regfile[7]);
                $display("  %%r8  = %d (should be 99, cmovle MOVED)", uut.decode_stage.regfile[8]);
                $display("  %%r9  = %d (should be 0x109=265, cmovl NOT moved)", uut.decode_stage.regfile[9]);
                $display("  %%r10 = %d (should be 99, cmove MOVED)", uut.decode_stage.regfile[10]);
                $display("  %%r11 = %d (should be 0x10B=267, cmovne NOT moved)", uut.decode_stage.regfile[11]);
                $display("  %%r12 = %d (should be 99, cmovge MOVED)", uut.decode_stage.regfile[12]);
                $display("  %%r13 = %d (should be 0x10D=269, cmovg NOT moved)", uut.decode_stage.regfile[13]);
                $display("  %%r14 = %d (should be 99, from popq)", uut.decode_stage.regfile[14]);
                
                $display("\n=== 验证结果 ===");
                if (uut.decode_stage.regfile[2] == 10) $display("  [PASS] rrmovq: rdx=10");
                else $display("  [FAIL] rrmovq: expected 10, got %d", uut.decode_stage.regfile[2]);
                
                if (uut.decode_stage.regfile[8] == 99) $display("  [PASS] cmovle (ifun=1): r8=99 (MOVED)");
                else $display("  [FAIL] cmovle: expected 99, got %d", uut.decode_stage.regfile[8]);
                
                if (uut.decode_stage.regfile[9] == 265) $display("  [PASS] cmovl (ifun=2): r9=265 (NOT moved)");
                else $display("  [FAIL] cmovl: expected 265 (0x109), got %d", uut.decode_stage.regfile[9]);
                
                if (uut.decode_stage.regfile[10] == 99) $display("  [PASS] cmove (ifun=3): r10=99 (MOVED)");
                else $display("  [FAIL] cmove: expected 99, got %d", uut.decode_stage.regfile[10]);
                
                if (uut.decode_stage.regfile[11] == 267) $display("  [PASS] cmovne (ifun=4): r11=267 (NOT moved)");
                else $display("  [FAIL] cmovne: expected 267 (0x10B), got %d", uut.decode_stage.regfile[11]);
                
                if (uut.decode_stage.regfile[12] == 99) $display("  [PASS] cmovge (ifun=5): r12=99 (MOVED)");
                else $display("  [FAIL] cmovge: expected 99, got %d", uut.decode_stage.regfile[12]);
                
                if (uut.decode_stage.regfile[13] == 269) $display("  [PASS] cmovg (ifun=6): r13=269 (NOT moved)");
                else $display("  [FAIL] cmovg: expected 269 (0x10D), got %d", uut.decode_stage.regfile[13]);
                
                if (uut.decode_stage.regfile[7] == 99) $display("  [PASS] rmmovq/mrmovq: rdi=99");
                else $display("  [FAIL] rmmovq/mrmovq: expected 99, got %d", uut.decode_stage.regfile[7]);
                
                if (uut.decode_stage.regfile[5] == 3) $display("  [PASS] JXX: rbp=3 (jle,jl,je NOT taken)");
                else $display("  [FAIL] JXX: expected rbp=3, got %d", uut.decode_stage.regfile[5]);
                
                if (uut.decode_stage.regfile[14] == 99) $display("  [PASS] pushq/popq: r14=99");
                else $display("  [FAIL] pushq/popq: expected 99, got %d", uut.decode_stage.regfile[14]);
                
                $display("\nCPU Status: %b (expected: 01 for HALT)", Stat);
                $display("Final PC: 0x%h", PC);
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
    // 地址分配（每条 irmovq 占10字节，其他指令占2或9字节）：
    // 0x00: nop (1)
    // 0x01: irmovq $200, %rsp (10)
    // 0x0B: irmovq $10, %rax (10)
    // 0x15: irmovq $20, %rbx (10)
    // 0x1F: irmovq $5, %rcx (10)
    // 0x29: irmovq $99, %rsi (10)
    // 0x33: irmovq $0x108, %r8 (10)   <- 新增初始化
    // 0x3D: irmovq $0x109, %r9 (10)
    // 0x47: irmovq $0x10A, %r10 (10)
    // 0x51: irmovq $0x10B, %r11 (10)
    // 0x5B: irmovq $0x10C, %r12 (10)
    // 0x65: irmovq $0x10D, %r13 (10)
    // 0x6F: rrmovq %rax, %rdx (2)
    // ... 后续指令从 0x71 开始
    // ============================================================
    
    integer i;
    
    initial begin
        $display("========================================");
        $display("=== Y86-64 Comprehensive Test V6 ===");
        $display("=== Explicit Register Initialization ===");
        $display("========================================\n");
        
        // 初始化指令内存为全0
        for (i = 0; i < 1024; i = i + 1) begin
            uut.fetch_stage.instr_mem[i] = 8'h00;
        end
        
        // ==================== 加载指令 ====================
        
        // === 阶段1：初始化所有寄存器 ===
        
        // [0] 0x00: NOP
        uut.fetch_stage.instr_mem[0] = 8'h00;
        
        // [1-10] 0x01: irmovq $200, %rsp
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
        
        // [51-60] 0x33: irmovq $0x108, %r8 (264)
        uut.fetch_stage.instr_mem[51] = 8'h30;
        uut.fetch_stage.instr_mem[52] = 8'hF8;
        uut.fetch_stage.instr_mem[53] = 8'h08;
        uut.fetch_stage.instr_mem[54] = 8'h01;
        uut.fetch_stage.instr_mem[55] = 8'h00;
        uut.fetch_stage.instr_mem[56] = 8'h00;
        uut.fetch_stage.instr_mem[57] = 8'h00;
        uut.fetch_stage.instr_mem[58] = 8'h00;
        uut.fetch_stage.instr_mem[59] = 8'h00;
        uut.fetch_stage.instr_mem[60] = 8'h00;
        
        // [61-70] 0x3D: irmovq $0x109, %r9 (265)
        uut.fetch_stage.instr_mem[61] = 8'h30;
        uut.fetch_stage.instr_mem[62] = 8'hF9;
        uut.fetch_stage.instr_mem[63] = 8'h09;
        uut.fetch_stage.instr_mem[64] = 8'h01;
        uut.fetch_stage.instr_mem[65] = 8'h00;
        uut.fetch_stage.instr_mem[66] = 8'h00;
        uut.fetch_stage.instr_mem[67] = 8'h00;
        uut.fetch_stage.instr_mem[68] = 8'h00;
        uut.fetch_stage.instr_mem[69] = 8'h00;
        uut.fetch_stage.instr_mem[70] = 8'h00;
        
        // [71-80] 0x47: irmovq $0x10A, %r10 (266)
        uut.fetch_stage.instr_mem[71] = 8'h30;
        uut.fetch_stage.instr_mem[72] = 8'hFA;
        uut.fetch_stage.instr_mem[73] = 8'h0A;
        uut.fetch_stage.instr_mem[74] = 8'h01;
        uut.fetch_stage.instr_mem[75] = 8'h00;
        uut.fetch_stage.instr_mem[76] = 8'h00;
        uut.fetch_stage.instr_mem[77] = 8'h00;
        uut.fetch_stage.instr_mem[78] = 8'h00;
        uut.fetch_stage.instr_mem[79] = 8'h00;
        uut.fetch_stage.instr_mem[80] = 8'h00;
        
        // [81-90] 0x51: irmovq $0x10B, %r11 (267)
        uut.fetch_stage.instr_mem[81] = 8'h30;
        uut.fetch_stage.instr_mem[82] = 8'hFB;
        uut.fetch_stage.instr_mem[83] = 8'h0B;
        uut.fetch_stage.instr_mem[84] = 8'h01;
        uut.fetch_stage.instr_mem[85] = 8'h00;
        uut.fetch_stage.instr_mem[86] = 8'h00;
        uut.fetch_stage.instr_mem[87] = 8'h00;
        uut.fetch_stage.instr_mem[88] = 8'h00;
        uut.fetch_stage.instr_mem[89] = 8'h00;
        uut.fetch_stage.instr_mem[90] = 8'h00;
        
        // [91-100] 0x5B: irmovq $0x10C, %r12 (268)
        uut.fetch_stage.instr_mem[91] = 8'h30;
        uut.fetch_stage.instr_mem[92] = 8'hFC;
        uut.fetch_stage.instr_mem[93] = 8'h0C;
        uut.fetch_stage.instr_mem[94] = 8'h01;
        uut.fetch_stage.instr_mem[95] = 8'h00;
        uut.fetch_stage.instr_mem[96] = 8'h00;
        uut.fetch_stage.instr_mem[97] = 8'h00;
        uut.fetch_stage.instr_mem[98] = 8'h00;
        uut.fetch_stage.instr_mem[99] = 8'h00;
        uut.fetch_stage.instr_mem[100] = 8'h00;
        
        // [101-110] 0x65: irmovq $0x10D, %r13 (269)
        uut.fetch_stage.instr_mem[101] = 8'h30;
        uut.fetch_stage.instr_mem[102] = 8'hFD;
        uut.fetch_stage.instr_mem[103] = 8'h0D;
        uut.fetch_stage.instr_mem[104] = 8'h01;
        uut.fetch_stage.instr_mem[105] = 8'h00;
        uut.fetch_stage.instr_mem[106] = 8'h00;
        uut.fetch_stage.instr_mem[107] = 8'h00;
        uut.fetch_stage.instr_mem[108] = 8'h00;
        uut.fetch_stage.instr_mem[109] = 8'h00;
        uut.fetch_stage.instr_mem[110] = 8'h00;
        
        // === 阶段2：RRMOVL ifun=0 ===
        // [111-112] 0x6F: rrmovq %rax, %rdx
        uut.fetch_stage.instr_mem[111] = 8'h20;
        uut.fetch_stage.instr_mem[112] = 8'h02;  // rA=0(%rax), rB=2(%rdx)
        
        // === 阶段3：ALU 全部 ifun (0-3) ===
        // [113-114] 0x71: addq %rbx, %rax - rax=10+20=30
        uut.fetch_stage.instr_mem[113] = 8'h60;
        uut.fetch_stage.instr_mem[114] = 8'h30;
        
        // [115-116] 0x73: subq %rcx, %rax - rax=30-5=25
        uut.fetch_stage.instr_mem[115] = 8'h61;
        uut.fetch_stage.instr_mem[116] = 8'h10;
        
        // [117-118] 0x75: andq %rbx, %rax - rax=25&20=16
        uut.fetch_stage.instr_mem[117] = 8'h62;
        uut.fetch_stage.instr_mem[118] = 8'h30;
        
        // [119-120] 0x77: xorq %rax, %rax - rax=0, ZF=1
        uut.fetch_stage.instr_mem[119] = 8'h63;
        uut.fetch_stage.instr_mem[120] = 8'h00;
        
        // === 阶段4：CMOVxx 测试 ZF=1 ===
        // 条件码：ZF=1, SF=0, OF=0
        // [121-122] 0x79: cmovle %rsi, %r8 - 应移动
        uut.fetch_stage.instr_mem[121] = 8'h21;
        uut.fetch_stage.instr_mem[122] = 8'h68;
        
        // [123-124] 0x7B: cmovl %rsi, %r9 - 不移动
        uut.fetch_stage.instr_mem[123] = 8'h22;
        uut.fetch_stage.instr_mem[124] = 8'h69;
        
        // [125-126] 0x7D: cmove %rsi, %r10 - 应移动
        uut.fetch_stage.instr_mem[125] = 8'h23;
        uut.fetch_stage.instr_mem[126] = 8'h6A;
        
        // [127-128] 0x7F: cmovne %rsi, %r11 - 不移动
        uut.fetch_stage.instr_mem[127] = 8'h24;
        uut.fetch_stage.instr_mem[128] = 8'h6B;
        
        // [129-130] 0x81: cmovge %rsi, %r12 - 应移动
        uut.fetch_stage.instr_mem[129] = 8'h25;
        uut.fetch_stage.instr_mem[130] = 8'h6C;
        
        // [131-132] 0x83: cmovg %rsi, %r13 - 不移动
        uut.fetch_stage.instr_mem[131] = 8'h26;
        uut.fetch_stage.instr_mem[132] = 8'h6D;
        
        // === 阶段5：RMMOVL & MRMOVL ===
        // [133-142] 0x85: rmmovq %rsi, 16(%rsp)
        uut.fetch_stage.instr_mem[133] = 8'h40;
        uut.fetch_stage.instr_mem[134] = 8'h64;
        uut.fetch_stage.instr_mem[135] = 8'h10;
        uut.fetch_stage.instr_mem[136] = 8'h00;
        uut.fetch_stage.instr_mem[137] = 8'h00;
        uut.fetch_stage.instr_mem[138] = 8'h00;
        uut.fetch_stage.instr_mem[139] = 8'h00;
        uut.fetch_stage.instr_mem[140] = 8'h00;
        uut.fetch_stage.instr_mem[141] = 8'h00;
        uut.fetch_stage.instr_mem[142] = 8'h00;
        
        // [143-152] 0x8F: mrmovq 16(%rsp), %rdi
        uut.fetch_stage.instr_mem[143] = 8'h50;
        uut.fetch_stage.instr_mem[144] = 8'h74;
        uut.fetch_stage.instr_mem[145] = 8'h10;
        uut.fetch_stage.instr_mem[146] = 8'h00;
        uut.fetch_stage.instr_mem[147] = 8'h00;
        uut.fetch_stage.instr_mem[148] = 8'h00;
        uut.fetch_stage.instr_mem[149] = 8'h00;
        uut.fetch_stage.instr_mem[150] = 8'h00;
        uut.fetch_stage.instr_mem[151] = 8'h00;
        uut.fetch_stage.instr_mem[152] = 8'h00;
        
        // === 阶段6：设置跳转测试条件 ===
        // [153-162] 0x99: irmovq $0, %rbp
        uut.fetch_stage.instr_mem[153] = 8'h30;
        uut.fetch_stage.instr_mem[154] = 8'hF5;
        uut.fetch_stage.instr_mem[155] = 8'h00;
        uut.fetch_stage.instr_mem[156] = 8'h00;
        uut.fetch_stage.instr_mem[157] = 8'h00;
        uut.fetch_stage.instr_mem[158] = 8'h00;
        uut.fetch_stage.instr_mem[159] = 8'h00;
        uut.fetch_stage.instr_mem[160] = 8'h00;
        uut.fetch_stage.instr_mem[161] = 8'h00;
        uut.fetch_stage.instr_mem[162] = 8'h00;
        
        // [163-172] 0xA3: irmovq $1, %r14
        uut.fetch_stage.instr_mem[163] = 8'h30;
        uut.fetch_stage.instr_mem[164] = 8'hFE;
        uut.fetch_stage.instr_mem[165] = 8'h01;
        uut.fetch_stage.instr_mem[166] = 8'h00;
        uut.fetch_stage.instr_mem[167] = 8'h00;
        uut.fetch_stage.instr_mem[168] = 8'h00;
        uut.fetch_stage.instr_mem[169] = 8'h00;
        uut.fetch_stage.instr_mem[170] = 8'h00;
        uut.fetch_stage.instr_mem[171] = 8'h00;
        uut.fetch_stage.instr_mem[172] = 8'h00;
        
        // [173-182] 0xAD: irmovq $30, %rax
        uut.fetch_stage.instr_mem[173] = 8'h30;
        uut.fetch_stage.instr_mem[174] = 8'hF0;
        uut.fetch_stage.instr_mem[175] = 8'h1E;
        uut.fetch_stage.instr_mem[176] = 8'h00;
        uut.fetch_stage.instr_mem[177] = 8'h00;
        uut.fetch_stage.instr_mem[178] = 8'h00;
        uut.fetch_stage.instr_mem[179] = 8'h00;
        uut.fetch_stage.instr_mem[180] = 8'h00;
        uut.fetch_stage.instr_mem[181] = 8'h00;
        uut.fetch_stage.instr_mem[182] = 8'h00;
        
        // [183-184] 0xB7: subq %rbx, %rax -> rax=10, ZF=0,SF=0
        uut.fetch_stage.instr_mem[183] = 8'h61;
        uut.fetch_stage.instr_mem[184] = 8'h30;
        
        // === 阶段7：JXX 全部 ifun (0-6) ===
        // 条件码：ZF=0, SF=0, OF=0
        // jle, jl, je 不跳转；jne, jge, jg, jmp 跳转
        
        // [185-193] 0xB9: jle target -> 不跳转
        uut.fetch_stage.instr_mem[185] = 8'h71;
        uut.fetch_stage.instr_mem[186] = 8'hC4;  // target=196
        uut.fetch_stage.instr_mem[187] = 8'h00;
        uut.fetch_stage.instr_mem[188] = 8'h00;
        uut.fetch_stage.instr_mem[189] = 8'h00;
        uut.fetch_stage.instr_mem[190] = 8'h00;
        uut.fetch_stage.instr_mem[191] = 8'h00;
        uut.fetch_stage.instr_mem[192] = 8'h00;
        uut.fetch_stage.instr_mem[193] = 8'h00;
        
        // [194-195] 0xC2: addq %r14, %rbp - rbp++
        uut.fetch_stage.instr_mem[194] = 8'h60;
        uut.fetch_stage.instr_mem[195] = 8'hE5;
        
        // [196-204] 0xC4: jl target -> 不跳转
        uut.fetch_stage.instr_mem[196] = 8'h72;
        uut.fetch_stage.instr_mem[197] = 8'hCF;  // target=207
        uut.fetch_stage.instr_mem[198] = 8'h00;
        uut.fetch_stage.instr_mem[199] = 8'h00;
        uut.fetch_stage.instr_mem[200] = 8'h00;
        uut.fetch_stage.instr_mem[201] = 8'h00;
        uut.fetch_stage.instr_mem[202] = 8'h00;
        uut.fetch_stage.instr_mem[203] = 8'h00;
        uut.fetch_stage.instr_mem[204] = 8'h00;
        
        // [205-206] 0xCD: addq %r14, %rbp - rbp++
        uut.fetch_stage.instr_mem[205] = 8'h60;
        uut.fetch_stage.instr_mem[206] = 8'hE5;
        
        // [207-215] 0xCF: je target -> 不跳转
        uut.fetch_stage.instr_mem[207] = 8'h73;
        uut.fetch_stage.instr_mem[208] = 8'hDA;  // target=218
        uut.fetch_stage.instr_mem[209] = 8'h00;
        uut.fetch_stage.instr_mem[210] = 8'h00;
        uut.fetch_stage.instr_mem[211] = 8'h00;
        uut.fetch_stage.instr_mem[212] = 8'h00;
        uut.fetch_stage.instr_mem[213] = 8'h00;
        uut.fetch_stage.instr_mem[214] = 8'h00;
        uut.fetch_stage.instr_mem[215] = 8'h00;
        
        // [216-217] 0xD8: addq %r14, %rbp - rbp++
        uut.fetch_stage.instr_mem[216] = 8'h60;
        uut.fetch_stage.instr_mem[217] = 8'hE5;
        
        // [218-226] 0xDA: jne target -> 跳转
        uut.fetch_stage.instr_mem[218] = 8'h74;
        uut.fetch_stage.instr_mem[219] = 8'hE5;  // target=229
        uut.fetch_stage.instr_mem[220] = 8'h00;
        uut.fetch_stage.instr_mem[221] = 8'h00;
        uut.fetch_stage.instr_mem[222] = 8'h00;
        uut.fetch_stage.instr_mem[223] = 8'h00;
        uut.fetch_stage.instr_mem[224] = 8'h00;
        uut.fetch_stage.instr_mem[225] = 8'h00;
        uut.fetch_stage.instr_mem[226] = 8'h00;
        
        // [227-228] 0xE3: addq (skipped)
        uut.fetch_stage.instr_mem[227] = 8'h60;
        uut.fetch_stage.instr_mem[228] = 8'hE5;
        
        // [229-237] 0xE5: jge target -> 跳转
        uut.fetch_stage.instr_mem[229] = 8'h75;
        uut.fetch_stage.instr_mem[230] = 8'hF0;  // target=240
        uut.fetch_stage.instr_mem[231] = 8'h00;
        uut.fetch_stage.instr_mem[232] = 8'h00;
        uut.fetch_stage.instr_mem[233] = 8'h00;
        uut.fetch_stage.instr_mem[234] = 8'h00;
        uut.fetch_stage.instr_mem[235] = 8'h00;
        uut.fetch_stage.instr_mem[236] = 8'h00;
        uut.fetch_stage.instr_mem[237] = 8'h00;
        
        // [238-239] 0xEE: addq (skipped)
        uut.fetch_stage.instr_mem[238] = 8'h60;
        uut.fetch_stage.instr_mem[239] = 8'hE5;
        
        // [240-248] 0xF0: jg target -> 跳转
        uut.fetch_stage.instr_mem[240] = 8'h76;
        uut.fetch_stage.instr_mem[241] = 8'hFB;  // target=251
        uut.fetch_stage.instr_mem[242] = 8'h00;
        uut.fetch_stage.instr_mem[243] = 8'h00;
        uut.fetch_stage.instr_mem[244] = 8'h00;
        uut.fetch_stage.instr_mem[245] = 8'h00;
        uut.fetch_stage.instr_mem[246] = 8'h00;
        uut.fetch_stage.instr_mem[247] = 8'h00;
        uut.fetch_stage.instr_mem[248] = 8'h00;
        
        // [249-250] 0xF9: addq (skipped)
        uut.fetch_stage.instr_mem[249] = 8'h60;
        uut.fetch_stage.instr_mem[250] = 8'hE5;
        
        // [251-259] 0xFB: jmp target -> 无条件跳转
        uut.fetch_stage.instr_mem[251] = 8'h70;
        uut.fetch_stage.instr_mem[252] = 8'h06;  // target=262 (0x106)
        uut.fetch_stage.instr_mem[253] = 8'h01;  // 高字节
        uut.fetch_stage.instr_mem[254] = 8'h00;
        uut.fetch_stage.instr_mem[255] = 8'h00;
        uut.fetch_stage.instr_mem[256] = 8'h00;
        uut.fetch_stage.instr_mem[257] = 8'h00;
        uut.fetch_stage.instr_mem[258] = 8'h00;
        uut.fetch_stage.instr_mem[259] = 8'h00;
        
        // [260-261] 0x104: addq (skipped)
        uut.fetch_stage.instr_mem[260] = 8'h60;
        uut.fetch_stage.instr_mem[261] = 8'hE5;
        
        // === 阶段8：PUSHL & POPL ===
        // [262-263] 0x106: pushq %rsi
        uut.fetch_stage.instr_mem[262] = 8'hA0;
        uut.fetch_stage.instr_mem[263] = 8'h6F;
        
        // [264-273] 0x108: irmovq $123, %rsi
        uut.fetch_stage.instr_mem[264] = 8'h30;
        uut.fetch_stage.instr_mem[265] = 8'hF6;
        uut.fetch_stage.instr_mem[266] = 8'h7B;  // 123
        uut.fetch_stage.instr_mem[267] = 8'h00;
        uut.fetch_stage.instr_mem[268] = 8'h00;
        uut.fetch_stage.instr_mem[269] = 8'h00;
        uut.fetch_stage.instr_mem[270] = 8'h00;
        uut.fetch_stage.instr_mem[271] = 8'h00;
        uut.fetch_stage.instr_mem[272] = 8'h00;
        uut.fetch_stage.instr_mem[273] = 8'h00;
        
        // [274-275] 0x112: popq %r14
        uut.fetch_stage.instr_mem[274] = 8'hB0;
        uut.fetch_stage.instr_mem[275] = 8'hEF;
        
        // === 阶段9：CALL & RET ===
        // [276-284] 0x114: call target
        uut.fetch_stage.instr_mem[276] = 8'h80;
        uut.fetch_stage.instr_mem[277] = 8'h20;  // target=288 (0x120)
        uut.fetch_stage.instr_mem[278] = 8'h01;
        uut.fetch_stage.instr_mem[279] = 8'h00;
        uut.fetch_stage.instr_mem[280] = 8'h00;
        uut.fetch_stage.instr_mem[281] = 8'h00;
        uut.fetch_stage.instr_mem[282] = 8'h00;
        uut.fetch_stage.instr_mem[283] = 8'h00;
        uut.fetch_stage.instr_mem[284] = 8'h00;
        
        // [285] 0x11D: halt (call返回后)
        uut.fetch_stage.instr_mem[285] = 8'h10;
        
        // [288] 0x120: ret
        uut.fetch_stage.instr_mem[288] = 8'h90;
        
        // ==================== 打印加载的完整指令 ====================
        $display("\n========================================");
        $display("=== Loaded Instructions ===");
        $display("========================================");
        
        $display("--- Register Initialization ---");
        // NOP
        $display("PC=0x00: %02h          -> nop", uut.fetch_stage.instr_mem[0]);
        
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
        
        // irmovq $0x108, %r8
        $display("PC=0x33: %02h %02h %02h%02h%02h%02h%02h%02h%02h%02h -> irmovq $0x108, %%r8 (264)",
            uut.fetch_stage.instr_mem[51], uut.fetch_stage.instr_mem[52],
            uut.fetch_stage.instr_mem[60], uut.fetch_stage.instr_mem[59], uut.fetch_stage.instr_mem[58], uut.fetch_stage.instr_mem[57],
            uut.fetch_stage.instr_mem[56], uut.fetch_stage.instr_mem[55], uut.fetch_stage.instr_mem[54], uut.fetch_stage.instr_mem[53]);
        
        // irmovq $0x109, %r9
        $display("PC=0x3D: %02h %02h %02h%02h%02h%02h%02h%02h%02h%02h -> irmovq $0x109, %%r9 (265)",
            uut.fetch_stage.instr_mem[61], uut.fetch_stage.instr_mem[62],
            uut.fetch_stage.instr_mem[70], uut.fetch_stage.instr_mem[69], uut.fetch_stage.instr_mem[68], uut.fetch_stage.instr_mem[67],
            uut.fetch_stage.instr_mem[66], uut.fetch_stage.instr_mem[65], uut.fetch_stage.instr_mem[64], uut.fetch_stage.instr_mem[63]);
        
        // irmovq $0x10A, %r10
        $display("PC=0x47: %02h %02h %02h%02h%02h%02h%02h%02h%02h%02h -> irmovq $0x10A, %%r10 (266)",
            uut.fetch_stage.instr_mem[71], uut.fetch_stage.instr_mem[72],
            uut.fetch_stage.instr_mem[80], uut.fetch_stage.instr_mem[79], uut.fetch_stage.instr_mem[78], uut.fetch_stage.instr_mem[77],
            uut.fetch_stage.instr_mem[76], uut.fetch_stage.instr_mem[75], uut.fetch_stage.instr_mem[74], uut.fetch_stage.instr_mem[73]);
        
        // irmovq $0x10B, %r11
        $display("PC=0x51: %02h %02h %02h%02h%02h%02h%02h%02h%02h%02h -> irmovq $0x10B, %%r11 (267)",
            uut.fetch_stage.instr_mem[81], uut.fetch_stage.instr_mem[82],
            uut.fetch_stage.instr_mem[90], uut.fetch_stage.instr_mem[89], uut.fetch_stage.instr_mem[88], uut.fetch_stage.instr_mem[87],
            uut.fetch_stage.instr_mem[86], uut.fetch_stage.instr_mem[85], uut.fetch_stage.instr_mem[84], uut.fetch_stage.instr_mem[83]);
        
        // irmovq $0x10C, %r12
        $display("PC=0x5B: %02h %02h %02h%02h%02h%02h%02h%02h%02h%02h -> irmovq $0x10C, %%r12 (268)",
            uut.fetch_stage.instr_mem[91], uut.fetch_stage.instr_mem[92],
            uut.fetch_stage.instr_mem[100], uut.fetch_stage.instr_mem[99], uut.fetch_stage.instr_mem[98], uut.fetch_stage.instr_mem[97],
            uut.fetch_stage.instr_mem[96], uut.fetch_stage.instr_mem[95], uut.fetch_stage.instr_mem[94], uut.fetch_stage.instr_mem[93]);
        
        // irmovq $0x10D, %r13
        $display("PC=0x65: %02h %02h %02h%02h%02h%02h%02h%02h%02h%02h -> irmovq $0x10D, %%r13 (269)",
            uut.fetch_stage.instr_mem[101], uut.fetch_stage.instr_mem[102],
            uut.fetch_stage.instr_mem[110], uut.fetch_stage.instr_mem[109], uut.fetch_stage.instr_mem[108], uut.fetch_stage.instr_mem[107],
            uut.fetch_stage.instr_mem[106], uut.fetch_stage.instr_mem[105], uut.fetch_stage.instr_mem[104], uut.fetch_stage.instr_mem[103]);
        
        $display("\n--- RRMOVL & ALU ---");
        $display("PC=0x6F: %02h %02h       -> rrmovq %%rax, %%rdx",
            uut.fetch_stage.instr_mem[111], uut.fetch_stage.instr_mem[112]);
        $display("PC=0x71: %02h %02h       -> addq %%rbx, %%rax (ifun=0)",
            uut.fetch_stage.instr_mem[113], uut.fetch_stage.instr_mem[114]);
        $display("PC=0x73: %02h %02h       -> subq %%rcx, %%rax (ifun=1)",
            uut.fetch_stage.instr_mem[115], uut.fetch_stage.instr_mem[116]);
        $display("PC=0x75: %02h %02h       -> andq %%rbx, %%rax (ifun=2)",
            uut.fetch_stage.instr_mem[117], uut.fetch_stage.instr_mem[118]);
        $display("PC=0x77: %02h %02h       -> xorq %%rax, %%rax (ifun=3) -> ZF=1",
            uut.fetch_stage.instr_mem[119], uut.fetch_stage.instr_mem[120]);
        
        $display("\n--- CMOVxx Test: CC={ZF=1, SF=0, OF=0} ---");
        $display("PC=0x79: %02h %02h       -> cmovle %%rsi, %%r8  | (SF^OF)|ZF = 1 -> MOVE",
            uut.fetch_stage.instr_mem[121], uut.fetch_stage.instr_mem[122]);
        $display("PC=0x7B: %02h %02h       -> cmovl  %%rsi, %%r9  | SF^OF = 0 -> NO MOVE",
            uut.fetch_stage.instr_mem[123], uut.fetch_stage.instr_mem[124]);
        $display("PC=0x7D: %02h %02h       -> cmove  %%rsi, %%r10 | ZF = 1 -> MOVE",
            uut.fetch_stage.instr_mem[125], uut.fetch_stage.instr_mem[126]);
        $display("PC=0x7F: %02h %02h       -> cmovne %%rsi, %%r11 | ~ZF = 0 -> NO MOVE",
            uut.fetch_stage.instr_mem[127], uut.fetch_stage.instr_mem[128]);
        $display("PC=0x81: %02h %02h       -> cmovge %%rsi, %%r12 | ~(SF^OF) = 1 -> MOVE",
            uut.fetch_stage.instr_mem[129], uut.fetch_stage.instr_mem[130]);
        $display("PC=0x83: %02h %02h       -> cmovg  %%rsi, %%r13 | ~(SF^OF)&~ZF = 0 -> NO MOVE",
            uut.fetch_stage.instr_mem[131], uut.fetch_stage.instr_mem[132]);
        
        $display("\n--- RMMOVL & MRMOVL ---");
        $display("PC=0x85: %02h %02h %02h%02h%02h%02h%02h%02h%02h%02h -> rmmovq %%rsi, 16(%%rsp)",
            uut.fetch_stage.instr_mem[133], uut.fetch_stage.instr_mem[134],
            uut.fetch_stage.instr_mem[142], uut.fetch_stage.instr_mem[141], uut.fetch_stage.instr_mem[140], uut.fetch_stage.instr_mem[139],
            uut.fetch_stage.instr_mem[138], uut.fetch_stage.instr_mem[137], uut.fetch_stage.instr_mem[136], uut.fetch_stage.instr_mem[135]);
        $display("PC=0x8F: %02h %02h %02h%02h%02h%02h%02h%02h%02h%02h -> mrmovq 16(%%rsp), %%rdi",
            uut.fetch_stage.instr_mem[143], uut.fetch_stage.instr_mem[144],
            uut.fetch_stage.instr_mem[152], uut.fetch_stage.instr_mem[151], uut.fetch_stage.instr_mem[150], uut.fetch_stage.instr_mem[149],
            uut.fetch_stage.instr_mem[148], uut.fetch_stage.instr_mem[147], uut.fetch_stage.instr_mem[146], uut.fetch_stage.instr_mem[145]);
        
        $display("\n--- Jump Preparation ---");
        $display("PC=0x99: %02h %02h %02h%02h%02h%02h%02h%02h%02h%02h -> irmovq $0, %%rbp",
            uut.fetch_stage.instr_mem[153], uut.fetch_stage.instr_mem[154],
            uut.fetch_stage.instr_mem[162], uut.fetch_stage.instr_mem[161], uut.fetch_stage.instr_mem[160], uut.fetch_stage.instr_mem[159],
            uut.fetch_stage.instr_mem[158], uut.fetch_stage.instr_mem[157], uut.fetch_stage.instr_mem[156], uut.fetch_stage.instr_mem[155]);
        $display("PC=0xA3: %02h %02h %02h%02h%02h%02h%02h%02h%02h%02h -> irmovq $1, %%r14",
            uut.fetch_stage.instr_mem[163], uut.fetch_stage.instr_mem[164],
            uut.fetch_stage.instr_mem[172], uut.fetch_stage.instr_mem[171], uut.fetch_stage.instr_mem[170], uut.fetch_stage.instr_mem[169],
            uut.fetch_stage.instr_mem[168], uut.fetch_stage.instr_mem[167], uut.fetch_stage.instr_mem[166], uut.fetch_stage.instr_mem[165]);
        $display("PC=0xAD: %02h %02h %02h%02h%02h%02h%02h%02h%02h%02h -> irmovq $30, %%rax",
            uut.fetch_stage.instr_mem[173], uut.fetch_stage.instr_mem[174],
            uut.fetch_stage.instr_mem[182], uut.fetch_stage.instr_mem[181], uut.fetch_stage.instr_mem[180], uut.fetch_stage.instr_mem[179],
            uut.fetch_stage.instr_mem[178], uut.fetch_stage.instr_mem[177], uut.fetch_stage.instr_mem[176], uut.fetch_stage.instr_mem[175]);
        $display("PC=0xB7: %02h %02h       -> subq %%rbx, %%rax -> ZF=0,SF=0",
            uut.fetch_stage.instr_mem[183], uut.fetch_stage.instr_mem[184]);
        
        $display("\n--- JXX Test: CC={ZF=0, SF=0, OF=0} ---");
        $display("PC=0xB9: %02h %02h%02h%02h%02h%02h%02h%02h%02h -> jle  | (SF^OF)|ZF = 0 -> NO JUMP",
            uut.fetch_stage.instr_mem[185],
            uut.fetch_stage.instr_mem[193], uut.fetch_stage.instr_mem[192], uut.fetch_stage.instr_mem[191], uut.fetch_stage.instr_mem[190],
            uut.fetch_stage.instr_mem[189], uut.fetch_stage.instr_mem[188], uut.fetch_stage.instr_mem[187], uut.fetch_stage.instr_mem[186]);
        $display("PC=0xC2: %02h %02h       -> addq %%r14, %%rbp (rbp++ because jle not taken)",
            uut.fetch_stage.instr_mem[194], uut.fetch_stage.instr_mem[195]);
        $display("PC=0xC4: %02h %02h%02h%02h%02h%02h%02h%02h%02h -> jl   | SF^OF = 0 -> NO JUMP",
            uut.fetch_stage.instr_mem[196],
            uut.fetch_stage.instr_mem[204], uut.fetch_stage.instr_mem[203], uut.fetch_stage.instr_mem[202], uut.fetch_stage.instr_mem[201],
            uut.fetch_stage.instr_mem[200], uut.fetch_stage.instr_mem[199], uut.fetch_stage.instr_mem[198], uut.fetch_stage.instr_mem[197]);
        $display("PC=0xCD: %02h %02h       -> addq %%r14, %%rbp (rbp++ because jl not taken)",
            uut.fetch_stage.instr_mem[205], uut.fetch_stage.instr_mem[206]);
        $display("PC=0xCF: %02h %02h%02h%02h%02h%02h%02h%02h%02h -> je   | ZF = 0 -> NO JUMP",
            uut.fetch_stage.instr_mem[207],
            uut.fetch_stage.instr_mem[215], uut.fetch_stage.instr_mem[214], uut.fetch_stage.instr_mem[213], uut.fetch_stage.instr_mem[212],
            uut.fetch_stage.instr_mem[211], uut.fetch_stage.instr_mem[210], uut.fetch_stage.instr_mem[209], uut.fetch_stage.instr_mem[208]);
        $display("PC=0xD8: %02h %02h       -> addq %%r14, %%rbp (rbp++ because je not taken)",
            uut.fetch_stage.instr_mem[216], uut.fetch_stage.instr_mem[217]);
        $display("PC=0xDA: %02h %02h%02h%02h%02h%02h%02h%02h%02h -> jne  | ~ZF = 1 -> JUMP",
            uut.fetch_stage.instr_mem[218],
            uut.fetch_stage.instr_mem[226], uut.fetch_stage.instr_mem[225], uut.fetch_stage.instr_mem[224], uut.fetch_stage.instr_mem[223],
            uut.fetch_stage.instr_mem[222], uut.fetch_stage.instr_mem[221], uut.fetch_stage.instr_mem[220], uut.fetch_stage.instr_mem[219]);
        $display("PC=0xE3: %02h %02h       -> addq %%r14, %%rbp (SKIPPED by jne)",
            uut.fetch_stage.instr_mem[227], uut.fetch_stage.instr_mem[228]);
        $display("PC=0xE5: %02h %02h%02h%02h%02h%02h%02h%02h%02h -> jge  | ~(SF^OF) = 1 -> JUMP",
            uut.fetch_stage.instr_mem[229],
            uut.fetch_stage.instr_mem[237], uut.fetch_stage.instr_mem[236], uut.fetch_stage.instr_mem[235], uut.fetch_stage.instr_mem[234],
            uut.fetch_stage.instr_mem[233], uut.fetch_stage.instr_mem[232], uut.fetch_stage.instr_mem[231], uut.fetch_stage.instr_mem[230]);
        $display("PC=0xEE: %02h %02h       -> addq %%r14, %%rbp (SKIPPED by jge)",
            uut.fetch_stage.instr_mem[238], uut.fetch_stage.instr_mem[239]);
        $display("PC=0xF0: %02h %02h%02h%02h%02h%02h%02h%02h%02h -> jg   | ~(SF^OF)&~ZF = 1 -> JUMP",
            uut.fetch_stage.instr_mem[240],
            uut.fetch_stage.instr_mem[248], uut.fetch_stage.instr_mem[247], uut.fetch_stage.instr_mem[246], uut.fetch_stage.instr_mem[245],
            uut.fetch_stage.instr_mem[244], uut.fetch_stage.instr_mem[243], uut.fetch_stage.instr_mem[242], uut.fetch_stage.instr_mem[241]);
        $display("PC=0xF9: %02h %02h       -> addq %%r14, %%rbp (SKIPPED by jg)",
            uut.fetch_stage.instr_mem[249], uut.fetch_stage.instr_mem[250]);
        $display("PC=0xFB: %02h %02h%02h%02h%02h%02h%02h%02h%02h -> jmp  | unconditional -> JUMP",
            uut.fetch_stage.instr_mem[251],
            uut.fetch_stage.instr_mem[259], uut.fetch_stage.instr_mem[258], uut.fetch_stage.instr_mem[257], uut.fetch_stage.instr_mem[256],
            uut.fetch_stage.instr_mem[255], uut.fetch_stage.instr_mem[254], uut.fetch_stage.instr_mem[253], uut.fetch_stage.instr_mem[252]);
        $display("PC=0x104: %02h %02h      -> addq %%r14, %%rbp (SKIPPED by jmp)",
            uut.fetch_stage.instr_mem[260], uut.fetch_stage.instr_mem[261]);
        $display("--- Expected: rbp = 3 (jle, jl, je NOT taken) ---");
        
        $display("\n--- PUSHL, POPL, CALL, RET ---");
        $display("PC=0x106: %02h %02h      -> pushq %%rsi",
            uut.fetch_stage.instr_mem[262], uut.fetch_stage.instr_mem[263]);
        $display("PC=0x108: %02h %02h %02h%02h%02h%02h%02h%02h%02h%02h -> irmovq $123, %%rsi",
            uut.fetch_stage.instr_mem[264], uut.fetch_stage.instr_mem[265],
            uut.fetch_stage.instr_mem[273], uut.fetch_stage.instr_mem[272], uut.fetch_stage.instr_mem[271], uut.fetch_stage.instr_mem[270],
            uut.fetch_stage.instr_mem[269], uut.fetch_stage.instr_mem[268], uut.fetch_stage.instr_mem[267], uut.fetch_stage.instr_mem[266]);
        $display("PC=0x112: %02h %02h      -> popq %%r14",
            uut.fetch_stage.instr_mem[274], uut.fetch_stage.instr_mem[275]);
        $display("PC=0x114: %02h %02h%02h%02h%02h%02h%02h%02h%02h -> call 0x120",
            uut.fetch_stage.instr_mem[276],
            uut.fetch_stage.instr_mem[284], uut.fetch_stage.instr_mem[283], uut.fetch_stage.instr_mem[282], uut.fetch_stage.instr_mem[281],
            uut.fetch_stage.instr_mem[280], uut.fetch_stage.instr_mem[279], uut.fetch_stage.instr_mem[278], uut.fetch_stage.instr_mem[277]);
        $display("PC=0x11D: %02h          -> halt",
            uut.fetch_stage.instr_mem[285]);
        $display("PC=0x120: %02h          -> ret",
            uut.fetch_stage.instr_mem[288]);
        
        $display("========================================\n");
        
        // ==================== 启动测试 ====================
        #5 rst_n = 1;
    end

endmodule
