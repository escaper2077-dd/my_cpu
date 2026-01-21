`timescale 1ps/1ps

module memory_access_tb;

    // Clock
    reg clk;
    
    // Inputs
    reg [3:0] icode;
    reg [63:0] valE;
    reg [63:0] valA;
    reg [63:0] valP;
    
    // Outputs
    wire [63:0] valM;
    wire dmem_error;

    // Instantiate the Unit Under Test (UUT)
    memory_access uut (
        .clk_i(clk),
        .icode_i(icode),
        .valE_i(valE),
        .valA_i(valA),
        .valP_i(valP),
        .valM_o(valM),
        .dmem_error_o(dmem_error)
    );

    // Y86操作码定义
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

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 10ps周期
    end

    // Test stimulus
    initial begin
        // Initialize VCD dump
        //$dumpfile("memory_access_tb.vcd");
        //$dumpvars(0, memory_access_tb);
        
        // Initialize Inputs
        icode = 0;
        valE = 0;
        valA = 0;
        valP = 0;

        // Wait for global reset
        #20;

        // Test 1: RMMOVL - 写内存 (rA -> M[valE])
        $display("\n=== Test 1: RMMOVL (Write to Memory) ===");
        @(negedge clk);
        icode = RMMOVL;
        valE = 64'h0000_0000_0000_0010;  // 地址0x10
        valA = 64'hDEAD_BEEF_CAFE_BABE;  // 要写入的数据
        valP = 64'h0000_0000_0000_0100;
        @(posedge clk);
        #1;
        $display("RMMOVL: Write 0x%h to address 0x%h", valA, valE);
        
        // Test 2: MRMOVL - 读内存 (M[valE] -> rB)
        $display("\n=== Test 2: MRMOVL (Read from Memory) ===");
        @(negedge clk);
        icode = MRMOVL;
        valE = 64'h0000_0000_0000_0010;  // 读取地址0x10
        valA = 64'h0;
        @(posedge clk);
        #1;
        $display("MRMOVL: Read from address 0x%h, value = 0x%h", valE, valM);
        if (valM == 64'hDEAD_BEEF_CAFE_BABE) begin
            $display("PASS: Read correct value");
        end else begin
            $display("FAIL: Expected 0xDEADBEEFCAFEBABE, got 0x%h", valM);
        end

        // Test 3: CALL - 压入返回地址
        $display("\n=== Test 3: CALL (Push return address) ===");
        @(negedge clk);
        icode = CALL;
        valE = 64'h0000_0000_0000_0020;  // 栈指针位置
        valA = 64'h0;
        valP = 64'h0000_0000_0000_0200;  // 返回地址
        @(posedge clk);
        #1;
        $display("CALL: Push return address 0x%h to stack at 0x%h", valP, valE);

        // Test 4: RET - 弹出返回地址
        $display("\n=== Test 4: RET (Pop return address) ===");
        @(negedge clk);
        icode = RET;
        valE = 64'h0;
        valA = 64'h0000_0000_0000_0020;  // 从这个地址读取
        valP = 64'h0;
        @(posedge clk);
        #1;
        $display("RET: Pop return address from 0x%h, value = 0x%h", valA, valM);
        if (valM == 64'h0000_0000_0000_0200) begin
            $display("PASS: Read correct return address");
        end else begin
            $display("FAIL: Expected 0x0000000000000200, got 0x%h", valM);
        end

        // Test 5: PUSHL - 压栈
        $display("\n=== Test 5: PUSHL (Push value) ===");
        @(negedge clk);
        icode = PUSHL;
        valE = 64'h0000_0000_0000_0030;  // 栈指针
        valA = 64'h1234_5678_9ABC_DEF0;  // 要压入的值
        valP = 64'h0;
        @(posedge clk);
        #1;
        $display("PUSHL: Push value 0x%h to stack at 0x%h", valA, valE);

        // Test 6: POPL - 出栈
        $display("\n=== Test 6: POPL (Pop value) ===");
        @(negedge clk);
        icode = POPL;
        valE = 64'h0;
        valA = 64'h0000_0000_0000_0030;  // 从这个地址读取
        valP = 64'h0;
        @(posedge clk);
        #1;
        $display("POPL: Pop value from 0x%h, value = 0x%h", valA, valM);
        if (valM == 64'h1234_5678_9ABC_DEF0) begin
            $display("PASS: Read correct value from stack");
        end else begin
            $display("FAIL: Expected 0x123456789ABCDEF0, got 0x%h", valM);
        end

        // Test 7: NOP - 无访存操作
        $display("\n=== Test 7: NOP (No memory access) ===");
        @(negedge clk);
        icode = NOP;
        valE = 64'h0;
        valA = 64'h0;
        valP = 64'h0;
        @(posedge clk);
        #1;
        $display("NOP: No memory access, valM = 0x%h", valM);

        // Test 8: 测试内存错误（地址越界）
        $display("\n=== Test 8: Memory Error (Address out of bounds) ===");
        @(negedge clk);
        icode = MRMOVL;
        valE = 64'h0000_0000_0000_0900;  // 超出范围的地址（>2047）
        valA = 64'h0;
        @(posedge clk);
        #1;
        $display("Memory access to address 0x%h", valE);
        if (dmem_error) begin
            $display("PASS: Memory error detected");
        end else begin
            $display("FAIL: Expected memory error");
        end

        // Test 9: 多次读写测试
        $display("\n=== Test 9: Multiple Read/Write Operations ===");
        // 写入多个值
        @(negedge clk);
        icode = RMMOVL;
        valE = 64'h0000_0000_0000_0040;
        valA = 64'hAAAA_AAAA_AAAA_AAAA;
        @(posedge clk);
        
        @(negedge clk);
        icode = RMMOVL;
        valE = 64'h0000_0000_0000_0048;
        valA = 64'hBBBB_BBBB_BBBB_BBBB;
        @(posedge clk);
        
        @(negedge clk);
        icode = RMMOVL;
        valE = 64'h0000_0000_0000_0050;
        valA = 64'hCCCC_CCCC_CCCC_CCCC;
        @(posedge clk);
        
        // 读取验证
        @(negedge clk);
        icode = MRMOVL;
        valE = 64'h0000_0000_0000_0040;
        @(posedge clk);
        #1;
        $display("Read from 0x40: 0x%h (expected 0xAAAAAAAAAAAAAAAA)", valM);
        
        @(negedge clk);
        icode = MRMOVL;
        valE = 64'h0000_0000_0000_0048;
        @(posedge clk);
        #1;
        $display("Read from 0x48: 0x%h (expected 0xBBBBBBBBBBBBBBBB)", valM);
        
        @(negedge clk);
        icode = MRMOVL;
        valE = 64'h0000_0000_0000_0050;
        @(posedge clk);
        #1;
        $display("Read from 0x50: 0x%h (expected 0xCCCCCCCCCCCCCCCC)", valM);

        // End simulation
        #20;
        $display("\n=== Memory Access Stage Test Complete ===");
        $finish;
    end

    // Monitor
    initial begin
        $monitor("Time=%0t | icode=%h | valE=%h | valA=%h | valM=%h | error=%b", 
                 $time, icode, valE, valA, valM, dmem_error);
    end

endmodule
