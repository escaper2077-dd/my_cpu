`include "define.v"
module REGU(
	input wire 								clk,
	input wire 								rst,
	input wire 	[4	:0]			IDU_i_rs1,
	input wire 	[4	:0]			IDU_i_rs2,
	input wire 								IDU_i_reg_wen,
	input wire 	[4	:0]			IDU_i_rd,
	input wire  [31		:0] 		IDU_i_valW,
	output wire [31		:0] 		REGU_o_valA,
	output wire [31		:0] 		REGU_o_valB
);	
reg [31:0] regfile[31:0];
import "DPI-C" function void dpi_read_regfile(input logic [31 : 0] a []);

initial begin
	dpi_read_regfile(regfile);
end


assign REGU_o_valA = regfile[IDU_i_rs1];
assign REGU_o_valB = regfile[IDU_i_rs2];


always @(posedge clk) begin
	if(rst) begin
		regfile[0] <= 32'h0;
	end
	else if(IDU_i_reg_wen == `reg_wen_w && IDU_i_rd != 0) begin
		regfile[IDU_i_rd] <= IDU_i_valW;
	end
end
endmodule //

