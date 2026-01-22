`timescale 1ps/1ps
module temp_debug();
    reg clk, rst_n;
    y86_cpu uut(.clk_i(clk), .rst_n_i(rst_n));
    wire [63:0] PC = uut.pc_update_stage.PC_o;
    wire [3:0] icode = uut.fetch_stage.icode_o;
    wire [63:0] valC = uut.fetch_stage.valC_o;
    wire [63:0] valA = uut.decode_stage.valA_o;
    wire [63:0] valB = uut.decode_stage.valB_o;
    wire [63:0] valE = uut.execute_stage.valE_o;
    initial begin clk=0; rst_n=0; end
    always #10 clk = ~clk;
    initial #50000 $stop;
    initial begin
        forever @(posedge clk) if(rst_n && (PC>=87 && PC<=100))
            $display("PC=%0d(0x%h): icode=%h valC=%d valA=%d valB=%d valE=%d", 
                     PC, PC, icode, valC, valA, valB, valE);
    end
    initial begin
        uut.fetch_stage.instr_mem[0] = 8'h00;
        // irmovq $200, %rsp
        uut.fetch_stage.instr_mem[1] = 8'h30; uut.fetch_stage.instr_mem[2] = 8'hF4;
        uut.fetch_stage.instr_mem[3] = 8'hC8; uut.fetch_stage.instr_mem[4] = 0;
        uut.fetch_stage.instr_mem[5] = 0; uut.fetch_stage.instr_mem[6] = 0;
        uut.fetch_stage.instr_mem[7] = 0; uut.fetch_stage.instr_mem[8] = 0;
        uut.fetch_stage.instr_mem[9] = 0; uut.fetch_stage.instr_mem[10] = 0;
        // irmovq $10, %rax  [11-20]
        uut.fetch_stage.instr_mem[11] = 8'h30; uut.fetch_stage.instr_mem[12] = 8'hF0;
        uut.fetch_stage.instr_mem[13] = 8'h0A; uut.fetch_stage.instr_mem[14] = 0;
        uut.fetch_stage.instr_mem[15] = 0; uut.fetch_stage.instr_mem[16] = 0;
        uut.fetch_stage.instr_mem[17] = 0; uut.fetch_stage.instr_mem[18] = 0;
        uut.fetch_stage.instr_mem[19] = 0; uut.fetch_stage.instr_mem[20] = 0;
        // irmovq $10, %rbx  [21-30]
        uut.fetch_stage.instr_mem[21] = 8'h30; uut.fetch_stage.instr_mem[22] = 8'hF3;
        uut.fetch_stage.instr_mem[23] = 8'h0A; uut.fetch_stage.instr_mem[24] = 0;
        uut.fetch_stage.instr_mem[25] = 0; uut.fetch_stage.instr_mem[26] = 0;
        uut.fetch_stage.instr_mem[27] = 0; uut.fetch_stage.instr_mem[28] = 0;
        uut.fetch_stage.instr_mem[29] = 0; uut.fetch_stage.instr_mem[30] = 0;
        // subq %rbx, %rax [31-32] -> rax = 10-10 = 0
        uut.fetch_stage.instr_mem[31] = 8'h61; uut.fetch_stage.instr_mem[32] = 8'h30;
        // irmovq $5, %rax [33-42]
        uut.fetch_stage.instr_mem[33] = 8'h30; uut.fetch_stage.instr_mem[34] = 8'hF0;
        uut.fetch_stage.instr_mem[35] = 8'h05; uut.fetch_stage.instr_mem[36] = 0;
        uut.fetch_stage.instr_mem[37] = 0; uut.fetch_stage.instr_mem[38] = 0;
        uut.fetch_stage.instr_mem[39] = 0; uut.fetch_stage.instr_mem[40] = 0;
        uut.fetch_stage.instr_mem[41] = 0; uut.fetch_stage.instr_mem[42] = 0;
        // subq %rbx, %rax [43-44] -> rax = 5-10 = -5
        uut.fetch_stage.instr_mem[43] = 8'h61; uut.fetch_stage.instr_mem[44] = 8'h30;
        // halt [45]
        uut.fetch_stage.instr_mem[45] = 8'h10;
        #5 rst_n = 1;
        #1000;
        $display("rax=%d rbx=%d", uut.decode_stage.regfile[0], uut.decode_stage.regfile[3]);
        $finish;
    end
endmodule
