`timescale 1ps/1ps

module pipelined_y86_cpu_tb;

    // 时钟和复位信号
    reg clk;
    reg rst_n;
    
    // CPU状态输出
    wire [1:0] stat;
    wire [63:0] PC;
    wire [3:0] F_icode, D_icode, E_icode, M_icode, W_icode;
    
    // 状态码定义
    localparam STAT_AOK = 2'b00;
    localparam STAT_HLT = 2'b01;
    localparam STAT_ADR = 2'b10;
    localparam STAT_INS = 2'b11;
    
    // 实例化流水线CPU
    pipelined_y86_cpu cpu(
        .clk_i(clk),
        .rst_n_i(rst_n),
        .stat_o(stat),
        .PC_o(PC),
        .F_icode_o(F_icode),
        .D_icode_o(D_icode),
        .E_icode_o(E_icode),
        .M_icode_o(M_icode),
        .W_icode_o(W_icode)
    );
    
    // 初始化指令内存
    initial begin
        // 简单测试程序：3 + 5 = 8
        // irmovq $3, %rax
        cpu.fetch_stage.instr_mem[0] = 8'h30;
        cpu.fetch_stage.instr_mem[1] = 8'hF0;
        cpu.fetch_stage.instr_mem[2] = 8'h03;
        cpu.fetch_stage.instr_mem[3] = 8'h00;
        cpu.fetch_stage.instr_mem[4] = 8'h00;
        cpu.fetch_stage.instr_mem[5] = 8'h00;
        cpu.fetch_stage.instr_mem[6] = 8'h00;
        cpu.fetch_stage.instr_mem[7] = 8'h00;
        cpu.fetch_stage.instr_mem[8] = 8'h00;
        cpu.fetch_stage.instr_mem[9] = 8'h00;
        
        // irmovq $5, %rbx
        cpu.fetch_stage.instr_mem[10] = 8'h30;
        cpu.fetch_stage.instr_mem[11] = 8'hF3;
        cpu.fetch_stage.instr_mem[12] = 8'h05;
        cpu.fetch_stage.instr_mem[13] = 8'h00;
        cpu.fetch_stage.instr_mem[14] = 8'h00;
        cpu.fetch_stage.instr_mem[15] = 8'h00;
        cpu.fetch_stage.instr_mem[16] = 8'h00;
        cpu.fetch_stage.instr_mem[17] = 8'h00;
        cpu.fetch_stage.instr_mem[18] = 8'h00;
        cpu.fetch_stage.instr_mem[19] = 8'h00;
        
        // addq %rbx, %rax
        cpu.fetch_stage.instr_mem[20] = 8'h60;
        cpu.fetch_stage.instr_mem[21] = 8'h30;
        
        // halt
        cpu.fetch_stage.instr_mem[22] = 8'h10;
    end
    
    // 时钟生成 - 10ns周期
    initial begin
        clk = 0;
        forever #5000 clk = ~clk;
    end
    
    // 测试序列
    initial begin
        // 初始化
        rst_n = 0;
        
        // 复位
        #10000;
        rst_n = 1;
        
        // 运行直到HALT或错误
        #10000;
        while (stat == STAT_AOK) begin
            #10000;
            if ($time > 10000000) begin  // 超时保护（10ms）
                $display("ERROR: Simulation timeout!");
                $finish;
            end
        end
        
        // 检查最终状态
        #10000;
        $display("===========================================");
        $display("CPU Final State:");
        $display("===========================================");
        case (stat)
            STAT_AOK: $display("Status: AOK (Running)");
            STAT_HLT: $display("Status: HLT (Halted normally)");
            STAT_ADR: $display("Status: ADR (Address error)");
            STAT_INS: $display("Status: INS (Invalid instruction)");
        endcase
        $display("Final PC: 0x%h", PC);
        $display("===========================================");
        
        // 显示寄存器内容
        $display("\nRegister File Contents:");
        $display("===========================================");
        $display("%%rax (R0):  0x%h", cpu.decode_stage.regfile[0]);
        $display("%%rcx (R1):  0x%h", cpu.decode_stage.regfile[1]);
        $display("%%rdx (R2):  0x%h", cpu.decode_stage.regfile[2]);
        $display("%%rbx (R3):  0x%h", cpu.decode_stage.regfile[3]);
        $display("%%rsp (R4):  0x%h", cpu.decode_stage.regfile[4]);
        $display("%%rbp (R5):  0x%h", cpu.decode_stage.regfile[5]);
        $display("%%rsi (R6):  0x%h", cpu.decode_stage.regfile[6]);
        $display("%%rdi (R7):  0x%h", cpu.decode_stage.regfile[7]);
        $display("%%r8  (R8):  0x%h", cpu.decode_stage.regfile[8]);
        $display("%%r9  (R9):  0x%h", cpu.decode_stage.regfile[9]);
        $display("%%r10 (R10): 0x%h", cpu.decode_stage.regfile[10]);
        $display("%%r11 (R11): 0x%h", cpu.decode_stage.regfile[11]);
        $display("%%r12 (R12): 0x%h", cpu.decode_stage.regfile[12]);
        $display("%%r13 (R13): 0x%h", cpu.decode_stage.regfile[13]);
        $display("%%r14 (R14): 0x%h", cpu.decode_stage.regfile[14]);
        $display("===========================================");
        
        if (stat == STAT_HLT) begin
            $display("\nTest PASSED: CPU halted normally");
        end else begin
            $display("\nTest FAILED: CPU did not halt normally");
        end
        
        $finish;
    end
    
    // 监视流水线状态（可选）
    initial begin
        $display("===========================================");
        $display("Pipelined Y86 CPU Simulation Started");
        $display("===========================================");
        $monitor("Time=%0t | PC=0x%h | F:%h D:%h E:%h M:%h W:%h | Stat=%b", 
                 $time, PC, F_icode, D_icode, E_icode, M_icode, W_icode, stat);
    end
    
    // 生成波形文件
    initial begin
        $dumpfile("pipelined_y86_cpu.vcd");
        $dumpvars(0, pipelined_y86_cpu_tb);
    end

endmodule
