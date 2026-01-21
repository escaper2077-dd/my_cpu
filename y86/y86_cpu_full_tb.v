`timescale 1ps/1ps

module y86_cpu_full_tb;

    // Clock and Reset
    reg clk;
    reg rst_n;
    
    // Status output
    wire [1:0] stat;
    
    // Debug outputs
    wire [63:0] PC;
    wire [3:0] icode;
    
    // Instantiate the Y86 CPU
    y86_cpu uut (
        .clk_i(clk),
        .rst_n_i(rst_n),
        .stat_o(stat),
        .PC_o(PC),
        .icode_o(icode)
    );
    
    // Clock generation (10ns period = 100MHz)
    always #5 clk = ~clk;
    
    // Status code definitions
    localparam STAT_AOK = 2'b00;  // 正常运行
    localparam STAT_HLT = 2'b01;  // 遇到 halt 指令
    localparam STAT_ADR = 2'b10;  // 地址错误
    localparam STAT_INS = 2'b11;  // 非法指令
    
    integer cycle_count;
    
    initial begin
        // Load program into instruction memory
        // Program: irmovq $10, %rax; irmovq $20, %rbx; addq %rbx, %rax; irmovq $100, %rsp; halt
        
        // PC = 0x00: irmovq $10, %rax
        uut.fetch_stage.instr_mem[0]  = 8'h30;
        uut.fetch_stage.instr_mem[1]  = 8'hF0;
        uut.fetch_stage.instr_mem[2]  = 8'h0A;
        uut.fetch_stage.instr_mem[3]  = 8'h00;
        uut.fetch_stage.instr_mem[4]  = 8'h00;
        uut.fetch_stage.instr_mem[5]  = 8'h00;
        uut.fetch_stage.instr_mem[6]  = 8'h00;
        uut.fetch_stage.instr_mem[7]  = 8'h00;
        uut.fetch_stage.instr_mem[8]  = 8'h00;
        uut.fetch_stage.instr_mem[9]  = 8'h00;
        
        // PC = 0x0A: irmovq $20, %rbx
        uut.fetch_stage.instr_mem[10] = 8'h30;
        uut.fetch_stage.instr_mem[11] = 8'hF3;
        uut.fetch_stage.instr_mem[12] = 8'h14;
        uut.fetch_stage.instr_mem[13] = 8'h00;
        uut.fetch_stage.instr_mem[14] = 8'h00;
        uut.fetch_stage.instr_mem[15] = 8'h00;
        uut.fetch_stage.instr_mem[16] = 8'h00;
        uut.fetch_stage.instr_mem[17] = 8'h00;
        uut.fetch_stage.instr_mem[18] = 8'h00;
        uut.fetch_stage.instr_mem[19] = 8'h00;
        
        // PC = 0x14: addq %rbx, %rax
        uut.fetch_stage.instr_mem[20] = 8'h60;
        uut.fetch_stage.instr_mem[21] = 8'h30;
        
        // PC = 0x16: irmovq $100, %rsp
        uut.fetch_stage.instr_mem[22] = 8'h30;
        uut.fetch_stage.instr_mem[23] = 8'hF4;
        uut.fetch_stage.instr_mem[24] = 8'h64;
        uut.fetch_stage.instr_mem[25] = 8'h00;
        uut.fetch_stage.instr_mem[26] = 8'h00;
        uut.fetch_stage.instr_mem[27] = 8'h00;
        uut.fetch_stage.instr_mem[28] = 8'h00;
        uut.fetch_stage.instr_mem[29] = 8'h00;
        uut.fetch_stage.instr_mem[30] = 8'h00;
        uut.fetch_stage.instr_mem[31] = 8'h00;
        
        // PC = 0x20: halt
        uut.fetch_stage.instr_mem[32] = 8'h10;
        
        // Initialize signals
        clk = 0;
        rst_n = 0;
        cycle_count = 0;
        
        $display("\n========================================");
        $display("=== Y86-64 Single-Cycle CPU Test ===");
        $display("========================================");
        $display("\nProgram loaded:");
        $display("  0x00: irmovq $10, %%rax");
        $display("  0x0A: irmovq $20, %%rbx");
        $display("  0x14: addq %%rbx, %%rax");
        $display("  0x16: irmovq $100, %%rsp");
        $display("  0x20: halt\n");
        
        // Reset the CPU
        #15 rst_n = 1;
        $display("CPU Reset Released at time %0t\n", $time);
        
        // Monitor CPU state
        $display("%-6s %-12s %-10s %-8s", "Cycle", "PC", "Icode", "Status");
        $display("------------------------------------------");
        
        // Run until HALT or error
        repeat(20) begin
            @(posedge clk);
            cycle_count = cycle_count + 1;
            
            // Check for HALT or error conditions BEFORE displaying
            // 注意：HALT 指令在执行周期就应该停止
            if (stat == STAT_HLT && cycle_count > 1) begin
                $display("%-6d 0x%-10h HALT       %b", cycle_count, PC, stat);
                $display("\n=== CPU HALTED at cycle %0d ===", cycle_count);
                $display("Final PC: 0x%h", PC);
                break;
            end else if (stat == STAT_ADR) begin
                $display("%-6d 0x%-10h ???        %b", cycle_count, PC, stat);
                $display("\n=== ADDRESS ERROR at cycle %0d ===", cycle_count);
                $display("PC: 0x%h", PC);
                break;
            end else if (stat == STAT_INS) begin
                $display("%-6d 0x%-10h ???        %b", cycle_count, PC, stat);
                $display("\n=== INVALID INSTRUCTION at cycle %0d ===", cycle_count);
                $display("PC: 0x%h, Icode: 0x%h", PC, icode);
                break;
            end
            
            // Display CPU state
            case (icode)
                4'h0: $display("%-6d 0x%-10h NOP        %b", cycle_count, PC, stat);
                4'h1: $display("%-6d 0x%-10h HALT       %b", cycle_count, PC, stat);
                4'h2: $display("%-6d 0x%-10h RRMOVL     %b", cycle_count, PC, stat);
                4'h3: $display("%-6d 0x%-10h IRMOVL     %b", cycle_count, PC, stat);
                4'h4: $display("%-6d 0x%-10h RMMOVL     %b", cycle_count, PC, stat);
                4'h5: $display("%-6d 0x%-10h MRMOVL     %b", cycle_count, PC, stat);
                4'h6: $display("%-6d 0x%-10h ALU        %b", cycle_count, PC, stat);
                4'h7: $display("%-6d 0x%-10h JXX        %b", cycle_count, PC, stat);
                4'h8: $display("%-6d 0x%-10h CALL       %b", cycle_count, PC, stat);
                4'h9: $display("%-6d 0x%-10h RET        %b", cycle_count, PC, stat);
                4'hA: $display("%-6d 0x%-10h PUSHL      %b", cycle_count, PC, stat);
                4'hB: $display("%-6d 0x%-10h POPL       %b", cycle_count, PC, stat);
                default: $display("%-6d 0x%-10h ???(0x%h)  %b", cycle_count, PC, icode, stat);
            endcase
        end
        
        // Wait one more cycle to see final register values
        @(posedge clk);
        
        // Display register file contents
        $display("\n=== Final Register File Contents ===");
        $display("%-6s  %-18s  %-10s", "Reg", "Value (hex)", "Value (dec)");
        $display("--------------------------------------------");
        $display("%%rax:  0x%016h  %0d", uut.decode_stage.regfile[0], uut.decode_stage.regfile[0]);
        $display("%%rcx:  0x%016h  %0d", uut.decode_stage.regfile[1], uut.decode_stage.regfile[1]);
        $display("%%rdx:  0x%016h  %0d", uut.decode_stage.regfile[2], uut.decode_stage.regfile[2]);
        $display("%%rbx:  0x%016h  %0d", uut.decode_stage.regfile[3], uut.decode_stage.regfile[3]);
        $display("%%rsp:  0x%016h  %0d", uut.decode_stage.regfile[4], uut.decode_stage.regfile[4]);
        $display("%%rbp:  0x%016h  %0d", uut.decode_stage.regfile[5], uut.decode_stage.regfile[5]);
        
        // Check results
        $display("\n=== Test Results Verification ===");
        if (uut.decode_stage.regfile[0] == 64'd30) begin
            $display("✓ PASS: %%rax = 30 (10 + 20)");
        end else begin
            $display("✗ FAIL: %%rax = %0d, expected 30", uut.decode_stage.regfile[0]);
        end
        
        if (uut.decode_stage.regfile[3] == 64'd20) begin
            $display("✓ PASS: %%rbx = 20");
        end else begin
            $display("✗ FAIL: %%rbx = %0d, expected 20", uut.decode_stage.regfile[3]);
        end
        
        if (uut.decode_stage.regfile[4] == 64'd100) begin
            $display("✓ PASS: %%rsp = 100");
        end else begin
            $display("✗ FAIL: %%rsp = %0d, expected 100", uut.decode_stage.regfile[4]);
        end
        
        $display("\n========================================");
        $display("=== Test Complete ===");
        $display("Total cycles executed: %0d", cycle_count);
        $display("========================================\n");
        
        #100;
        $finish;
    end
    
    // Watchdog timer
    initial begin
        #5000;
        $display("\n=== ERROR: Simulation timeout ===");
        $finish;
    end

endmodule
