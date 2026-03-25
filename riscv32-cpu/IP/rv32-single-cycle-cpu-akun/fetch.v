module IFU(
	input wire  [31:0] PCU_i_pc,
	output wire [31:0] IFU_o_next_pc, 
	output wire [31:0] IFU_o_instr
);
import "DPI-C" function int  dpi_mem_read 	(input int addr  , input int len);

assign IFU_o_instr = dpi_mem_read(PCU_i_pc, 4);

assign IFU_o_next_pc = PCU_i_pc + 32'd4;
endmodule