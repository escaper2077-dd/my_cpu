//最顶层模块必须包含以下这些信号
module TOP_Module_Name(
    input  wire         clk,                 
    input  wire         rst,                

    output wire [31:0]  cur_pc,             // 这个信号连接到当前PC寄存器的实时值

    output wire         commit,             // 单周期处理器里恒为1
    output wire [31:0]  commit_pc,          // 连接到刚执行指令的PC值（单周期处理器中与cur_pc相同）
    output wire [31:0]  commit_instr,       // 连接到刚执行的指令
    output wire [31:0]  commit_next_pc,     // 连接到执行完当前指令后的下一条指令PC值，分支/跳转指令需根据执行结果修正该值

    output wire [31:0]  commit_mem_addr,    // 固定赋值为32'd0,单周期处理器不会使用
    output wire [31:0]  commit_mem_wdata,   // 固定赋值为32'd0,单周期处理器不会使用
    output wire [31:0]  commit_mem_rdata    // 固定赋值为32'd0,单周期处理器不会使用
);



endmodule