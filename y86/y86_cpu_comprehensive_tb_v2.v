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
    
    // Y86-64 instruction codes
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
        $display("测试指令序列:");
        $display("  PC=0x00: NOP");
        $display("  PC=0x01-0x0A: irmovq $100, %%rsp");
        $display("  PC=0x0B-0x14: irmovq $10, %%rax");
        $display("  PC=0x15-0x1E: irmovq $20, %%rbx");
        $display("  PC=0x1F-0x20: rrmovq %%rax, %%rcx (RRMOVL ifun=0)");
        $display("  PC=0x21-0x22: addq %%rbx, %%rax (ALU ifun=0)");
        $display("  PC=0x23-0x24: subq %%rbx, %%rax (ALU ifun=1)");
        $display("  PC=0x25-0x26: andq %%rbx, %%rax (ALU ifun=2)");
        $display("  PC=0x27-0x28: xorq %%rbx, %%rax (ALU ifun=3)");
        $display("  PC=0x29-0x32: irmovq $5, %%rax (清除ZF)");
        $display("  PC=0x33-0x34: cmovle %%rbx, %%rdx (RRMOVL ifun=1)");
        $display("  PC=0x35-0x36: cmovl %%rbx, %%rdx (RRMOVL ifun=2)");
        $display("  PC=0x37-0x38: cmove %%rbx, %%rdx (RRMOVL ifun=3)");
        $display("  PC=0x39-0x3A: cmovne %%rbx, %%rdx (RRMOVL ifun=4)");
        $display("  PC=0x3B-0x3C: cmovge %%rbx, %%rdx (RRMOVL ifun=5)");
        $display("  PC=0x3D-0x3E: cmovg %%rbx, %%rdx (RRMOVL ifun=6)");
        $display("  PC=0x3F-0x48: rmmovq %%rax, 16(%%rsp)");
        $display("  PC=0x49-0x52: mrmovq 16(%%rsp), %%rcx");
        $display("  PC=0x53-0x54: addq %%rcx, %%rax (清除ZF)");
        $display("  PC=0x55-0x5D: jle 0x60 (JXX ifun=1, 不应跳转)");
        $display("  PC=0x5E: nop (继续执行)");
        $display("  PC=0x60: jl 0x69 (JXX ifun=2, 不应跳转)");
        $display("  PC=0x69: je 0x72 (JXX ifun=3, 不应跳转)");
        $display("  PC=0x72: jne 0x7B (JXX ifun=4, 应该跳转)");
        $display("  PC=0x7B: jge 0x84 (JXX ifun=5, 应该跳转)");
        $display("  PC=0x84: jg 0x8D (JXX ifun=6, 应该跳转)");
        $display("  PC=0x8D: jmp 0x96 (JXX ifun=0, 无条件跳转)");
        $display("  PC=0x96-0x9F: pushq %%rax (PUSHL)");
        $display("  PC=0xA0-0xA1: popq %%rbx (POPL)");
        $display("  PC=0xA2-0xAA: call 0xC0 (CALL)");
        $display("  PC=0xC0: ret (RET)");
        $display("  PC=0xAB: halt (HALT)");
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
        
        // PC=11/0x0B: irmovq $10, %rax (10字节)
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
        
        // PC=21/0x15: irmovq $20, %rbx (10字节)
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
        
        // PC=31/0x1F: rrmovq %rax, %rcx (2字节) - RRMOVL ifun=0
        uut.fetch_stage.instr_mem[31] = 8'h20;
        uut.fetch_stage.instr_mem[32] = 8'h01;
        
        // PC=33/0x21: addq %rbx, %rax (2字节) - ALU ifun=0
        uut.fetch_stage.instr_mem[33] = 8'h60;
        uut.fetch_stage.instr_mem[34] = 8'h30;
        
        // PC=35/0x23: subq %rbx, %rax (2字节) - ALU ifun=1
        uut.fetch_stage.instr_mem[35] = 8'h61;
        uut.fetch_stage.instr_mem[36] = 8'h30;
        
        // PC=37/0x25: andq %rbx, %rax (2字节) - ALU ifun=2
        uut.fetch_stage.instr_mem[37] = 8'h62;
        uut.fetch_stage.instr_mem[38] = 8'h30;
        
        // PC=39/0x27: xorq %rbx, %rax (2字节) - ALU ifun=3
        uut.fetch_stage.instr_mem[39] = 8'h63;
        uut.fetch_stage.instr_mem[40] = 8'h30;
        
        // PC=41/0x29: irmovq $5, %rax (10字节) - 清除ZF，设置非零值
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
        
        // PC=51/0x33: cmovle %rbx, %rdx (2字节) - RRMOVL ifun=1
        uut.fetch_stage.instr_mem[51] = 8'h21;
        uut.fetch_stage.instr_mem[52] = 8'h32;
        
        // PC=53/0x35: cmovl %rbx, %rdx (2字节) - RRMOVL ifun=2
        uut.fetch_stage.instr_mem[53] = 8'h22;
        uut.fetch_stage.instr_mem[54] = 8'h32;
        
        // PC=55/0x37: cmove %rbx, %rdx (2字节) - RRMOVL ifun=3
        uut.fetch_stage.instr_mem[55] = 8'h23;
        uut.fetch_stage.instr_mem[56] = 8'h32;
        
        // PC=57/0x39: cmovne %rbx, %rdx (2字节) - RRMOVL ifun=4
        uut.fetch_stage.instr_mem[57] = 8'h24;
        uut.fetch_stage.instr_mem[58] = 8'h32;
        
        // PC=59/0x3B: cmovge %rbx, %rdx (2字节) - RRMOVL ifun=5
        uut.fetch_stage.instr_mem[59] = 8'h25;
        uut.fetch_stage.instr_mem[60] = 8'h32;
        
        // PC=61/0x3D: cmovg %rbx, %rdx (2字节) - RRMOVL ifun=6
        uut.fetch_stage.instr_mem[61] = 8'h26;
        uut.fetch_stage.instr_mem[62] = 8'h32;
        
        // PC=63/0x3F: rmmovq %rax, 16(%rsp) (10字节)
        uut.fetch_stage.instr_mem[63] = 8'h40;
        uut.fetch_stage.instr_mem[64] = 8'h04;
        uut.fetch_stage.instr_mem[65] = 8'h10;
        uut.fetch_stage.instr_mem[66] = 8'h00;
        uut.fetch_stage.instr_mem[67] = 8'h00;
        uut.fetch_stage.instr_mem[68] = 8'h00;
        uut.fetch_stage.instr_mem[69] = 8'h00;
        uut.fetch_stage.instr_mem[70] = 8'h00;
        uut.fetch_stage.instr_mem[71] = 8'h00;
        uut.fetch_stage.instr_mem[72] = 8'h00;
        
        // PC=73/0x49: mrmovq 16(%rsp), %rcx (10字节)
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
        
        // PC=83/0x53: addq %rcx, %rax (2字节) - 清除ZF标志（5+5=10, ZF=0）
        uut.fetch_stage.instr_mem[83] = 8'h60;
        uut.fetch_stage.instr_mem[84] = 8'h10;
        
        // PC=85/0x55: jle 0x65 (9字节) - JXX ifun=1 (不应跳转，因为ZF=0, SF=0, OF=0)
        uut.fetch_stage.instr_mem[85] = 8'h71;
        uut.fetch_stage.instr_mem[86] = 8'h65;
        uut.fetch_stage.instr_mem[87] = 8'h00;
        uut.fetch_stage.instr_mem[88] = 8'h00;
        uut.fetch_stage.instr_mem[89] = 8'h00;
        uut.fetch_stage.instr_mem[90] = 8'h00;
        uut.fetch_stage.instr_mem[91] = 8'h00;
        uut.fetch_stage.instr_mem[92] = 8'h00;
        uut.fetch_stage.instr_mem[93] = 8'h00;
        
        // PC=94/0x5E: jmp 0x69 (9字节) - JXX ifun=0，无条件跳转到其他JXX测试
        uut.fetch_stage.instr_mem[94] = 8'h70;
        uut.fetch_stage.instr_mem[95] = 8'h69;
        uut.fetch_stage.instr_mem[96] = 8'h00;
        uut.fetch_stage.instr_mem[97] = 8'h00;
        uut.fetch_stage.instr_mem[98] = 8'h00;
        uut.fetch_stage.instr_mem[99] = 8'h00;
        uut.fetch_stage.instr_mem[100] = 8'h00;
        uut.fetch_stage.instr_mem[101] = 8'h00;
        uut.fetch_stage.instr_mem[102] = 8'h00;
        
        // PC=103/0x67: jl 0x72 (9字节) - JXX ifun=2 (不应跳转)
        uut.fetch_stage.instr_mem[103] = 8'h72;
        uut.fetch_stage.instr_mem[104] = 8'h72;
        uut.fetch_stage.instr_mem[105] = 8'h00;
        uut.fetch_stage.instr_mem[106] = 8'h00;
        uut.fetch_stage.instr_mem[107] = 8'h00;
        uut.fetch_stage.instr_mem[108] = 8'h00;
        uut.fetch_stage.instr_mem[109] = 8'h00;
        uut.fetch_stage.instr_mem[110] = 8'h00;
        uut.fetch_stage.instr_mem[111] = 8'h00;
        
        // PC=112/0x70: je 0x7B (9字节) - JXX ifun=3 (不应跳转，ZF=0)
        uut.fetch_stage.instr_mem[112] = 8'h73;
        uut.fetch_stage.instr_mem[113] = 8'h7B;
        uut.fetch_stage.instr_mem[114] = 8'h00;
        uut.fetch_stage.instr_mem[115] = 8'h00;
        uut.fetch_stage.instr_mem[116] = 8'h00;
        uut.fetch_stage.instr_mem[117] = 8'h00;
        uut.fetch_stage.instr_mem[118] = 8'h00;
        uut.fetch_stage.instr_mem[119] = 8'h00;
        uut.fetch_stage.instr_mem[120] = 8'h00;
        
        // PC=121/0x79: jne 0x84 (9字节) - JXX ifun=4 (应该跳转，ZF=0)
        uut.fetch_stage.instr_mem[121] = 8'h74;
        uut.fetch_stage.instr_mem[122] = 8'h84;
        uut.fetch_stage.instr_mem[123] = 8'h00;
        uut.fetch_stage.instr_mem[124] = 8'h00;
        uut.fetch_stage.instr_mem[125] = 8'h00;
        uut.fetch_stage.instr_mem[126] = 8'h00;
        uut.fetch_stage.instr_mem[127] = 8'h00;
        uut.fetch_stage.instr_mem[128] = 8'h00;
        uut.fetch_stage.instr_mem[129] = 8'h00;
        
        // PC=130/0x82: jge 0x8D (9字节) - JXX ifun=5 (应该跳转)
        uut.fetch_stage.instr_mem[130] = 8'h75;
        uut.fetch_stage.instr_mem[131] = 8'h8D;
        uut.fetch_stage.instr_mem[132] = 8'h00;
        uut.fetch_stage.instr_mem[133] = 8'h00;
        uut.fetch_stage.instr_mem[134] = 8'h00;
        uut.fetch_stage.instr_mem[135] = 8'h00;
        uut.fetch_stage.instr_mem[136] = 8'h00;
        uut.fetch_stage.instr_mem[137] = 8'h00;
        uut.fetch_stage.instr_mem[138] = 8'h00;
        
        // PC=139/0x8B: jg 0x96 (9字节) - JXX ifun=6 (应该跳转)
        uut.fetch_stage.instr_mem[139] = 8'h76;
        uut.fetch_stage.instr_mem[140] = 8'h96;
        uut.fetch_stage.instr_mem[141] = 8'h00;
        uut.fetch_stage.instr_mem[142] = 8'h00;
        uut.fetch_stage.instr_mem[143] = 8'h00;
        uut.fetch_stage.instr_mem[144] = 8'h00;
        uut.fetch_stage.instr_mem[145] = 8'h00;
        uut.fetch_stage.instr_mem[146] = 8'h00;
        uut.fetch_stage.instr_mem[147] = 8'h00;
        
        // PC=148/0x94: nop (1字节) - 填充
        uut.fetch_stage.instr_mem[148] = 8'h00;
        
        // PC=149/0x95: nop (1字节) - 填充
        uut.fetch_stage.instr_mem[149] = 8'h00;
        uut.fetch_stage.instr_mem[143] = 8'h00;
        uut.fetch_stage.instr_mem[144] = 8'h00;
        uut.fetch_stage.instr_mem[145] = 8'h00;
        uut.fetch_stage.instr_mem[146] = 8'h00;
        uut.fetch_stage.instr_mem[147] = 8'h00;
        uut.fetch_stage.instr_mem[148] = 8'h00;
        uut.fetch_stage.instr_mem[149] = 8'h00;
        
        // PC=150/0x96: pushq %rax (2字节) - PUSHL
        uut.fetch_stage.instr_mem[150] = 8'hA0;
        uut.fetch_stage.instr_mem[151] = 8'hF0;
        
        // PC=152/0x98: irmovq $30, %rax (10字节) - 改变%rax值后再pop
        uut.fetch_stage.instr_mem[152] = 8'h30;
        uut.fetch_stage.instr_mem[153] = 8'hF0;
        uut.fetch_stage.instr_mem[154] = 8'h1E;
        uut.fetch_stage.instr_mem[155] = 8'h00;
        uut.fetch_stage.instr_mem[156] = 8'h00;
        uut.fetch_stage.instr_mem[157] = 8'h00;
        uut.fetch_stage.instr_mem[158] = 8'h00;
        uut.fetch_stage.instr_mem[159] = 8'h00;
        uut.fetch_stage.instr_mem[160] = 8'h00;
        uut.fetch_stage.instr_mem[161] = 8'h00;
        
        // PC=162/0xA2: popq %rbx (2字节) - POPL
        uut.fetch_stage.instr_mem[162] = 8'hB0;
        uut.fetch_stage.instr_mem[163] = 8'hF3;
        
        // PC=164/0xA4: call 0xC0 (9字节) - CALL
        uut.fetch_stage.instr_mem[164] = 8'h80;
        uut.fetch_stage.instr_mem[165] = 8'hC0;
        uut.fetch_stage.instr_mem[166] = 8'h00;
        uut.fetch_stage.instr_mem[167] = 8'h00;
        uut.fetch_stage.instr_mem[168] = 8'h00;
        uut.fetch_stage.instr_mem[169] = 8'h00;
        uut.fetch_stage.instr_mem[170] = 8'h00;
        uut.fetch_stage.instr_mem[171] = 8'h00;
        uut.fetch_stage.instr_mem[172] = 8'h00;
        
        // PC=173/0xAD: halt (1字节) - 从call返回后halt
        uut.fetch_stage.instr_mem[173] = 8'h10;
        
        // PC=192/0xC0: ret (1字节) - RET
        uut.fetch_stage.instr_mem[192] = 8'h90;
        
        // 初始化其他内存位置为NOP
        for (integer i = 193; i < 1024; i = i + 1) begin
            uut.fetch_stage.instr_mem[i] = 8'h00;
        end
        
        // ==================== 启动测试 ====================
        
        #5 rst_n = 1;
        
        // 等待足够的周期让所有指令执行完成
        #10000;
        
        $display("\n========================================");
        $display("=== Test Complete ===");
        $display("========================================");
        
        $display("\n寄存器状态:");
        $display("  %%rax = %h (expected: 0x23 from 5+5+30-1)", uut.decode_stage.regfile[0]);
        $display("  %%rbx = %h (expected: 5, pop from stack)", uut.decode_stage.regfile[3]);
        $display("  %%rcx = %h (expected: 5, from mrmovq)", uut.decode_stage.regfile[1]);
        $display("  %%rdx = %h (expected: 20, from cmov)", uut.decode_stage.regfile[2]);
        $display("  %%rsp = %h", uut.decode_stage.regfile[4]);
        
        $display("\nCPU Status: %b (expected: 01 for HALT)", Stat);
        $display("Final PC: %h (expected: AD after return)", PC);
        
        $finish;
    end

endmodule
