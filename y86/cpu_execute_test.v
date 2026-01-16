`timescale 1ps/1ps

module cpu_execute_test();

    // 时钟和复位
    reg clk_i;
    reg rst_n_i;
    
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
    
    // Execute输出
    wire [63:0] valE_execute;
    wire Cnd_execute;
    
    // PC信号
    reg [63:0] PC_i;

    // 实例化Fetch模块
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
    
    // 实例化Decode模块
    decode decode_inst (
        .icode_i(icode_o),
        .rA_i(rA_o),
        .rB_i(rB_o),
        .valA_o(valA_decode),
        .valB_o(valB_decode)
    );
    
    // 实例化Execute模块
    execute execute_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .icode_i(icode_o),
        .ifun_i(ifun_o),
        .valA_i(valA_decode),
        .valB_i(valB_decode),
        .valC_i(valC_o),
        .valE_o(valE_execute),
        .Cnd_o(Cnd_execute)
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
    
    // RRMOVL func码定义
    localparam RRMOV_RRMOVL = 4'h0;  // 无条件移动
    localparam RRMOV_CMOVLE = 4'h1;  // 小于等于时移动
    localparam RRMOV_CMOVL  = 4'h2;  // 小于时移动
    localparam RRMOV_CMOVE  = 4'h3;  // 等于时移动
    localparam RRMOV_CMOVNE = 4'h4;  // 不等于时移动
    localparam RRMOV_CMOVGE = 4'h5;  // 大于等于时移动
    localparam RRMOV_CMOVG  = 4'h6;  // 大于时移动

    initial begin
        clk_i = 1'b0;
        forever #5 clk_i = ~clk_i;
    end

    initial begin
        // 初始化复位
        rst_n_i = 1'b0;
        PC_i = 64'h0;
        
        // 加载指令到指令内存
        // PC=0: ADDL (2字节) - icode=6, ifun=0
        // 指令格式: [icode|ifun][rA|rB]
        fetch_inst.instr_mem[0] = 8'h60;  // icode=6(ALU), ifun=0(ADDL)
        fetch_inst.instr_mem[1] = 8'h01;  // rA=0(%rax), rB=1(%rcx)
        
        // PC=2: SUBL (2字节) - icode=6, ifun=1
        fetch_inst.instr_mem[2] = 8'h61;  // icode=6(ALU), ifun=1(SUBL)
        fetch_inst.instr_mem[3] = 8'h01;  // rA=0(%rax), rB=1(%rcx)
        
        // PC=4: CMOVE (2字节) - icode=2, ifun=3
        fetch_inst.instr_mem[4] = 8'h23;  // icode=2(RRMOVL), ifun=3(CMOVE)
        fetch_inst.instr_mem[5] = 8'h01;  // rA=0(%rax), rB=1(%rcx)
        
        // PC=6: JE (9字节) - 条件跳转
        fetch_inst.instr_mem[6] = 8'h73;  // icode=7(JXX), ifun=3(JE)
        fetch_inst.instr_mem[7]  = 8'h00;
        fetch_inst.instr_mem[8]  = 8'h00;
        fetch_inst.instr_mem[9]  = 8'h00;
        fetch_inst.instr_mem[10] = 8'h00;
        fetch_inst.instr_mem[11] = 8'h00;
        fetch_inst.instr_mem[12] = 8'h00;
        fetch_inst.instr_mem[13] = 8'h00;
        fetch_inst.instr_mem[14] = 8'h00;
        
        #100;
        rst_n_i = 1'b1;
        
        $display("\n================ Y86 CPU Three-Stage Integration Test ================\n");
        
        // ========== Test 1: ADDL指令 ==========
        $display("========== Test 1: ADDL (Add) at PC=0 ==========");
        $display("寄存器初始值: %rax=0, %rcx=1");
        $display("指令: ADDL %%rax, %%rcx (icode=6, ifun=0, rA=0, rB=1)");
        PC_i = 64'h0;
        #10;
        $display("Fetch => icode=%h, ifun=%h, rA=%h, rB=%h, valC=%016h", 
                 icode_o, ifun_o, rA_o, rB_o, valC_o);
        $display("Decode => valA=%016h (from %%rax), valB=%016h (from %%rcx)", 
                 valA_decode, valB_decode);
        #10;
        $display("Execute => valE=%016h (result), ZF=%d, SF=%d, Cnd=%d\n", 
                 valE_execute, execute_inst.ZF, execute_inst.SF, Cnd_execute);
        
        // ========== Test 2: SUBL指令（改变条件码） ==========
        $display("========== Test 2: SUBL (Subtract) at PC=2 ==========");
        $display("前一条指令设置的条件码: ZF=%d, SF=%d", 
                 execute_inst.ZF, execute_inst.SF);
        $display("指令: SUBL %%rax, %%rcx (icode=6, ifun=1, rA=0, rB=1)");
        PC_i = 64'h2;
        #10;
        $display("Fetch => icode=%h, ifun=%h, rA=%h, rB=%h", 
                 icode_o, ifun_o, rA_o, rB_o);
        $display("Decode => valA=%016h (from %%rax), valB=%016h (from %%rcx)", 
                 valA_decode, valB_decode);
        #10;
        $display("Execute => valE=%016h (result), ZF=%d, SF=%d, Cnd=%d", 
                 valE_execute, execute_inst.ZF, execute_inst.SF, Cnd_execute);
        $display("说明: 1 - 0 = 1 (正数), SF应该为0, ZF应该为0\n");
        
        // ========== Test 3: CMOVE条件移动 ==========
        $display("========== Test 3: CMOVE at PC=4 ==========");
        $display("前一条SUBL设置的条件码: ZF=%d, SF=%d", 
                 execute_inst.ZF, execute_inst.SF);
        $display("指令: CMOVE %%rax, %%rcx (icode=2, ifun=3, RRMOV条件移动)");
        PC_i = 64'h4;
        #10;
        $display("Fetch => icode=%h, ifun=%h (RRMOVL条件编码: 0=无条件, 1-6=条件移动)", 
                 icode_o, ifun_o);
        $display("Decode => valA=%016h (源寄存器), valB=%016h", 
                 valA_decode, valB_decode);
        #10;
        $display("Execute => valE=%016h (要写入的值), Cnd=%d (条件满足时移动)", 
                 valE_execute, Cnd_execute);
        $display("说明: CMOVE在ZF=1时执行，当前ZF=%d，所以Cnd=%d表示%s\n", 
                 execute_inst.ZF, Cnd_execute, Cnd_execute ? "条件满足，可以移动" : "条件不满足，不移动");
        
        // ========== Test 4: 条件跳转（JE）==========
        $display("========== Test 4: JE (Jump if Equal) at PC=6 ==========");
        $display("前面指令设置的条件码: ZF=%d, SF=%d", 
                 execute_inst.ZF, execute_inst.SF);
        $display("指令: JE 0x... (icode=7, ifun=3, 需要ZF=1才跳转)");
        PC_i = 64'h6;
        #10;
        $display("Fetch => icode=%h, ifun=%h, valC=%016h", 
                 icode_o, ifun_o, valC_o);
        $display("Execute => Cnd=%d (跳转条件%s, ZF=%d)", 
                 Cnd_execute, Cnd_execute ? "满足" : "不满足", execute_inst.ZF);
        $display("说明: 由于ZF=0，JE条件不满足，不会跳转\n");
        
        $display("================ Integration Test Complete ================\n");
        
        // 详细说明
        $display("执行阶段关键特性：");
        $display("1. valE_o是组合逻辑输出，可以直接被内存阶段或写回阶段使用");
        $display("2. Cnd_o表示条件跳转是否满足，用于PC控制逻辑");
        $display("3. 条件码在时钟上升沿更新，使得前面的ALU指令可以为后续指令设置条件");
        $display("4. 每条指令的valE计算方式不同，根据指令的功能选择:");
        $display("   - ALU: 运算结果");
        $display("   - RRMOVL: valA（源寄存器）");
        $display("   - 内存操作: 地址计算（基址+偏移）");
        $display("   - 栈操作: 栈指针调整（±8）");
        
        #10;
        $finish;
    end

endmodule
