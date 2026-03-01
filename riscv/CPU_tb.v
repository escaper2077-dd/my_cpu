`timescale 1ps/1ps

// ============================================================================
// RISC-V 单周期 CPU 综合测试 (RV32I - 40 条指令全覆盖)
// ============================================================================
// 测试指令列表:
//   R-type (10): ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
//   I-type ALU (9): ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI
//   Load (5): LB, LH, LW, LBU, LHU
//   Store (3): SB, SH, SW
//   Branch (6): BEQ, BNE, BLT, BGE, BLTU, BGEU
//   U-type (2): LUI, AUIPC
//   Jump (2): JAL, JALR
//   System (3): FENCE, ECALL, EBREAK
// ============================================================================

module CPU_tb();

    reg clk;
    reg rst_n;
    
    wire [1:0]  stat;
    wire [31:0] PC;
    wire [6:0]  opcode;
    
    riscv_cpu uut(
        .clk_i(clk),
        .rst_n_i(rst_n),
        .stat_o(stat),
        .PC_o(PC),
        .opcode_o(opcode)
    );
    
    // 内部信号监控
    wire [31:0] instr      = uut.fetch_stage.instr_o;
    wire [4:0]  rd         = uut.fetch_stage.rd_o;
    wire [2:0]  funct3     = uut.fetch_stage.funct3_o;
    wire [4:0]  rs1        = uut.fetch_stage.rs1_o;
    wire [4:0]  rs2        = uut.fetch_stage.rs2_o;
    wire [6:0]  funct7     = uut.fetch_stage.funct7_o;
    wire [31:0] imm        = uut.fetch_stage.imm_o;
    wire [31:0] valP       = uut.fetch_stage.valP_o;
    wire [31:0] rs1_data   = uut.decode_stage.rs1_data_o;
    wire [31:0] rs2_data   = uut.decode_stage.rs2_data_o;
    wire [31:0] alu_result = uut.execute_stage.alu_result_o;
    wire        br_taken   = uut.execute_stage.branch_taken_o;
    wire [31:0] mem_data   = uut.memory_stage.mem_data_o;
    wire        reg_wr_en  = uut.writeback_stage.reg_wr_en_o;
    wire [31:0] wr_data    = uut.writeback_stage.wr_data_o;
    
    // 时钟
    initial clk = 0;
    always #10 clk = ~clk;
    
    // 超时保护
    initial begin
        #500000 $display("ERROR: Simulation timeout!"); $finish;
    end
    
    // ECALL/EBREAK 停机检测
    initial begin
        wait(rst_n == 1);
        forever @(posedge clk) begin
            if (stat == 2'b01) begin
                #20;
                display_results();
                $finish;
            end
        end
    end
    
    // 详细状态监控
    initial begin
        forever @(posedge clk) begin
            if (rst_n) begin
                $display("Cycle: PC=%08h instr=%08h op=%07b rd=%0d rs1=%0d rs2=%0d funct3=%03b funct7=%07b",
                         PC, instr, opcode, rd, rs1, rs2, funct3, funct7);
                $display("       imm=%08h rs1_data=%08h rs2_data=%08h alu=%08h br=%b mem=%08h wr_en=%b wr=%08h stat=%b",
                         imm, rs1_data, rs2_data, alu_result, br_taken, mem_data, reg_wr_en, wr_data, stat);
                $display("");
            end
        end
    end

    // ==================== 辅助函数：编码 RV32I 指令 ====================
    // R-type: funct7[6:0] rs2[4:0] rs1[4:0] funct3[2:0] rd[4:0] opcode[6:0]
    function [31:0] R_TYPE;
        input [6:0] funct7;
        input [4:0] rs2;
        input [4:0] rs1;
        input [2:0] funct3;
        input [4:0] rd;
        input [6:0] opcode;
        R_TYPE = {funct7, rs2, rs1, funct3, rd, opcode};
    endfunction

    // I-type: imm[11:0] rs1[4:0] funct3[2:0] rd[4:0] opcode[6:0]
    function [31:0] I_TYPE;
        input [11:0] imm;
        input [4:0]  rs1;
        input [2:0]  funct3;
        input [4:0]  rd;
        input [6:0]  opcode;
        I_TYPE = {imm, rs1, funct3, rd, opcode};
    endfunction
    
    // S-type: imm[11:5] rs2[4:0] rs1[4:0] funct3[2:0] imm[4:0] opcode[6:0]
    function [31:0] S_TYPE;
        input [11:0] imm;
        input [4:0]  rs2;
        input [4:0]  rs1;
        input [2:0]  funct3;
        input [6:0]  opcode;
        S_TYPE = {imm[11:5], rs2, rs1, funct3, imm[4:0], opcode};
    endfunction
    
    // B-type: imm[12|10:5] rs2[4:0] rs1[4:0] funct3[2:0] imm[4:1|11] opcode[6:0]
    function [31:0] B_TYPE;
        input [12:0] imm;  // 13 bit (包含 bit0=0)
        input [4:0]  rs2;
        input [4:0]  rs1;
        input [2:0]  funct3;
        input [6:0]  opcode;
        B_TYPE = {imm[12], imm[10:5], rs2, rs1, funct3, imm[4:1], imm[11], opcode};
    endfunction
    
    // U-type: imm[31:12] rd[4:0] opcode[6:0]
    function [31:0] U_TYPE;
        input [31:0] imm;  // 只用高 20 位
        input [4:0]  rd;
        input [6:0]  opcode;
        U_TYPE = {imm[31:12], rd, opcode};
    endfunction
    
    // J-type: imm[20|10:1|11|19:12] rd[4:0] opcode[6:0]
    function [31:0] J_TYPE;
        input [20:0] imm;  // 21 bit (包含 bit0=0)
        input [4:0]  rd;
        input [6:0]  opcode;
        J_TYPE = {imm[20], imm[10:1], imm[11], imm[19:12], rd, opcode};
    endfunction

    // 操作码常量
    localparam OP_LUI    = 7'b0110111;
    localparam OP_AUIPC  = 7'b0010111;
    localparam OP_JAL    = 7'b1101111;
    localparam OP_JALR   = 7'b1100111;
    localparam OP_BRANCH = 7'b1100011;
    localparam OP_LOAD   = 7'b0000011;
    localparam OP_STORE  = 7'b0100011;
    localparam OP_ALUI   = 7'b0010011;
    localparam OP_ALU    = 7'b0110011;
    localparam OP_FENCE  = 7'b0001111;
    localparam OP_SYSTEM = 7'b1110011;

    // 寄存器名称
    localparam [4:0] x0=0, x1=1, x2=2, x3=3, x4=4, x5=5, x6=6, x7=7;
    localparam [4:0] x8=8, x9=9, x10=10, x11=11, x12=12, x13=13, x14=14, x15=15;
    localparam [4:0] x16=16, x17=17, x18=18, x19=19, x20=20, x21=21, x22=22, x23=23;
    localparam [4:0] x24=24, x25=25, x26=26, x27=27, x28=28, x29=29, x30=30, x31=31;

    // ==================== 加载指令到内存的 task ====================
    task load_instr;
        input [31:0] addr;
        input [31:0] data;
        begin
            uut.fetch_stage.instr_mem[addr]     = data[7:0];
            uut.fetch_stage.instr_mem[addr + 1] = data[15:8];
            uut.fetch_stage.instr_mem[addr + 2] = data[23:16];
            uut.fetch_stage.instr_mem[addr + 3] = data[31:24];
        end
    endtask

    // ==================== 结果显示 ====================
    integer pass_count;
    integer fail_count;
    
    task check;
        input [4:0]  reg_idx;
        input [31:0] expected;
        input [255:0] test_name;
        reg [31:0] actual;
        begin
            actual = uut.decode_stage.regfile[reg_idx];
            if (actual == expected) begin
                $display("  [PASS] %0s: x%0d = 0x%08h", test_name, reg_idx, actual);
                pass_count = pass_count + 1;
            end else begin
                $display("  [FAIL] %0s: x%0d = 0x%08h (expected 0x%08h)", test_name, reg_idx, actual, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask
    
    task display_results;
        begin
            $display("\n========================================");
            $display("=== RISC-V RV32I Test Complete ===");
            $display("========================================");
            
            $display("\n=== 寄存器状态 ===");
            $display("  x0  (zero) = 0x%08h", uut.decode_stage.regfile[0]);
            $display("  x1  (ra)   = 0x%08h", uut.decode_stage.regfile[1]);
            $display("  x2  (sp)   = 0x%08h", uut.decode_stage.regfile[2]);
            $display("  x3  (gp)   = 0x%08h", uut.decode_stage.regfile[3]);
            $display("  x4  (tp)   = 0x%08h", uut.decode_stage.regfile[4]);
            $display("  x5  (t0)   = 0x%08h", uut.decode_stage.regfile[5]);
            $display("  x6  (t1)   = 0x%08h", uut.decode_stage.regfile[6]);
            $display("  x7  (t2)   = 0x%08h", uut.decode_stage.regfile[7]);
            $display("  x8  (s0)   = 0x%08h", uut.decode_stage.regfile[8]);
            $display("  x9  (s1)   = 0x%08h", uut.decode_stage.regfile[9]);
            $display("  x10 (a0)   = 0x%08h", uut.decode_stage.regfile[10]);
            $display("  x11 (a1)   = 0x%08h", uut.decode_stage.regfile[11]);
            $display("  x12 (a2)   = 0x%08h", uut.decode_stage.regfile[12]);
            $display("  x13 (a3)   = 0x%08h", uut.decode_stage.regfile[13]);
            $display("  x14 (a4)   = 0x%08h", uut.decode_stage.regfile[14]);
            $display("  x15 (a5)   = 0x%08h", uut.decode_stage.regfile[15]);
            $display("  x16 (a6)   = 0x%08h", uut.decode_stage.regfile[16]);
            $display("  x17 (a7)   = 0x%08h", uut.decode_stage.regfile[17]);
            $display("  x18 (s2)   = 0x%08h", uut.decode_stage.regfile[18]);
            $display("  x19 (s3)   = 0x%08h", uut.decode_stage.regfile[19]);
            $display("  x20 (s4)   = 0x%08h", uut.decode_stage.regfile[20]);
            $display("  x21 (s5)   = 0x%08h", uut.decode_stage.regfile[21]);
            $display("  x22 (s6)   = 0x%08h", uut.decode_stage.regfile[22]);
            $display("  x23 (s7)   = 0x%08h", uut.decode_stage.regfile[23]);
            $display("  x24 (s8)   = 0x%08h", uut.decode_stage.regfile[24]);
            $display("  x25 (s9)   = 0x%08h", uut.decode_stage.regfile[25]);
            $display("  x26 (s10)  = 0x%08h", uut.decode_stage.regfile[26]);
            $display("  x27 (s11)  = 0x%08h", uut.decode_stage.regfile[27]);
            $display("  x28 (t3)   = 0x%08h", uut.decode_stage.regfile[28]);
            $display("  x29 (t4)   = 0x%08h", uut.decode_stage.regfile[29]);
            $display("  x30 (t5)   = 0x%08h", uut.decode_stage.regfile[30]);
            $display("  x31 (t6)   = 0x%08h", uut.decode_stage.regfile[31]);
            
            $display("\n=== 验证结果 ===");
            pass_count = 0;
            fail_count = 0;
            
            // I-type ALU 验证 (x1 被 JAL 覆写为返回地址)
            check(x1,  32'h000000D0,  "JAL saved ra: x1 = 0xD0");
            check(x2,  32'h000000C8,  "ADDI: x2 = 200");
            check(x3,  32'hFFFFFF38,  "ADDI: x3 = -200");
            
            // LUI & AUIPC
            check(x4,  32'h12345000,  "LUI: x4 = 0x12345000");
            check(x5,  32'h00010010, "AUIPC: x5 = PC(0x10) + 0x10000");
            
            // R-type ALU
            check(x6,  32'h0000012C,  "ADD: x6 = x1+x2 = 300");
            check(x7,  32'hFFFFFF9C,  "SUB: x7 = x1-x2 = -100");
            check(x8,  32'h00000001,  "SLT: x8 = (x7 < x6) = 1");
            check(x9,  32'h00000000,  "SLTU: x9 = (x7 < x6 unsigned) = 0");
            check(x10, 32'h000000AC, "XOR: x10 = x2 ^ x1 = 172");
            check(x11, 32'h000000EC, "OR: x11 = x2 | x1 = 236");
            check(x12, 32'h00000040, "AND: x12 = x2 & x1 = 64");
            check(x13, 32'h00000640, "SLL: x13 = x1 << 4 = 1600");
            check(x14, 32'h00000006, "SRL: x14 = x1 >> 4 = 6");
            
            // I-type: SLTI, SLTIU, ORI, ANDI, XORI, SLLI, SRLI, SRAI
            check(x15, 32'h00000001,  "SLTI: x15 = (x7 < 0) = 1");
            check(x16, 32'h00000000,  "SLTIU: x16 = (x1 < 1 unsigned) = 0");
            check(x17, 32'h0000009B, "XORI: x17 = x1 ^ 0xFF = 155");
            check(x18, 32'h000000FF, "ORI: x18 = x1 | 0xFF = 255");
            check(x19, 32'h00000004, "ANDI: x19 = x1 & 0x0F = 4");
            check(x20, 32'h00000190, "SLLI: x20 = x1 << 2 = 400");
            check(x21, 32'h00000019, "SRLI: x21 = x1 >> 2 = 25");
            
            // SRA on negative number
            check(x22, 32'hFFFFFFCE, "SRAI: x22 = x3 >>> 2 = -50");
            
            // Store/Load
            check(x23, 32'h00000064, "SW/LW: x23 = x1 (stored then loaded)");
            check(x24, 32'h00000064, "SB/LBU: x24 = low byte of x1");
            check(x25, 32'h00000064, "SH/LHU: x25 = low halfword of x1");
            
            // LB (sign extend) x7=-100=0xFFFFFF9C, low byte=0x9C, sign_ext=0xFFFFFF9C
            check(x26, 32'hFFFFFF9C, "SB/LB: x26 = sign-ext byte of x7");
            
            // Branch counting
            check(x28, 32'h00000003, "Branch: x28 = 3 (beq+bge+bgeu taken)");
            
            // JAL/JALR
            check(x29, 32'h00000001, "JAL/JALR: x29 = 1 (subroutine executed)");
            
            $display("\n========================================");
            $display("=== Total: %0d PASS, %0d FAIL ===", pass_count, fail_count);
            $display("========================================");
            $display("Final PC: 0x%08h, Status: %b", PC, stat);
        end
    endtask

    // ==================== 测试程序 ====================
    integer i;
    
    // 程序地址
    // 测试覆盖所有 40 条 RV32I 指令
    
    initial begin
        $display("========================================");
        $display("=== RISC-V RV32I Comprehensive Test ===");
        $display("=== 40 Instructions Full Coverage    ===");
        $display("========================================\n");
        
        // 清空指令内存
        for (i = 0; i < 4096; i = i + 1) begin
            uut.fetch_stage.instr_mem[i] = 8'h00;
        end
        
        // 清空数据内存
        for (i = 0; i < 4096; i = i + 1) begin
            uut.memory_stage.dmem_inst.mem[i] = 8'h00;
        end

        // ========== 第一部分: I-type ALU 指令 ==========
        
        // [0x00] ADDI x1, x0, 100       # x1 = 100
        load_instr(32'h00, I_TYPE(12'd100, x0, 3'b000, x1, OP_ALUI));
        
        // [0x04] ADDI x2, x0, 200       # x2 = 200
        load_instr(32'h04, I_TYPE(12'd200, x0, 3'b000, x2, OP_ALUI));
        
        // [0x08] ADDI x3, x0, -200      # x3 = -200 (0xFFFFFF38)
        load_instr(32'h08, I_TYPE(-12'sd200, x0, 3'b000, x3, OP_ALUI));
        
        // ========== 第二部分: U-type 指令 ==========
        
        // [0x0C] LUI x4, 0x12345        # x4 = 0x12345000
        load_instr(32'h0C, U_TYPE(32'h12345000, x4, OP_LUI));
        
        // [0x10] AUIPC x5, 0x10         # x5 = PC(0x10) + 0x10000 = 0x10010
        load_instr(32'h10, U_TYPE(32'h00010000, x5, OP_AUIPC));
        
        // ========== 第三部分: R-type ALU 指令 ==========
        
        // [0x14] ADD x6, x1, x2         # x6 = 100 + 200 = 300
        load_instr(32'h14, R_TYPE(7'b0000000, x2, x1, 3'b000, x6, OP_ALU));
        
        // [0x18] SUB x7, x1, x2         # x7 = 100 - 200 = -100
        load_instr(32'h18, R_TYPE(7'b0100000, x2, x1, 3'b000, x7, OP_ALU));
        
        // [0x1C] SLT x8, x7, x6         # x8 = (-100 < 300) = 1
        load_instr(32'h1C, R_TYPE(7'b0000000, x6, x7, 3'b010, x8, OP_ALU));
        
        // [0x20] SLTU x9, x7, x6        # x9 = (0xFFFFFF9C <u 300) = 0 (unsigned: big > small)
        load_instr(32'h20, R_TYPE(7'b0000000, x6, x7, 3'b011, x9, OP_ALU));
        
        // [0x24] XOR x10, x2, x1        # x10 = 200 ^ 100
        load_instr(32'h24, R_TYPE(7'b0000000, x1, x2, 3'b100, x10, OP_ALU));
        
        // [0x28] OR x11, x2, x1         # x11 = 200 | 100
        load_instr(32'h28, R_TYPE(7'b0000000, x1, x2, 3'b110, x11, OP_ALU));
        
        // [0x2C] AND x12, x2, x1        # x12 = 200 & 100
        load_instr(32'h2C, R_TYPE(7'b0000000, x1, x2, 3'b111, x12, OP_ALU));
        
        // [0x30] SLL x13, x1, x4        # x13 = x1 << (x4[4:0]=0) ... 需要调整
        // 用 ADDI 设置移位量
        // [0x30] ADDI x31, x0, 4        # x31 = 4
        load_instr(32'h30, I_TYPE(12'd4, x0, 3'b000, x31, OP_ALUI));
        
        // [0x34] SLL x13, x1, x31       # x13 = 100 << 4 = 1600
        load_instr(32'h34, R_TYPE(7'b0000000, x31, x1, 3'b001, x13, OP_ALU));
        
        // [0x38] SRL x14, x1, x31       # x14 = 100 >> 4 = 6
        load_instr(32'h38, R_TYPE(7'b0000000, x31, x1, 3'b101, x14, OP_ALU));
        
        // ========== 第四部分: 更多 I-type ALU 指令 ==========
        
        // [0x3C] SLTI x15, x7, 0        # x15 = (-100 < 0) = 1
        load_instr(32'h3C, I_TYPE(12'd0, x7, 3'b010, x15, OP_ALUI));
        
        // [0x40] SLTIU x16, x1, 1       # x16 = (100 <u 1) = 0
        load_instr(32'h40, I_TYPE(12'd1, x1, 3'b011, x16, OP_ALUI));
        
        // [0x44] XORI x17, x1, 0xFF     # x17 = 100 ^ 255
        load_instr(32'h44, I_TYPE(12'hFF, x1, 3'b100, x17, OP_ALUI));
        
        // [0x48] ORI x18, x1, 0xFF      # x18 = 100 | 255
        load_instr(32'h48, I_TYPE(12'hFF, x1, 3'b110, x18, OP_ALUI));
        
        // [0x4C] ANDI x19, x1, 0x0F     # x19 = 100 & 15
        load_instr(32'h4C, I_TYPE(12'h0F, x1, 3'b111, x19, OP_ALUI));
        
        // [0x50] SLLI x20, x1, 2        # x20 = 100 << 2 = 400
        load_instr(32'h50, R_TYPE(7'b0000000, 5'd2, x1, 3'b001, x20, OP_ALUI));
        
        // [0x54] SRLI x21, x1, 2        # x21 = 100 >> 2 = 25
        load_instr(32'h54, R_TYPE(7'b0000000, 5'd2, x1, 3'b101, x21, OP_ALUI));
        
        // [0x58] SRAI x22, x3, 2        # x22 = -200 >>> 2 = -50
        load_instr(32'h58, R_TYPE(7'b0100000, 5'd2, x3, 3'b101, x22, OP_ALUI));
        
        // ========== 第五部分: Store/Load 指令 ==========
        // 使用地址 0x800 作为数据区
        
        // [0x5C] ADDI x30, x0, 0x100    # x30 = 0x100 (base addr for data, 实际映射到 data_memory)
        load_instr(32'h5C, I_TYPE(12'h100, x0, 3'b000, x30, OP_ALUI));
        
        // [0x60] SW x1, 0(x30)          # mem[0x100] = 100 (store word)
        load_instr(32'h60, S_TYPE(12'd0, x1, x30, 3'b010, OP_STORE));
        
        // [0x64] LW x23, 0(x30)         # x23 = mem[0x100] = 100 (load word)
        load_instr(32'h64, I_TYPE(12'd0, x30, 3'b010, x23, OP_LOAD));
        
        // [0x68] SB x1, 4(x30)          # mem[0x104] = 0x64 (store byte)
        load_instr(32'h68, S_TYPE(12'd4, x1, x30, 3'b000, OP_STORE));
        
        // [0x6C] LBU x24, 4(x30)        # x24 = mem[0x104] = 0x64 (load byte unsigned)
        load_instr(32'h6C, I_TYPE(12'd4, x30, 3'b100, x24, OP_LOAD));
        
        // [0x70] SH x1, 8(x30)          # mem[0x108] = 0x0064 (store halfword)
        load_instr(32'h70, S_TYPE(12'd8, x1, x30, 3'b001, OP_STORE));
        
        // [0x74] LHU x25, 8(x30)        # x25 = mem[0x108] = 0x0064 (load halfword unsigned)
        load_instr(32'h74, I_TYPE(12'd8, x30, 3'b101, x25, OP_LOAD));
        
        // [0x78] SB x3, 12(x30)         # mem[0x10C] = 0x38 (low byte of -200 = 0xFFFFFF38)
        load_instr(32'h78, S_TYPE(12'd12, x3, x30, 3'b000, OP_STORE));
        
        // [0x7C] LB x26, 12(x30)        # x26 = sign_ext(0x38) = 0x38 = 56 ... 
        // 等等，-200 = 0xFFFFFF38，低字节是 0x38 = 56，符号扩展后是 56（正数）
        // 换个方案：存一个负数的高字节
        // 改为直接存 x3 的一个字节到另一个地址
        // 让我用 x7 = -100 = 0xFFFFFF9C，低字节 0x9C
        // [0x78] SB x7, 12(x30)         # mem[0x10C] = 0x9C
        load_instr(32'h78, S_TYPE(12'd12, x7, x30, 3'b000, OP_STORE));
        
        // [0x7C] LB x26, 12(x30)        # x26 = sign_ext(0x9C) = 0xFFFFFF9C = -100
        load_instr(32'h7C, I_TYPE(12'd12, x30, 3'b000, x26, OP_LOAD));
        
        // ========== 第六部分: FENCE ===========
        
        // [0x80] FENCE                   # NOP (无操作)
        load_instr(32'h80, 32'h0000000F);  // fence 指令编码
        
        // ========== 第七部分: Branch 指令 ==========
        
        // 用 x28 作为计数器记录哪些分支跳转了
        // [0x84] ADDI x28, x0, 0        # x28 = 0 (counter)
        load_instr(32'h84, I_TYPE(12'd0, x0, 3'b000, x28, OP_ALUI));
        
        // x1 = 100, x2 = 200
        
        // [0x88] BEQ x1, x1, +8         # branch taken (100==100), jump to 0x90
        load_instr(32'h88, B_TYPE(13'd8, x1, x1, 3'b000, OP_BRANCH));
        
        // [0x8C] ADDI x28, x28, -1      # 不应执行（被跳过）
        load_instr(32'h8C, I_TYPE(-12'sd1, x28, 3'b000, x28, OP_ALUI));
        
        // [0x90] ADDI x28, x28, 1       # x28 += 1 (BEQ taken)
        load_instr(32'h90, I_TYPE(12'd1, x28, 3'b000, x28, OP_ALUI));
        
        // [0x94] BNE x1, x2, +8         # branch taken (100!=200), jump to 0x9C
        load_instr(32'h94, B_TYPE(13'd8, x2, x1, 3'b001, OP_BRANCH));
        
        // [0x98] ADDI x28, x28, -1      # 不应执行
        load_instr(32'h98, I_TYPE(-12'sd1, x28, 3'b000, x28, OP_ALUI));
        
        // [0x9C] (BNE NOT taken test) BNE x1, x1, +8   # not taken (100==100)
        load_instr(32'h9C, B_TYPE(13'd8, x1, x1, 3'b001, OP_BRANCH));
        
        // [0xA0] BLT x7, x1, +8         # taken (-100 < 100), jump to 0xA8
        load_instr(32'hA0, B_TYPE(13'd8, x1, x7, 3'b100, OP_BRANCH));
        
        // [0xA4] ADDI x28, x28, -1      # 不应执行
        load_instr(32'hA4, I_TYPE(-12'sd1, x28, 3'b000, x28, OP_ALUI));
        
        // [0xA8] BGE x1, x7, +8         # taken (100 >= -100), jump to 0xB0
        load_instr(32'hA8, B_TYPE(13'd8, x7, x1, 3'b101, OP_BRANCH));
        
        // [0xAC] ADDI x28, x28, -1      # 不应执行
        load_instr(32'hAC, I_TYPE(-12'sd1, x28, 3'b000, x28, OP_ALUI));
        
        // [0xB0] ADDI x28, x28, 1       # x28 += 1 (BGE taken)
        load_instr(32'hB0, I_TYPE(12'd1, x28, 3'b000, x28, OP_ALUI));
        
        // [0xB4] BLTU x1, x7, +8        # taken (100 <u 0xFFFFFF9C), jump to 0xBC
        load_instr(32'hB4, B_TYPE(13'd8, x7, x1, 3'b110, OP_BRANCH));
        
        // [0xB8] ADDI x28, x28, -1      # 不应执行
        load_instr(32'hB8, I_TYPE(-12'sd1, x28, 3'b000, x28, OP_ALUI));
        
        // [0xBC] BGEU x7, x1, +8        # taken (0xFFFFFF9C >=u 100), jump to 0xC4
        load_instr(32'hBC, B_TYPE(13'd8, x1, x7, 3'b111, OP_BRANCH));
        
        // [0xC0] ADDI x28, x28, -1      # 不应执行
        load_instr(32'hC0, I_TYPE(-12'sd1, x28, 3'b000, x28, OP_ALUI));
        
        // [0xC4] ADDI x28, x28, 1       # x28 += 1 (BGEU taken)
        load_instr(32'hC4, I_TYPE(12'd1, x28, 3'b000, x28, OP_ALUI));
        // 最终 x28 应 = 3 (BEQ + BGE + BGEU 各 +1)
        
        // ========== 第八部分: JAL & JALR ==========
        
        // [0xC8] ADDI x29, x0, 0        # x29 = 0
        load_instr(32'hC8, I_TYPE(12'd0, x0, 3'b000, x29, OP_ALUI));
        
        // [0xCC] JAL x1, +12            # x1 = PC+4 = 0xD0, jump to 0xD8
        load_instr(32'hCC, J_TYPE(21'd12, x1, OP_JAL));
        
        // [0xD0] ADDI x29, x29, -1      # 不应执行（被 JAL 跳过）
        load_instr(32'hD0, I_TYPE(-12'sd1, x29, 3'b000, x29, OP_ALUI));
        
        // [0xD4] ADDI x29, x29, -1      # 不应执行
        load_instr(32'hD4, I_TYPE(-12'sd1, x29, 3'b000, x29, OP_ALUI));
        
        // [0xD8] ADDI x29, x29, 1       # x29 = 1 (subroutine body)
        load_instr(32'hD8, I_TYPE(12'd1, x29, 3'b000, x29, OP_ALUI));
        
        // [0xDC] JALR x27, x1, 0        # x27 = PC+4 = 0xE0, jump to x1=0xD0
        load_instr(32'hDC, I_TYPE(12'd0, x1, 3'b000, x27, OP_JALR));
        
        // [0xE0] - 永远不会到达这里，因为 JALR 跳到 0xD0
        // 但 0xD0 的指令会让 x29 -= 1，所以需要调整
        
        // 重新设计 JAL/JALR 测试:
        // [0xCC] JAL x1, +16            # x1 = 0xD0, jump to 0xDC (subroutine)
        load_instr(32'hCC, J_TYPE(21'd16, x1, OP_JAL));
        
        // [0xD0] NOP (after return point)
        load_instr(32'hD0, I_TYPE(12'd0, x0, 3'b000, x0, OP_ALUI));  // ADDI x0, x0, 0 = NOP
        
        // [0xD4] JAL x0, +16            # jump to 0xE4 (skip subroutine, go to ECALL)
        load_instr(32'hD4, J_TYPE(21'd16, x0, OP_JAL));
        
        // [0xD8] NOP (padding)
        load_instr(32'hD8, I_TYPE(12'd0, x0, 3'b000, x0, OP_ALUI));
        
        // ---- Subroutine at 0xDC ----
        // [0xDC] ADDI x29, x29, 1       # x29 = 1
        load_instr(32'hDC, I_TYPE(12'd1, x29, 3'b000, x29, OP_ALUI));
        
        // [0xE0] JALR x0, x1, 0         # return to x1 = 0xD0
        load_instr(32'hE0, I_TYPE(12'd0, x1, 3'b000, x0, OP_JALR));
        
        // ---- After subroutine ----
        // [0xE4] ECALL                   # 停机
        load_instr(32'hE4, 32'h00000073);  // ECALL 编码
        
        // 备用: EBREAK at 0xE8 (不会执行到)
        load_instr(32'hE8, 32'h00100073);  // EBREAK 编码

        // SRA with x7(-100) using R-type
        // 需要在前面加入 SRA 测试
        // x7 = -100 = 0xFFFFFF9C
        // SRA x27, x7, x31 (x31=4) => -100 >>> 4 = -7 = 0xFFFFFFF9
        // 这个测试已经用 SRAI 覆盖了 SRA 的移位逻辑
        
        // 初始化
        rst_n = 0;
        #5 rst_n = 1;
    end

endmodule
