`timescale 1ps/1ps

module write_back_tb;

    // Inputs
    reg [3:0] icode;
    reg [63:0] valE;
    reg [63:0] valM;
    reg instr_valid;
    reg imem_error;
    reg dmem_error;
    
    // Outputs
    wire [63:0] valE_o;
    wire [63:0] valM_o;
    wire [1:0] stat_o;
    
    // Instantiate the write_back module
    write_back uut (
        .icode_i(icode),
        .valE_i(valE),
        .valM_i(valM),
        .instr_valid_i(instr_valid),
        .imem_error_i(imem_error),
        .dmem_error_i(dmem_error),
        .valE_o(valE_o),
        .valM_o(valM_o),
        .stat_o(stat_o)
    );
    
    initial begin
        $display("=== Write Back Stage Test ===");
        
        // Test 1: 正常状态
        $display("\nTest 1: Normal Operation (AOK)");
        icode = 4'h2;           // RRMOVL
        valE = 64'h1234567890ABCDEF;
        valM = 64'hFEDCBA0987654321;
        instr_valid = 1'b1;
        imem_error = 1'b0;
        dmem_error = 1'b0;
        #10;
        $display("valE_o = 0x%h, valM_o = 0x%h, stat_o = %b", valE_o, valM_o, stat_o);
        if (valE_o == valE && valM_o == valM && stat_o == 2'b00)
            $display("PASS: Values passed through correctly, status is AOK");
        else
            $display("FAIL: Expected AOK status");
        
        // Test 2: 非法指令
        $display("\nTest 2: Invalid Instruction (INS)");
        icode = 4'hF;
        valE = 64'h1111111111111111;
        valM = 64'h2222222222222222;
        instr_valid = 1'b0;     // 非法指令
        imem_error = 1'b0;
        dmem_error = 1'b0;
        #10;
        $display("valE_o = 0x%h, valM_o = 0x%h, stat_o = %b", valE_o, valM_o, stat_o);
        if (stat_o == 2'b11)
            $display("PASS: Status is INS (Invalid Instruction)");
        else
            $display("FAIL: Expected INS status");
        
        // Test 3: 指令内存错误
        $display("\nTest 3: Instruction Memory Error (ADR)");
        icode = 4'h3;
        valE = 64'h3333333333333333;
        valM = 64'h4444444444444444;
        instr_valid = 1'b1;
        imem_error = 1'b1;      // 指令内存错误
        dmem_error = 1'b0;
        #10;
        $display("valE_o = 0x%h, valM_o = 0x%h, stat_o = %b", valE_o, valM_o, stat_o);
        if (stat_o == 2'b10)
            $display("PASS: Status is ADR (Address Error - IMEM)");
        else
            $display("FAIL: Expected ADR status");
        
        // Test 4: 数据内存错误
        $display("\nTest 4: Data Memory Error (ADR)");
        icode = 4'h5;           // MRMOVL
        valE = 64'h5555555555555555;
        valM = 64'h6666666666666666;
        instr_valid = 1'b1;
        imem_error = 1'b0;
        dmem_error = 1'b1;      // 数据内存错误
        #10;
        $display("valE_o = 0x%h, valM_o = 0x%h, stat_o = %b", valE_o, valM_o, stat_o);
        if (stat_o == 2'b10)
            $display("PASS: Status is ADR (Address Error - DMEM)");
        else
            $display("FAIL: Expected ADR status");
        
        // Test 5: 多个错误（优先级测试）
        $display("\nTest 5: Multiple Errors - Priority Test (IMEM > INS > DMEM)");
        icode = 4'hF;
        valE = 64'h7777777777777777;
        valM = 64'h8888888888888888;
        instr_valid = 1'b0;     // 非法指令
        imem_error = 1'b1;      // 指令内存错误（优先级更高）
        dmem_error = 1'b1;      // 数据内存错误
        #10;
        $display("valE_o = 0x%h, valM_o = 0x%h, stat_o = %b", valE_o, valM_o, stat_o);
        if (stat_o == 2'b10)
            $display("PASS: IMEM error has highest priority");
        else
            $display("FAIL: Expected ADR status (IMEM priority)");
        
        $display("\n=== All Tests Completed ===");
        $finish;
    end

endmodule
