module execute(	   
	   input  [9:0]   opcode_info_i,
	   input  [9:0]   alu_info_i,
	   input  [5:0]   branch_info_i,	   
	   input  [7:0]   load_store_info_i,
	   
	   input  [31:0]  pc_i,	
	   input  [31:0]  regfile_rs1_rdata_i,
	   input  [31:0]  regfile_rs2_rdata_i,
	   input  [31:0]  imm_i,

           output [31:0]  execute_alu_result_o,
	   output [31:0]  execute_mem_addr_o,
	   output         execute_branch_jump_o
);

alu alu_module(
	.opcode_info_i     (opcode_info_i    ),
	.alu_info_i        (alu_info_i       ),
	.branch_info_i     (branch_info_i    ),
	.load_store_info_i (load_store_info_i),

	.pc_i              (pc_i               ),
	.rs1_data_i        (regfile_rs1_rdata_i),
	.rs2_data_i        (regfile_rs2_rdata_i),
	.imm_i             (imm_i              ),
	
	.alu_result_o      (execute_alu_result_o ),
	.mem_addr_o        (execute_mem_addr_o   ),
	.alu_branch_jump_o (execute_branch_jump_o)
);

endmodule
