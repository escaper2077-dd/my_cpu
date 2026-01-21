`timescale 1ps/1ps

// Y86 CPU 测试程序加载器
// 这个模块用于初始化指令内存，加载一个简单的测试程序
module y86_program_loader;

    // 指令内存 - 可以从外部访问
    reg [7:0] instr_mem[0:1023];
    
    initial begin
        integer i;
        
        // 首先清空所有内存
        for (i = 0; i < 1024; i = i + 1) begin
            instr_mem[i] = 8'h00;
        end
        
        // 加载测试程序
        // 这是一个简单的程序：执行一些算术运算然后 HALT
        
        // PC = 0x00: irmovq $10, %rax    (30 F0 0A 00 00 00 00 00 00 00)
        instr_mem[0]  = 8'h30;  // icode=3 (IRMOVL), ifun=0
        instr_mem[1]  = 8'hF0;  // rA=F (unused), rB=0 (%rax)
        instr_mem[2]  = 8'h0A;  // valC = 10 (little-endian)
        instr_mem[3]  = 8'h00;
        instr_mem[4]  = 8'h00;
        instr_mem[5]  = 8'h00;
        instr_mem[6]  = 8'h00;
        instr_mem[7]  = 8'h00;
        instr_mem[8]  = 8'h00;
        instr_mem[9]  = 8'h00;
        
        // PC = 0x0A: irmovq $20, %rbx    (30 F3 14 00 00 00 00 00 00 00)
        instr_mem[10] = 8'h30;  // icode=3 (IRMOVL), ifun=0
        instr_mem[11] = 8'hF3;  // rA=F (unused), rB=3 (%rbx)
        instr_mem[12] = 8'h14;  // valC = 20
        instr_mem[13] = 8'h00;
        instr_mem[14] = 8'h00;
        instr_mem[15] = 8'h00;
        instr_mem[16] = 8'h00;
        instr_mem[17] = 8'h00;
        instr_mem[18] = 8'h00;
        instr_mem[19] = 8'h00;
        
        // PC = 0x14: addq %rbx, %rax     (60 30)
        instr_mem[20] = 8'h60;  // icode=6 (ALU), ifun=0 (ADDL)
        instr_mem[21] = 8'h30;  // rA=3 (%rbx), rB=0 (%rax)
        
        // PC = 0x16: irmovq $100, %rsp   (30 F4 64 00 00 00 00 00 00 00)
        instr_mem[22] = 8'h30;  // icode=3 (IRMOVL), ifun=0
        instr_mem[23] = 8'hF4;  // rA=F (unused), rB=4 (%rsp)
        instr_mem[24] = 8'h64;  // valC = 100
        instr_mem[25] = 8'h00;
        instr_mem[26] = 8'h00;
        instr_mem[27] = 8'h00;
        instr_mem[28] = 8'h00;
        instr_mem[29] = 8'h00;
        instr_mem[30] = 8'h00;
        instr_mem[31] = 8'h00;
        
        // PC = 0x20: halt                (10)
        instr_mem[32] = 8'h10;  // icode=1 (HALT), ifun=0
        
        $display("Y86 Program loaded successfully");
        $display("Program:");
        $display("  0x00: irmovq $10, %%rax");
        $display("  0x0A: irmovq $20, %%rbx");
        $display("  0x14: addq %%rbx, %%rax");
        $display("  0x16: irmovq $100, %%rsp");
        $display("  0x20: halt");
    end

endmodule
