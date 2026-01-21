`timescale 1ps/1ps

module y86_cpu(
    // Clock and Reset
    input wire clk_i,
    input wire rst_n_i,
    
    // Status output
    output wire [1:0] stat_o,
    
    // Debug outputs (optional)
    output wire [63:0] PC_o,
    output wire [3:0] icode_o
);

    // ==================== 阶段间连接信号 ====================
    
    // PC
    wire [63:0] PC;
    
    // Fetch stage outputs
    wire [3:0] icode;
    wire [3:0] ifun;
    wire [3:0] rA;
    wire [3:0] rB;
    wire [63:0] valC;
    wire [63:0] valP;
    wire instr_valid;
    wire imem_error;
    
    // Decode stage outputs
    wire [63:0] valA;
    wire [63:0] valB;
    
    // Execute stage outputs
    wire [63:0] valE;
    wire Cnd;
    
    // Memory Access stage outputs
    wire [63:0] valM;
    wire dmem_error;
    
    // Write Back stage outputs
    wire [63:0] valE_wb;
    wire [63:0] valM_wb;
    
    // ==================== 各个阶段实例化 ====================
    
    // Fetch Stage
    fetch fetch_stage(
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .PC_i(PC),
        .icode_o(icode),
        .ifun_o(ifun),
        .rA_o(rA),
        .rB_o(rB),
        .valC_o(valC),
        .valP_o(valP),
        .instr_valid_o(instr_valid),
        .imem_error_o(imem_error)
    );
    
    // Decode Stage (with register write-back)
    decode decode_stage(
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .icode_i(icode),
        .rA_i(rA),
        .rB_i(rB),
        .valE_i(valE_wb),
        .valM_i(valM_wb),
        .cnd_i(Cnd),
        .valA_o(valA),
        .valB_o(valB)
    );
    
    // Execute Stage
    execute execute_stage(
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .icode_i(icode),
        .ifun_i(ifun),
        .valA_i(valA),
        .valB_i(valB),
        .valC_i(valC),
        .valE_o(valE),
        .Cnd_o(Cnd)
    );
    
    // Memory Access Stage
    memory_access memory_stage(
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .icode_i(icode),
        .valE_i(valE),
        .valA_i(valA),
        .valP_i(valP),
        .valM_o(valM),
        .dmem_error_o(dmem_error)
    );
    
    // Write Back Stage
    write_back writeback_stage(
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .icode_i(icode),
        .valE_i(valE),
        .valM_i(valM),
        .instr_valid_i(instr_valid),
        .imem_error_i(imem_error),
        .dmem_error_i(dmem_error),
        .valE_o(valE_wb),
        .valM_o(valM_wb),
        .stat_o(stat_o)
    );
    
    // PC Update Stage
    pc_update pc_update_stage(
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .icode_i(icode),
        .cnd_i(Cnd),
        .valC_i(valC),
        .valM_i(valM),
        .valP_i(valP),
        .stat_i(stat_o),
        .PC_o(PC)
    );
    
    // Debug outputs
    assign PC_o = PC;
    assign icode_o = icode;

endmodule
