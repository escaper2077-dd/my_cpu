`timescale 1ps/1ps

module fetch_func_tb();

    // 信号声明
    reg [63:0] PC_i;
    wire [3:0] icode_o;
    wire [3:0] ifun_o;
    wire [3:0] rA_o;
    wire [3:0] rB_o;
    wire [63:0] valC_o;
    wire [63:0] valP_o;
    wire instr_valid_o;
    wire imem_error_o;

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

    // 测试激励
    initial begin
        $display("========== Fetch Func Validation Testbench ==========\n");
        
        // ========== NOP指令测试 (func=0) ==========
        $display("[Test NOP] NOP with func=0 (valid)");
        fetch_inst.instr_mem[0] = 8'h00;  // icode=0, func=0
        PC_i = 64'd0;
        #10;
        $display("icode=%h, func=%h, valid=%b (expected: 1)\n", icode_o, ifun_o, instr_valid_o);
        
        // ========== ALU指令测试 ==========
        $display("[Test ALU-ADDL] ADDL (icode=6, func=0) - VALID");
        fetch_inst.instr_mem[1] = 8'h60;  // icode=6, func=0 (ADDL)
        fetch_inst.instr_mem[2] = 8'h12;  // rA=1, rB=2
        PC_i = 64'd1;
        #10;
        $display("icode=%h, func=%h, valid=%b (expected: 1)\n", icode_o, ifun_o, instr_valid_o);
        
        $display("[Test ALU-SUBL] SUBL (icode=6, func=1) - VALID");
        fetch_inst.instr_mem[3] = 8'h61;  // icode=6, func=1 (SUBL)
        fetch_inst.instr_mem[4] = 8'h34;  // rA=3, rB=4
        PC_i = 64'd3;
        #10;
        $display("icode=%h, func=%h, valid=%b (expected: 1)\n", icode_o, ifun_o, instr_valid_o);
        
        $display("[Test ALU-ANDL] ANDL (icode=6, func=2) - VALID");
        fetch_inst.instr_mem[5] = 8'h62;  // icode=6, func=2 (ANDL)
        fetch_inst.instr_mem[6] = 8'h56;  // rA=5, rB=6
        PC_i = 64'd5;
        #10;
        $display("icode=%h, func=%h, valid=%b (expected: 1)\n", icode_o, ifun_o, instr_valid_o);
        
        $display("[Test ALU-XORL] XORL (icode=6, func=3) - VALID");
        fetch_inst.instr_mem[7] = 8'h63;  // icode=6, func=3 (XORL)
        fetch_inst.instr_mem[8] = 8'h78;  // rA=7, rB=8
        PC_i = 64'd7;
        #10;
        $display("icode=%h, func=%h, valid=%b (expected: 1)\n", icode_o, ifun_o, instr_valid_o);
        
        $display("[Test ALU-Invalid] INVALID ALU func (icode=6, func=4) - INVALID");
        fetch_inst.instr_mem[9] = 8'h64;  // icode=6, func=4 (INVALID)
        fetch_inst.instr_mem[10] = 8'h9A; // dummy
        PC_i = 64'd9;
        #10;
        $display("icode=%h, func=%h, valid=%b (expected: 0)\n", icode_o, ifun_o, instr_valid_o);
        
        $display("[Test ALU-Invalid2] INVALID ALU func (icode=6, func=F) - INVALID");
        fetch_inst.instr_mem[11] = 8'h6F;  // icode=6, func=F (INVALID)
        fetch_inst.instr_mem[12] = 8'h9B; // dummy
        PC_i = 64'd11;
        #10;
        $display("icode=%h, func=%h, valid=%b (expected: 0)\n", icode_o, ifun_o, instr_valid_o);
        
        // ========== JXX指令测试 ==========
        $display("[Test JXX-JMP] JMP (icode=7, func=0) - VALID");
        fetch_inst.instr_mem[13] = 8'h70;  // icode=7, func=0 (JMP)
        fetch_inst.instr_mem[14] = 8'h00; // valC start
        PC_i = 64'd13;
        #10;
        $display("icode=%h, func=%h, valid=%b (expected: 1)\n", icode_o, ifun_o, instr_valid_o);
        
        $display("[Test JXX-JLE] JLE (icode=7, func=1) - VALID");
        fetch_inst.instr_mem[15] = 8'h71;  // icode=7, func=1 (JLE)
        fetch_inst.instr_mem[16] = 8'h00; // valC start
        PC_i = 64'd15;
        #10;
        $display("icode=%h, func=%h, valid=%b (expected: 1)\n", icode_o, ifun_o, instr_valid_o);
        
        $display("[Test JXX-JG] JG (icode=7, func=6) - VALID");
        fetch_inst.instr_mem[17] = 8'h76;  // icode=7, func=6 (JG)
        fetch_inst.instr_mem[18] = 8'h00; // valC start
        PC_i = 64'd17;
        #10;
        $display("icode=%h, func=%h, valid=%b (expected: 1)\n", icode_o, ifun_o, instr_valid_o);
        
        $display("[Test JXX-Invalid] INVALID JXX func (icode=7, func=7) - INVALID");
        fetch_inst.instr_mem[19] = 8'h77;  // icode=7, func=7 (INVALID)
        fetch_inst.instr_mem[20] = 8'h00; // valC start
        PC_i = 64'd19;
        #10;
        $display("icode=%h, func=%h, valid=%b (expected: 0)\n", icode_o, ifun_o, instr_valid_o);
        
        $display("[Test JXX-Invalid2] INVALID JXX func (icode=7, func=F) - INVALID");
        fetch_inst.instr_mem[21] = 8'h7F;  // icode=7, func=F (INVALID)
        fetch_inst.instr_mem[22] = 8'h00; // valC start
        PC_i = 64'd21;
        #10;
        $display("icode=%h, func=%h, valid=%b (expected: 0)\n", icode_o, ifun_o, instr_valid_o);
        
        // ========== 其他指令测试 ==========
        $display("[Test RRMOVL] RRMOVL with func=0 (valid)");
        fetch_inst.instr_mem[23] = 8'h20;  // icode=2, func=0 (RRMOVL)
        fetch_inst.instr_mem[24] = 8'h12; // rA=1, rB=2
        PC_i = 64'd23;
        #10;
        $display("icode=%h, func=%h, valid=%b (expected: 1)\n", icode_o, ifun_o, instr_valid_o);
        
        $display("[Test CMOVLE] CMOVLE with func=1 (valid)");
        fetch_inst.instr_mem[25] = 8'h21;  // icode=2, func=1 (CMOVLE)
        fetch_inst.instr_mem[26] = 8'h34; // rA=3, rB=4
        PC_i = 64'd25;
        #10;
        $display("icode=%h, func=%h, valid=%b (expected: 1)\n", icode_o, ifun_o, instr_valid_o);
        
        $display("[Test CMOVG] CMOVG with func=6 (valid)");
        fetch_inst.instr_mem[27] = 8'h26;  // icode=2, func=6 (CMOVG)
        fetch_inst.instr_mem[28] = 8'h56; // rA=5, rB=6
        PC_i = 64'd27;
        #10;
        $display("icode=%h, func=%h, valid=%b (expected: 1)\n", icode_o, ifun_o, instr_valid_o);
        
        $display("[Test RRMOVL-Invalid] RRMOVL with func=7 (invalid)");
        fetch_inst.instr_mem[29] = 8'h27;  // icode=2, func=7 (INVALID)
        fetch_inst.instr_mem[30] = 8'h12; // rA=1, rB=2
        PC_i = 64'd29;
        #10;
        $display("icode=%h, func=%h, valid=%b (expected: 0)\n", icode_o, ifun_o, instr_valid_o);
        
        $display("[Test RRMOVL-Invalid2] RRMOVL with func=F (invalid)");
        fetch_inst.instr_mem[31] = 8'h2F;  // icode=2, func=F (INVALID)
        fetch_inst.instr_mem[32] = 8'h12; // rA=1, rB=2
        PC_i = 64'd31;
        #10;
        $display("icode=%h, func=%h, valid=%b (expected: 0)\n", icode_o, ifun_o, instr_valid_o);
        
        $display("========== Test Complete ==========");
        $finish;
    end

endmodule
