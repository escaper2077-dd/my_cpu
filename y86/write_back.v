`timescale 1ps/1ps

module write_back(
    // Input signals from Memory Access stage
    input wire [3:0] icode_i,
    input wire [63:0] valE_i,
    input wire [63:0] valM_i,
    
    input wire instr_valid_i,
    input wire imem_error_i,
    input wire dmem_error_i,
    
    // Output signals
    output wire [63:0] valE_o,
    output wire [63:0] valM_o,
    output wire [1:0] stat_o
);

    // 直接传递 valE 和 valM 到下一阶段（或寄存器写回）
    assign valE_o = valE_i;
    assign valM_o = valM_i;

    // 实例化 stat 模块来确定 CPU 状态
    stat stat_module(
        .instr_valid_i(instr_valid_i),
        .imem_error_i(imem_error_i),
        .dmem_error_i(dmem_error_i),
        .stat_o(stat_o)
    );

endmodule
