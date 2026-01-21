`timescale 1ps/1ps

module y86_cpu_comprehensive_tb;

    // Clock and Reset
    reg clk;
    reg rst_n;
    
    // CPU输出信号
    wire [1:0] stat;
    wire [63:0] PC;
    wire [3:0] icode;
    
    // 内部信号监控
    wire [63:0] npc;
    wire [3:0] ifun;
    wire [3:0] rA;
    wire [3:0] rB;
    wire [63:0] valC;
    wire [63:0] valP;
    wire [63:0] valA;
    wire [63:0] valB;
    wire [63:0] valE_exe;
    wire [63:0] valM_mem;
    wire [63:0] valE_wb;
    wire [63:0] valM_wb;
    wire [1:0] Stat;
    
    // Instantiate the Y86 CPU
    y86_cpu uut (
        .clk_i(clk),
        .rst_n_i(rst_n),
        .stat_o(stat),
        .PC_o(PC),
        .icode_o(icode)
    );
    
    // 连接内部信号用于监控
    assign npc = uut.pc_update_stage.new_PC;
    assign ifun = uut.ifun;
    assign rA = uut.rA;
    assign rB = uut.rB;
    assign valC = uut.valC;
    assign valP = uut.valP;
    assign valA = uut.valA;
    assign valB = uut.valB;
    assign valE_exe = uut.valE;
    assign valM_mem = uut.valM;
    assign valE_wb = uut.valE_wb;
    assign valM_wb = uut.valM_wb;
    assign Stat = uut.stat_o;
    
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
    
    // 初始化
    initial begin
        clk = 0;
        rst_n = 0;
    end
    
    // 时钟生成 (20ps 周期)
    always #10 clk = ~clk;
    
    // PC 更新监控
    always @ (posedge clk) begin
        if (rst_n) begin
            // PC 更新逻辑由模块内部处理
        end
    end
    
    // 超时控制
    initial begin
        #50000 $stop;
    end
    
    // 状态监控和显示
    initial begin
        forever @ (posedge clk) begin
            if (rst_n) begin
                $display("Cycle: PC=%h, icode=%h, ifun=%h, rA=%h, rB=%h, valC=%h, valP=%h,",
                         PC, icode, ifun, rA, rB, valC, valP);
                $display("       valA=%h, valB=%h, valE=%h, valM=%h, valE_wb=%h, valM_wb=%h, npc=%h, Stat=%b",
                         valA, valB, valE_exe, valM_mem, valE_wb, valM_wb, npc, Stat);
            end
        end
    end
    
    // 测试程序
    initial begin
        $display("========================================");
        $display("=== Y86-64 Comprehensive CPU Test ===");
        $display("========================================\n");
        
        // ==================== 加载指令到内存 ====================
        
        // PC=0: NOP (1字节)
        uut.fetch_stage.instr_mem[0] = 8'h00;
        
        // PC=1: irmovq $100, %rsp (10字节) - 初始化栈指针
        uut.fetch_stage.instr_mem[1] = 8'h30;
        uut.fetch_stage.instr_mem[2] = 8'hF4;
        uut.fetch_stage.instr_mem[3] = 8'h64;
        uut.fetch_stage.instr_mem[4] = 8'h00;
        uut.fetch_stage.instr_mem[5] = 8'h00;
        uut.fetch_stage.instr_mem[6] = 8'h00;
        uut.fetch_stage.instr_mem[7] = 8'h00;
        uut.fetch_stage.instr_mem[8] = 8'h00;
        uut.fetch_stage.instr_mem[9] = 8'h00;
        uut.fetch_stage.instr_mem[10] = 8'h00;
        
        // PC=11: irmovq $10, %rax (10字节)
        uut.fetch_stage.instr_mem[11] = 8'h30;
        uut.fetch_stage.instr_mem[12] = 8'hF0;
        uut.fetch_stage.instr_mem[13] = 8'h0A;
        uut.fetch_stage.instr_mem[14] = 8'h00;
        uut.fetch_stage.instr_mem[15] = 8'h00;
        uut.fetch_stage.instr_mem[16] = 8'h00;
        uut.fetch_stage.instr_mem[17] = 8'h00;
        uut.fetch_stage.instr_mem[18] = 8'h00;
        uut.fetch_stage.instr_mem[19] = 8'h00;
        uut.fetch_stage.instr_mem[20] = 8'h00;
        
        // PC=21: irmovq $20, %rbx (10字节)
        uut.fetch_stage.instr_mem[21] = 8'h30;
        uut.fetch_stage.instr_mem[22] = 8'hF3;
        uut.fetch_stage.instr_mem[23] = 8'h14;
        uut.fetch_stage.instr_mem[24] = 8'h00;
        uut.fetch_stage.instr_mem[25] = 8'h00;
        uut.fetch_stage.instr_mem[26] = 8'h00;
        uut.fetch_stage.instr_mem[27] = 8'h00;
        uut.fetch_stage.instr_mem[28] = 8'h00;
        uut.fetch_stage.instr_mem[29] = 8'h00;
        uut.fetch_stage.instr_mem[30] = 8'h00;
        
        // PC=31: rrmovq %rax, %rcx (2字节) - ifun=0
        uut.fetch_stage.instr_mem[31] = 8'h20;
        uut.fetch_stage.instr_mem[32] = 8'h01;
        
        // PC=33: addq %rbx, %rax (2字节) - ALU ifun=0
        uut.fetch_stage.instr_mem[33] = 8'h60;
        uut.fetch_stage.instr_mem[34] = 8'h30;
        
        // PC=35: subq %rbx, %rax (2字节) - ALU ifun=1
        uut.fetch_stage.instr_mem[35] = 8'h61;
        uut.fetch_stage.instr_mem[36] = 8'h30;
        
        // PC=37: andq %rbx, %rax (2字节) - ALU ifun=2
        uut.fetch_stage.instr_mem[37] = 8'h62;
        uut.fetch_stage.instr_mem[38] = 8'h30;
        
        // PC=39: xorq %rbx, %rax (2字节) - ALU ifun=3
        uut.fetch_stage.instr_mem[39] = 8'h63;
        uut.fetch_stage.instr_mem[40] = 8'h30;
        
        // PC=41: cmovle %rbx, %rdx (2字节) - RRMOVL ifun=1
        uut.fetch_stage.instr_mem[41] = 8'h21;
        uut.fetch_stage.instr_mem[42] = 8'h32;
        
        // PC=43: cmovl %rbx, %rdx (2字节) - RRMOVL ifun=2
        uut.fetch_stage.instr_mem[43] = 8'h22;
        uut.fetch_stage.instr_mem[44] = 8'h32;
        
        // PC=45: cmove %rbx, %rdx (2字节) - RRMOVL ifun=3
        uut.fetch_stage.instr_mem[45] = 8'h23;
        uut.fetch_stage.instr_mem[46] = 8'h32;
        
        // PC=47: cmovne %rbx, %rdx (2字节) - RRMOVL ifun=4
        uut.fetch_stage.instr_mem[47] = 8'h24;
        uut.fetch_stage.instr_mem[48] = 8'h32;
        
        // PC=49: cmovge %rbx, %rdx (2字节) - RRMOVL ifun=5
        uut.fetch_stage.instr_mem[49] = 8'h25;
        uut.fetch_stage.instr_mem[50] = 8'h32;
        
        // PC=51: cmovg %rbx, %rdx (2字节) - RRMOVL ifun=6
        uut.fetch_stage.instr_mem[51] = 8'h26;
        uut.fetch_stage.instr_mem[52] = 8'h32;
        
        // PC=53: jmp 0x50 (9字节) - JXX ifun=0
        uut.fetch_stage.instr_mem[53] = 8'h70;
        uut.fetch_stage.instr_mem[54] = 8'h50;
        uut.fetch_stage.instr_mem[55] = 8'h00;
        uut.fetch_stage.instr_mem[56] = 8'h00;
        uut.fetch_stage.instr_mem[57] = 8'h00;
        uut.fetch_stage.instr_mem[58] = 8'h00;
        uut.fetch_stage.instr_mem[59] = 8'h00;
        uut.fetch_stage.instr_mem[60] = 8'h00;
        uut.fetch_stage.instr_mem[61] = 8'h00;
        
        // PC=62: jle 0x50 (9字节) - JXX ifun=1
        uut.fetch_stage.instr_mem[62] = 8'h71;
        uut.fetch_stage.instr_mem[63] = 8'h50;
        uut.fetch_stage.instr_mem[64] = 8'h00;
        uut.fetch_stage.instr_mem[65] = 8'h00;
        uut.fetch_stage.instr_mem[66] = 8'h00;
        uut.fetch_stage.instr_mem[67] = 8'h00;
        uut.fetch_stage.instr_mem[68] = 8'h00;
        uut.fetch_stage.instr_mem[69] = 8'h00;
        uut.fetch_stage.instr_mem[70] = 8'h00;
        
        // PC=71: jl 0x50 (9字节) - JXX ifun=2
        uut.fetch_stage.instr_mem[71] = 8'h72;
        uut.fetch_stage.instr_mem[72] = 8'h50;
        uut.fetch_stage.instr_mem[73] = 8'h00;
        uut.fetch_stage.instr_mem[74] = 8'h00;
        uut.fetch_stage.instr_mem[75] = 8'h00;
        uut.fetch_stage.instr_mem[76] = 8'h00;
        uut.fetch_stage.instr_mem[77] = 8'h00;
        uut.fetch_stage.instr_mem[78] = 8'h00;
        uut.fetch_stage.instr_mem[79] = 8'h00;
        
        // PC=80 (0x50): 跳转目标位置
        // je 0x90 (9字节) - JXX ifun=3
        uut.fetch_stage.instr_mem[80] = 8'h73;
        uut.fetch_stage.instr_mem[81] = 8'h90;
        uut.fetch_stage.instr_mem[82] = 8'h00;
        uut.fetch_stage.instr_mem[83] = 8'h00;
        uut.fetch_stage.instr_mem[84] = 8'h00;
        uut.fetch_stage.instr_mem[85] = 8'h00;
        uut.fetch_stage.instr_mem[86] = 8'h00;
        uut.fetch_stage.instr_mem[87] = 8'h00;
        uut.fetch_stage.instr_mem[88] = 8'h00;
        
        // PC=89: jne 0x90 (9字节) - JXX ifun=4
        uut.fetch_stage.instr_mem[89] = 8'h74;
        uut.fetch_stage.instr_mem[90] = 8'h90;
        uut.fetch_stage.instr_mem[91] = 8'h00;
        uut.fetch_stage.instr_mem[92] = 8'h00;
        uut.fetch_stage.instr_mem[93] = 8'h00;
        uut.fetch_stage.instr_mem[94] = 8'h00;
        uut.fetch_stage.instr_mem[95] = 8'h00;
        uut.fetch_stage.instr_mem[96] = 8'h00;
        uut.fetch_stage.instr_mem[97] = 8'h00;
        
        // PC=98: jge 0x90 (9字节) - JXX ifun=5
        uut.fetch_stage.instr_mem[98] = 8'h75;
        uut.fetch_stage.instr_mem[99] = 8'h90;
        uut.fetch_stage.instr_mem[100] = 8'h00;
        uut.fetch_stage.instr_mem[101] = 8'h00;
        uut.fetch_stage.instr_mem[102] = 8'h00;
        uut.fetch_stage.instr_mem[103] = 8'h00;
        uut.fetch_stage.instr_mem[104] = 8'h00;
        uut.fetch_stage.instr_mem[105] = 8'h00;
        uut.fetch_stage.instr_mem[106] = 8'h00;
        
        // PC=107: jg 0x90 (9字节) - JXX ifun=6
        uut.fetch_stage.instr_mem[107] = 8'h76;
        uut.fetch_stage.instr_mem[108] = 8'h90;
        uut.fetch_stage.instr_mem[109] = 8'h00;
        uut.fetch_stage.instr_mem[110] = 8'h00;
        uut.fetch_stage.instr_mem[111] = 8'h00;
        uut.fetch_stage.instr_mem[112] = 8'h00;
        uut.fetch_stage.instr_mem[113] = 8'h00;
        uut.fetch_stage.instr_mem[114] = 8'h00;
        uut.fetch_stage.instr_mem[115] = 8'h00;
        
        // PC=116: rmmovq %rax, 16(%rsp) (10字节)
        uut.fetch_stage.instr_mem[116] = 8'h40;
        uut.fetch_stage.instr_mem[117] = 8'h04;
        uut.fetch_stage.instr_mem[118] = 8'h10;
        uut.fetch_stage.instr_mem[119] = 8'h00;
        uut.fetch_stage.instr_mem[120] = 8'h00;
        uut.fetch_stage.instr_mem[121] = 8'h00;
        uut.fetch_stage.instr_mem[122] = 8'h00;
        uut.fetch_stage.instr_mem[123] = 8'h00;
        uut.fetch_stage.instr_mem[124] = 8'h00;
        uut.fetch_stage.instr_mem[125] = 8'h00;
        
        // PC=126: mrmovq 16(%rsp), %rbp (10字节)
        uut.fetch_stage.instr_mem[126] = 8'h50;
        uut.fetch_stage.instr_mem[127] = 8'h54;
        uut.fetch_stage.instr_mem[128] = 8'h10;
        uut.fetch_stage.instr_mem[129] = 8'h00;
        uut.fetch_stage.instr_mem[130] = 8'h00;
        uut.fetch_stage.instr_mem[131] = 8'h00;
        uut.fetch_stage.instr_mem[132] = 8'h00;
        uut.fetch_stage.instr_mem[133] = 8'h00;
        uut.fetch_stage.instr_mem[134] = 8'h00;
        uut.fetch_stage.instr_mem[135] = 8'h00;
        
        // PC=136: pushq %rax (2字节)
        uut.fetch_stage.instr_mem[136] = 8'hA0;
        uut.fetch_stage.instr_mem[137] = 8'h0F;
        
        // PC=138: popq %rsi (2字节)
        uut.fetch_stage.instr_mem[138] = 8'hB0;
        uut.fetch_stage.instr_mem[139] = 8'h6F;
        
        // PC=140 (0x8C): call 0xA0 (9字节)
        uut.fetch_stage.instr_mem[140] = 8'h80;
        uut.fetch_stage.instr_mem[141] = 8'hA0;
        uut.fetch_stage.instr_mem[142] = 8'h00;
        uut.fetch_stage.instr_mem[143] = 8'h00;
        uut.fetch_stage.instr_mem[144] = 8'h00;
        uut.fetch_stage.instr_mem[145] = 8'h00;
        uut.fetch_stage.instr_mem[146] = 8'h00;
        uut.fetch_stage.instr_mem[147] = 8'h00;
        uut.fetch_stage.instr_mem[148] = 8'h00;
        
        // PC=149: halt (1字节)
        uut.fetch_stage.instr_mem[149] = 8'h10;
        
        // PC=160 (0xA0): 函数入口
        // irmovq $99, %rdi (10字节)
        uut.fetch_stage.instr_mem[160] = 8'h30;
        uut.fetch_stage.instr_mem[161] = 8'hF7;
        uut.fetch_stage.instr_mem[162] = 8'h63;
        uut.fetch_stage.instr_mem[163] = 8'h00;
        uut.fetch_stage.instr_mem[164] = 8'h00;
        uut.fetch_stage.instr_mem[165] = 8'h00;
        uut.fetch_stage.instr_mem[166] = 8'h00;
        uut.fetch_stage.instr_mem[167] = 8'h00;
        uut.fetch_stage.instr_mem[168] = 8'h00;
        uut.fetch_stage.instr_mem[169] = 8'h00;
        
        // PC=170: ret (1字节)
        uut.fetch_stage.instr_mem[170] = 8'h90;
        
        $display("Program Instructions Loaded:\n");
        $display("  0x00: nop");
        $display("  0x01: irmovq $100, %%rsp");
        $display("  0x0B: irmovq $10, %%rax");
        $display("  0x15: irmovq $20, %%rbx");
        $display("  0x1F: rrmovq %%rax, %%rcx (ifun=0)");
        $display("  0x21: addq %%rbx, %%rax (ALU ifun=0)");
        $display("  0x23: subq %%rbx, %%rax (ALU ifun=1)");
        $display("  0x25: andq %%rbx, %%rax (ALU ifun=2)");
        $display("  0x27: xorq %%rbx, %%rax (ALU ifun=3)");
        $display("  0x29: cmovle %%rbx, %%rdx (RRMOVL ifun=1)");
        $display("  0x2B: cmovl %%rbx, %%rdx (RRMOVL ifun=2)");
        $display("  0x2D: cmove %%rbx, %%rdx (RRMOVL ifun=3)");
        $display("  0x2F: cmovne %%rbx, %%rdx (RRMOVL ifun=4)");
        $display("  0x31: cmovge %%rbx, %%rdx (RRMOVL ifun=5)");
        $display("  0x33: cmovg %%rbx, %%rdx (RRMOVL ifun=6)");
        $display("  0x35: jmp 0x50 (JXX ifun=0)");
        $display("  0x50: je 0x90 (JXX ifun=3)");
        $display("  0x59: jne 0x90 (JXX ifun=4)");
        $display("  0x62: jge 0x90 (JXX ifun=5)");
        $display("  0x6B: jg 0x90 (JXX ifun=6)");
        $display("  0x74: rmmovq %%rax, 16(%%rsp)");
        $display("  0x7E: mrmovq 16(%%rsp), %%rbp");
        $display("  0x88: pushq %%rax");
        $display("  0x8A: popq %%rsi");
        $display("  0x8C: call 0xA0");
        $display("  0x95: halt");
        $display("  0xA0: irmovq $99, %%rdi (function entry)");
        $display("  0xAA: ret\n");
        
        // 释放复位
        #15 rst_n = 1;
        $display("CPU Reset Released at time %0t\n", $time);
        
        // 等待足够的周期让程序执行
        #10000;
        
        // 显示最终寄存器状态
        $display("\n========================================");
        $display("=== Final Register State ===");
        $display("========================================");
        $display("%%rax:  0x%016h", uut.decode_stage.regfile[0]);
        $display("%%rcx:  0x%016h", uut.decode_stage.regfile[1]);
        $display("%%rdx:  0x%016h", uut.decode_stage.regfile[2]);
        $display("%%rbx:  0x%016h", uut.decode_stage.regfile[3]);
        $display("%%rsp:  0x%016h", uut.decode_stage.regfile[4]);
        $display("%%rbp:  0x%016h", uut.decode_stage.regfile[5]);
        $display("%%rsi:  0x%016h", uut.decode_stage.regfile[6]);
        $display("%%rdi:  0x%016h", uut.decode_stage.regfile[7]);
        
        $display("\n=== Test Complete ===\n");
        $finish;
    end

endmodule
