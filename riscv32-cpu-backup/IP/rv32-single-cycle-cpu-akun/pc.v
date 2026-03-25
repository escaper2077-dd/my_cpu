`include "define.v"
module PCU(
	input wire  clk,
	input wire  rst, 

	input wire  [1:0]  CTRL_i_pc_sel, 
	input wire  [31:0] EXU_i_valE,
	input wire  [31:0] CSR_i_CSR_valP,
	input wire  [31:0] IFU_i_next_pc,
	output wire [31:0] PCU_o_pc
);

reg [31:0] pc;
assign PCU_o_pc   = pc;

always @(posedge clk) begin
	if(rst) begin
		pc <= 32'h80000000;
	end
	else begin
		pc <= CTRL_i_pc_sel == `pc_sel_valE	 	? EXU_i_valE :
		      CTRL_i_pc_sel == `pc_sel_CSR_valP ? CSR_i_CSR_valP:
			  CTRL_i_pc_sel == `pc_sel_valP     ? IFU_i_next_pc   : 32'hffffffff;
	end
end
endmodule 