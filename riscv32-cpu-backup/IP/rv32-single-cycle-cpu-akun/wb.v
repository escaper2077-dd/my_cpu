`include "define.v"
module WBU(
	input wire 			[1:0]		CTRL_i_wb_sel,
	input wire  [31 : 0]     IFU_i_next_pc,
	input wire 	[31 : 0] 	 MEM_i_valM,
	input wire 	[31 : 0]	 EXU_i_valE,
	input wire  [31 : 0]     CSR_i_valR,
	output wire [31 : 0]     WBU_o_valW
);

wire sel_valM = CTRL_i_wb_sel== `wb_sel_valM;
wire sel_valE = CTRL_i_wb_sel== `wb_sel_valE;
wire sel_valP = CTRL_i_wb_sel== `wb_sel_valP;
wire sel_valR = CTRL_i_wb_sel== `wb_sel_valR;
assign WBU_o_valW[31 : 0] = 	(sel_valM) ? MEM_i_valM 	:
									(sel_valE) ? EXU_i_valE 	:
									(sel_valP) ? IFU_i_next_pc  :
									(sel_valR) ? CSR_i_valR 	: 32'd0;
endmodule