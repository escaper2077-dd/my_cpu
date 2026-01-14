`timescale 1ps/1ps

module fetch_tb_enhanced();

    // 信号声明
    reg  [63:0] PC_i;
    wire [3:0]  icode_o;
    wire [3:0]  ifun_o;
    wire [3:0]  rA_o;
    wire [3:0]  rB_o;
    wire [63:0] valC_o;
    wire [63:0] valP_o;
    wire        instr_valid_o;
    wire        imem_error_o;

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

    // 测试计数器
    integer pass_count;
    integer fail_count;

    // 测试激励
    initial begin
        pass_count = 0;
        fail_count = 0;

        // 初始化指令内存
        
        // 测试用例1-7: 基本指令 (1-2字节)
        fetch_inst.instr_mem[0] = 8'h00;      // NOP
        fetch_inst.instr_mem[1] = 8'h10;      // HALT
        fetch_inst.instr_mem[2] = 8'h20;      // RRMOVQ
        fetch_inst.instr_mem[3] = 8'h34;
        fetch_inst.instr_mem[4] = 8'h61;      // OPQ (add)
        fetch_inst.instr_mem[5] = 8'h56;
        fetch_inst.instr_mem[6] = 8'h62;      // OPQ (sub)
        fetch_inst.instr_mem[7] = 8'hAB;
        fetch_inst.instr_mem[8] = 8'hA0;      // PUSHQ
        fetch_inst.instr_mem[9] = 8'hF5;
        
        // 测试用例: IRMOVQ (10字节)
        fetch_inst.instr_mem[10] = 8'h30;
        fetch_inst.instr_mem[11] = 8'hF5;
        fetch_inst.instr_mem[12] = 8'h11;     // valC = 0x1122334455667788
        fetch_inst.instr_mem[13] = 8'h22;
        fetch_inst.instr_mem[14] = 8'h33;
        fetch_inst.instr_mem[15] = 8'h44;
        fetch_inst.instr_mem[16] = 8'h55;
        fetch_inst.instr_mem[17] = 8'h66;
        fetch_inst.instr_mem[18] = 8'h77;
        fetch_inst.instr_mem[19] = 8'h88;
        
        // 测试用例: JXX (5字节)
        fetch_inst.instr_mem[20] = 8'h70;     // JMP
        fetch_inst.instr_mem[21] = 8'hFF;     // valC = 0x0000000000001000
        fetch_inst.instr_mem[22] = 8'h00;
        fetch_inst.instr_mem[23] = 8'h00;
        fetch_inst.instr_mem[24] = 8'h10;
        
        // 测试用例: 无效指令
        fetch_inst.instr_mem[25] = 8'hCC;     // Invalid (icode=C)
        fetch_inst.instr_mem[26] = 8'hDD;     // Invalid (icode=D)

        $display("\n");
        $display("╔════════════════════════════════════════════════════════════╗");
        $display("║    Y86-64 Fetch Stage - Enhanced Testbench (VCS Compatible) ║");
        $display("╚════════════════════════════════════════════════════════════╝");
        $display("\n");

        // ========== Test 1: NOP (1字节) ==========
        $display("[Test 1] NOP Instruction at PC=0");
        PC_i = 64'd0;
        #10;
        if ((valP_o == 64'd1) && (icode_o == 4'h0) && (instr_valid_o == 1'b1)) begin
            $display("✓ PASS\n");
            pass_count = pass_count + 1;
        end else begin
            $display("✗ FAIL - Expected: valP=1, icode=0, valid=1");
            $display("         Got:      valP=%h, icode=%h, valid=%b\n", valP_o, icode_o, instr_valid_o);
            fail_count = fail_count + 1;
        end

        // ========== Test 2: HALT (1字节) ==========
        $display("[Test 2] HALT Instruction at PC=1");
        PC_i = 64'd1;
        #10;
        if ((valP_o == 64'd2) && (icode_o == 4'h1) && (instr_valid_o == 1'b1)) begin
            $display("✓ PASS\n");
            pass_count = pass_count + 1;
        end else begin
            $display("✗ FAIL - Expected: valP=2, icode=1, valid=1");
            $display("         Got:      valP=%h, icode=%h, valid=%b\n", valP_o, icode_o, instr_valid_o);
            fail_count = fail_count + 1;
        end

        // ========== Test 3: RRMOVQ (2字节) ==========
        $display("[Test 3] RRMOVQ Instruction at PC=2 (icode=2, rA=3, rB=4)");
        PC_i = 64'd2;
        #10;
        if ((valP_o == 64'd4) && (icode_o == 4'h2) && (rA_o == 4'h3) && (rB_o == 4'h4) && (instr_valid_o == 1'b1)) begin
            $display("✓ PASS\n");
            pass_count = pass_count + 1;
        end else begin
            $display("✗ FAIL - Expected: valP=4, icode=2, rA=3, rB=4, valid=1");
            $display("         Got:      valP=%h, icode=%h, rA=%h, rB=%h, valid=%b\n", 
                     valP_o, icode_o, rA_o, rB_o, instr_valid_o);
            fail_count = fail_count + 1;
        end

        // ========== Test 4: OPQ-ADD (2字节) ==========
        $display("[Test 4] OPQ (ADD) Instruction at PC=4 (icode=6, ifun=1, rA=5, rB=6)");
        PC_i = 64'd4;
        #10;
        if ((valP_o == 64'd6) && (icode_o == 4'h6) && (ifun_o == 4'h1)) begin
            $display("✓ PASS\n");
            pass_count = pass_count + 1;
        end else begin
            $display("✗ FAIL - Expected: valP=6, icode=6, ifun=1");
            $display("         Got:      valP=%h, icode=%h, ifun=%h\n", valP_o, icode_o, ifun_o);
            fail_count = fail_count + 1;
        end

        // ========== Test 5: OPQ-SUB (2字节) ==========
        $display("[Test 5] OPQ (SUB) Instruction at PC=6 (icode=6, ifun=2)");
        PC_i = 64'd6;
        #10;
        if ((valP_o == 64'd8) && (icode_o == 4'h6) && (ifun_o == 4'h2)) begin
            $display("✓ PASS\n");
            pass_count = pass_count + 1;
        end else begin
            $display("✗ FAIL - Expected: valP=8, icode=6, ifun=2");
            $display("         Got:      valP=%h, icode=%h, ifun=%h\n", valP_o, icode_o, ifun_o);
            fail_count = fail_count + 1;
        end

        // ========== Test 6: PUSHQ (2字节) ==========
        $display("[Test 6] PUSHQ Instruction at PC=8 (icode=A, rA=F, rB=5)");
        PC_i = 64'd8;
        #10;
        if ((valP_o == 64'd10) && (icode_o == 4'hA) && (instr_valid_o == 1'b1)) begin
            $display("✓ PASS\n");
            pass_count = pass_count + 1;
        end else begin
            $display("✗ FAIL - Expected: valP=10, icode=A, valid=1");
            $display("         Got:      valP=%h, icode=%h, valid=%b\n", valP_o, icode_o, instr_valid_o);
            fail_count = fail_count + 1;
        end

        // ========== Test 7: IRMOVQ (10字节，需要valC) ==========
        $display("[Test 7] IRMOVQ Instruction at PC=10 (icode=3, need_regids=1, need_valC=1)");
        PC_i = 64'd10;
        #10;
        $display("         Expected: valP=0x18 (10+1+1+8), icode=3, rA=F, rB=5");
        $display("         Got:      valP=%h, icode=%h, rA=%h, rB=%h, valC=%h",
                 valP_o, icode_o, rA_o, rB_o, valC_o);
        if (valP_o == 64'd24) begin
            $display("✓ PASS\n");
            pass_count = pass_count + 1;
        end else begin
            $display("✗ FAIL\n");
            fail_count = fail_count + 1;
        end

        // ========== Test 8: JXX (5字节，需要valC，但不需要regids) ==========
        $display("[Test 8] JMP Instruction at PC=20 (icode=7, need_regids=0, need_valC=1)");
        PC_i = 64'd20;
        #10;
        $display("         Expected: valP=0x19 (20+1+0+8), icode=7, rA=F, rB=F");
        $display("         Got:      valP=%h, icode=%h, rA=%h, rB=%h, valC=%h",
                 valP_o, icode_o, rA_o, rB_o, valC_o);
        if (valP_o == 64'd29) begin
            $display("✓ PASS\n");
            pass_count = pass_count + 1;
        end else begin
            $display("✗ FAIL\n");
            fail_count = fail_count + 1;
        end

        // ========== Test 9: Invalid Instruction (icode=C) ==========
        $display("[Test 9] Invalid Instruction (icode=12)");
        PC_i = 64'd25;
        #10;
        if (instr_valid_o == 1'b0) begin
            $display("✓ PASS - Correctly identified as invalid\n");
            pass_count = pass_count + 1;
        end else begin
            $display("✗ FAIL - Should be invalid\n");
            fail_count = fail_count + 1;
        end

        // ========== Test 10: Invalid Instruction (icode=D) ==========
        $display("[Test 10] Invalid Instruction (icode=13)");
        PC_i = 64'd26;
        #10;
        if (instr_valid_o == 1'b0) begin
            $display("✓ PASS - Correctly identified as invalid\n");
            pass_count = pass_count + 1;
        end else begin
            $display("✗ FAIL - Should be invalid\n");
            fail_count = fail_count + 1;
        end

        // ========== Test 11: Memory Out of Bounds ==========
        $display("[Test 11] Memory Out of Bounds (PC > 1023)");
        PC_i = 64'd2048;
        #10;
        if (imem_error_o == 1'b1) begin
            $display("✓ PASS - Correctly detected memory error\n");
            pass_count = pass_count + 1;
        end else begin
            $display("✗ FAIL - Should have memory error\n");
            fail_count = fail_count + 1;
        end

        // ========== Test Summary ==========
        $display("╔════════════════════════════════════════════════════════════╗");
        $display("║                      Test Summary                           ║");
        $display("╠════════════════════════════════════════════════════════════╣");
        $display("║  PASS: %3d                                                  ║", pass_count);
        $display("║  FAIL: %3d                                                  ║", fail_count);
        $display("║  Total: %2d                                                 ║", pass_count + fail_count);
        $display("╚════════════════════════════════════════════════════════════╝");
        $display("\n");

        $finish;
    end

endmodule
