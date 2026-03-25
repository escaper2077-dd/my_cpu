module commit(

    input  wire [31:0] PCU_i_pc,
    input  wire [31:0] IFU_i_instr,
    input  wire [31:0] IFU_i_next_pc,

	input wire  [1:0]  CTRL_i_pc_sel, 

	input wire  [31:0] EXU_i_valE,
	input wire  [31:0] CSR_i_CSR_valP,

	output wire [31:0] cur_pc,
	output wire 	   commit,
	output wire [31:0] commit_pc,
	output wire [31:0] commit_instr,
	output wire [31:0] commit_next_pc,
	output wire [31:0] commit_mem_addr,
	output wire [31:0] commit_mem_wdata,
	output wire [31:0] commit_mem_rdata
);


assign cur_pc           = PCU_i_pc;
assign commit_pc	 	= PCU_i_pc;
assign commit			= 1'b1;
assign commit_instr     = IFU_i_instr;
assign commit_next_pc   = CTRL_i_pc_sel == `pc_sel_valE     ? EXU_i_valE        : 
                          CTRL_i_pc_sel == `pc_sel_CSR_valP ? CSR_i_CSR_valP    : IFU_i_next_pc;

//now not use
assign commit_mem_addr  = 32'd0;
assign commit_mem_rdata = 32'd0;
assign commit_mem_wdata = 32'd0;

endmodule