`timescale 1ps/1ps

module fetch_tb();

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
    fetchC fetch_inst (
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

    // 测试激励
    initial begin
        // 初始化指令内存
        // 测试用例1: NOP指令 (icode=0x0, ifun=0x0) - 1字节
        fetch_inst.instr_mem[0] = 8'h00;
        
        // 测试用例2: HALT指令 (icode=0x1, ifun=0x0) - 1字节
        fetch_inst.instr_mem[1] = 8'h10;
        
        // 测试用例3: RRMOVQ指令 (icode=0x2, ifun=0x0, rA=3, rB=4) - 2字节
        fetch_inst.instr_mem[2] = 8'h20;      // icode=2, ifun=0
        fetch_inst.instr_mem[3] = 8'h34;      // rA=3, rB=4
        
        // 测试用例4: IRMOVQ指令 (icode=0x3, ifun=0x0, rA=0xF, rB=5, valC=0x0123456789ABCDEF) - 10字节
        // valC采用小端法存储：低位字节在低地址
        fetch_inst.instr_mem[4] = 8'h30;      // icode=3, ifun=0
        fetch_inst.instr_mem[5] = 8'hF5;      // rA=F, rB=5
        fetch_inst.instr_mem[6] = 8'hEF;      // valC byte 0
        fetch_inst.instr_mem[7] = 8'hCD;      // valC byte 1
        fetch_inst.instr_mem[8] = 8'hAB;      // valC byte 2
        fetch_inst.instr_mem[9] = 8'h89;      // valC byte 3
        fetch_inst.instr_mem[10] = 8'h67;     // valC byte 4
        fetch_inst.instr_mem[11] = 8'h45;     // valC byte 5
        fetch_inst.instr_mem[12] = 8'h23;     // valC byte 6
        fetch_inst.instr_mem[13] = 8'h01;     // valC byte 7
        
        // 测试用例5: RMMOVQ指令 (icode=0x4, ifun=0x0, rA=1, rB=2, valC=0x0000000000000100) - 10字节
        fetch_inst.instr_mem[14] = 8'h40;     // icode=4, ifun=0
        fetch_inst.instr_mem[15] = 8'h12;     // rA=1, rB=2
        fetch_inst.instr_mem[16] = 8'h00;     // valC byte 0
        fetch_inst.instr_mem[17] = 8'h01;     // valC byte 1
        fetch_inst.instr_mem[18] = 8'h00;     // valC byte 2
        fetch_inst.instr_mem[19] = 8'h00;     // valC byte 3
        fetch_inst.instr_mem[20] = 8'h00;     // valC byte 4
        fetch_inst.instr_mem[21] = 8'h00;     // valC byte 5
        fetch_inst.instr_mem[22] = 8'h00;     // valC byte 6
        fetch_inst.instr_mem[23] = 8'h00;     // valC byte 7
        
        // 测试用例6: OPQ指令 (icode=0x6, ifun=0x1, rA=5, rB=6) - 2字节
        fetch_inst.instr_mem[24] = 8'h61;     // icode=6, ifun=1
        fetch_inst.instr_mem[25] = 8'h56;     // rA=5, rB=6
        
        // 测试用例7: 无效指令 (icode=0xE) - 错误检查
        fetch_inst.instr_mem[26] = 8'hE0;     // icode=E, ifun=0
        
        // 打印头信息
        $display("Y86-64 Fetch Stage Testbench");
        $display("================================================================================");
        $display("PC      | icode | ifun | rA   | rB   | valC             | valP     | valid | error");
        $display("--------|-------|------|------|------|------------------|----------|-------|------");

        // 测试1: NOP指令
        PC_i = 64'd0;
        #10;
        $display("%08h | %01h    | %01h   | %01h   | %01h   | %016h | %08h | %d     | %d",
                 PC_i, icode_o, ifun_o, rA_o, rB_o, valC_o, valP_o, instr_valid_o, imem_error_o);

        // 测试2: HALT指令
        PC_i = 64'd1;
        #10;
        $display("%08h | %01h    | %01h   | %01h   | %01h   | %016h | %08h | %d     | %d",
                 PC_i, icode_o, ifun_o, rA_o, rB_o, valC_o, valP_o, instr_valid_o, imem_error_o);

        // 测试3: RRMOVQ指令 (2字节)
        PC_i = 64'd2;
        #10;
        $display("%08h | %01h    | %01h   | %01h   | %01h   | %016h | %08h | %d     | %d",
                 PC_i, icode_o, ifun_o, rA_o, rB_o, valC_o, valP_o, instr_valid_o, imem_error_o);

        // 测试4: IRMOVQ指令 (10字节)
        PC_i = 64'd4;
        #10;
        $display("%08h | %01h    | %01h   | %01h   | %01h   | %016h | %08h | %d     | %d",
                 PC_i, icode_o, ifun_o, rA_o, rB_o, valC_o, valP_o, instr_valid_o, imem_error_o);

        // 测试5: RMMOVQ指令 (10字节)
        PC_i = 64'd14;
        #10;
        $display("%08h | %01h    | %01h   | %01h   | %01h   | %016h | %08h | %d     | %d",
                 PC_i, icode_o, ifun_o, rA_o, rB_o, valC_o, valP_o, instr_valid_o, imem_error_o);

        // 测试6: OPQ指令 (2字节)
        PC_i = 64'd24;
        #10;
        $display("%08h | %01h    | %01h   | %01h   | %01h   | %016h | %08h | %d     | %d",
                 PC_i, icode_o, ifun_o, rA_o, rB_o, valC_o, valP_o, instr_valid_o, imem_error_o);

        // 测试7: 无效指令
        PC_i = 64'd26;
        #10;
        $display("%08h | %01h    | %01h   | %01h   | %01h   | %016h | %08h | %d     | %d",
                 PC_i, icode_o, ifun_o, rA_o, rB_o, valC_o, valP_o, instr_valid_o, imem_error_o);

        // 测试8: 内存越界
        PC_i = 64'd1024;
        #10;
        $display("%08h | %01h    | %01h   | %01h   | %01h   | %016h | %08h | %d     | %d",
                 PC_i, icode_o, ifun_o, rA_o, rB_o, valC_o, valP_o, instr_valid_o, imem_error_o);

        $display("================================================================================");
        $display("Simulation finished!");
        $finish;
    end

endmodule
