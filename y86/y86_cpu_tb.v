`timescale 1ps/1ps

module y86_cpu_tb;

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
    
    // Instruction code definitions
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
    
    integer cycle_count;
    
    initial begin
        // Initialize signals
        clk = 0;
        rst_n = 0;
        cycle_count = 0;
        
        $display("=== Y86-64 Single-Cycle CPU Test ===");
        $display("Time: %0t", $time);
        
        // Reset the CPU
        #15 rst_n = 1;
        $display("CPU Reset Released at time %0t", $time);
        
        // Monitor CPU state
        $display("\n%-10s %-10s %-10s %-10s", "Cycle", "PC", "Icode", "Status");
        $display("--------------------------------------------");
        
        // Run for a certain number of cycles or until HALT
        repeat(50) begin
            @(posedge clk);
            cycle_count = cycle_count + 1;
            
            // Display CPU state
            $display("%-10d 0x%-8h %-10h %b", cycle_count, PC, icode, stat);
            
            // Check for HALT or error conditions
            if (stat == STAT_HLT) begin
                $display("\n=== CPU HALTED at cycle %0d ===", cycle_count);
                $display("Final PC: 0x%h", PC);
                break;
            end else if (stat == STAT_ADR) begin
                $display("\n=== ADDRESS ERROR at cycle %0d ===", cycle_count);
                $display("PC: 0x%h", PC);
                break;
            end else if (stat == STAT_INS) begin
                $display("\n=== INVALID INSTRUCTION at cycle %0d ===", cycle_count);
                $display("PC: 0x%h, Icode: 0x%h", PC, icode);
                break;
            end
        end
        
        // Display register file contents
        $display("\n=== Final Register File Contents ===");
        $display("%-6s  %-18s", "Reg", "Value (hex)");
        $display("------------------------------");
        $display("%%rax:  0x%h", uut.decode_stage.regfile[0]);
        $display("%%rcx:  0x%h", uut.decode_stage.regfile[1]);
        $display("%%rdx:  0x%h", uut.decode_stage.regfile[2]);
        $display("%%rbx:  0x%h", uut.decode_stage.regfile[3]);
        $display("%%rsp:  0x%h", uut.decode_stage.regfile[4]);
        $display("%%rbp:  0x%h", uut.decode_stage.regfile[5]);
        $display("%%rsi:  0x%h", uut.decode_stage.regfile[6]);
        $display("%%rdi:  0x%h", uut.decode_stage.regfile[7]);
        $display("%%r8:   0x%h", uut.decode_stage.regfile[8]);
        $display("%%r9:   0x%h", uut.decode_stage.regfile[9]);
        $display("%%r10:  0x%h", uut.decode_stage.regfile[10]);
        $display("%%r11:  0x%h", uut.decode_stage.regfile[11]);
        $display("%%r12:  0x%h", uut.decode_stage.regfile[12]);
        $display("%%r13:  0x%h", uut.decode_stage.regfile[13]);
        $display("%%r14:  0x%h", uut.decode_stage.regfile[14]);
        
        // Display some data memory locations
        $display("\n=== Sample Data Memory Contents ===");
        $display("Address  Value (hex)");
        $display("------------------------------");
        $display("0x00:    0x%h", uut.memory_stage.data_memory[0]);
        $display("0x08:    0x%h", uut.memory_stage.data_memory[1]);
        $display("0x10:    0x%h", uut.memory_stage.data_memory[2]);
        $display("0x18:    0x%h", uut.memory_stage.data_memory[3]);
        
        $display("\n=== Test Complete ===");
        $display("Total cycles executed: %0d", cycle_count);
        #100;
        $finish;
    end
    
    // Watchdog timer
    initial begin
        #10000;
        $display("\n=== ERROR: Simulation timeout ===");
        $finish;
    end

endmodule
