module top_cpu(
	input wire clk,
	input wire rst,
	output wire [31:0] cur_pc,
	output wire 	   commit,
	output wire [31:0] commit_pc,
	output wire [31:0] commit_instr,
	output wire [31:0] commit_next_pc,
	output wire [31:0] commit_mem_addr,
	output wire [31:0] commit_mem_wdata,
	output wire [31:0] commit_mem_rdata
);
// outports wire
wire [31:0] 	PCU_o_pc;

PCU u_PCU(
	.clk            	( clk             ),
	.rst            	( rst             ),
	.CTRL_i_pc_sel  	( CTRL_o_pc_sel    ),
	.EXU_i_valE     	( EXU_o_valE       ),
	.CSR_i_CSR_valP 	( CSR_o_CSR_valP   ),
	.IFU_i_next_pc  	( IFU_o_next_pc    ),
	.PCU_o_pc       	( PCU_o_pc        )
);
// outports wire
wire [31:0] 	IFU_o_next_pc;
wire [31:0] 	IFU_o_instr;

IFU u_IFU(
	.PCU_i_pc      	( PCU_o_pc        ),
	.IFU_o_next_pc 	( IFU_o_next_pc  ),
	.IFU_o_instr   	( IFU_o_instr    )
);
// outports wire
wire [31:0] 	IDU_o_valA;
wire [31:0] 	IDU_o_valB;
wire [31:0] 	IDU_o_valC;
wire [11:0] 	IDU_o_csr_id;

IDU u_IDU(
	.PCU_i_pc        	( PCU_o_pc          ),
	.clk             	( clk              ),
	.rst             	( rst              ),
	.IFU_i_instr     	( IFU_o_instr       ),
	.CTRL_i_reg_wen  	( CTRL_o_reg_wen    ),
	.CTRL_i_valC_sel 	( CTRL_o_valC_sel   ),
	.WBU_i_valW      	( WBU_o_valW        ),
	.IDU_o_valA      	( IDU_o_valA       ),
	.IDU_o_valB      	( IDU_o_valB       ),
	.IDU_o_valC      	( IDU_o_valC       ),
	.IDU_o_csr_id    	( IDU_o_csr_id     )
);
// outports wire
wire [31:0] 	EXU_o_valE;

EXU u_EXU(
	.clk             	( clk              ),
	.CTRL_i_valA_sel 	( CTRL_o_valA_sel   ),
	.CTRL_i_valB_sel 	( CTRL_o_valB_sel   ),
	.CTRL_i_ALU_sel  	( CTRL_o_ALU_sel    ),
	.IDU_i_valA      	( IDU_o_valA        ),
	.IDU_i_valB      	( IDU_o_valB        ),
	.IDU_i_valC      	( IDU_o_valC        ),
	.PCU_i_pc        	( PCU_o_pc          ),
	.EXU_o_valE      	( EXU_o_valE       )
);
// outports wire
wire [31:0] 	MEM_o_valM;

MEMU u_MEMU(
	.clk           	( clk            ),
	.rst           	( rst            ),
	.EXU_i_valE    	( EXU_o_valE      ),
	.IDU_i_valB    	( IDU_o_valB      ),
	.CTRL_i_mem_rw 	( CTRL_o_mem_rw   ),
	.MEM_o_valM    	( MEM_o_valM     )
);
// outports wire
// outports wire
wire [31:0] 	WBU_o_valW;

WBU u_WBU(
	.CTRL_i_wb_sel 	( CTRL_o_wb_sel   ),
	.IFU_i_next_pc 	( IFU_o_next_pc   ),
	.MEM_i_valM    	( MEM_o_valM      ),
	.EXU_i_valE    	( EXU_o_valE      ),
	.CSR_i_valR    	( CSR_o_valR      ),
	.WBU_o_valW    	( WBU_o_valW     )
);

// outports wire
// outports wire
wire [31:0] 	CSR_o_valR;
wire [31:0] 	CSR_o_CSR_valP;

CSR u_CSR(
	.clk            	( clk             ),
	.rst            	( rst             ),
	.IFU_i_instr    	( IFU_o_instr      ),
	.PCU_i_pc       	( PCU_o_pc         ),
	.IDU_i_valA     	( IDU_o_valA       ),
	.CSR_o_valR     	( CSR_o_valR      ),
	.CSR_o_CSR_valP 	( CSR_o_CSR_valP  )
);


// outports wire
wire        	CTRL_o_valA_sel;
wire        	CTRL_o_valB_sel;
wire [3:0]  	CTRL_o_ALU_sel;
wire        	CTRL_o_reg_wen;
wire [1:0]  	CTRL_o_wb_sel;
wire        	CTRL_o_br_un;
wire [2:0]  	CTRL_o_valC_sel;
wire [1:0]  	CTRL_o_pc_sel;
wire [3:0]  	CTRL_o_mem_rw;
wire [2:0]  	CTRL_o_csr_flag;

CTRL u_CTRL(
	.IFU_i_instr     	( IFU_o_instr       ),
	.BR_JMP_i_br_lt  	( BR_JMP_o_br_lt    ),
	.BR_JMP_i_br_eq  	( BR_JMP_o_br_eq    ),
	.CTRL_o_valA_sel 	( CTRL_o_valA_sel  ),
	.CTRL_o_valB_sel 	( CTRL_o_valB_sel  ),
	.CTRL_o_ALU_sel  	( CTRL_o_ALU_sel   ),
	.CTRL_o_reg_wen  	( CTRL_o_reg_wen   ),
	.CTRL_o_wb_sel   	( CTRL_o_wb_sel    ),
	.CTRL_o_br_un    	( CTRL_o_br_un     ),
	.CTRL_o_valC_sel 	( CTRL_o_valC_sel  ),
	.CTRL_o_pc_sel   	( CTRL_o_pc_sel    ),
	.CTRL_o_mem_rw   	( CTRL_o_mem_rw    ),
	.CTRL_o_csr_flag 	( CTRL_o_csr_flag  )
);

commit u_commit(
	.PCU_i_pc         	( PCU_o_pc           ),
	.IFU_i_instr      	( IFU_o_instr        ),
	.IFU_i_next_pc    	( IFU_o_next_pc      ),
	.CTRL_i_pc_sel    	( CTRL_o_pc_sel      ),
	.EXU_i_valE       	( EXU_o_valE         ),
	.CSR_i_CSR_valP   	( CSR_o_CSR_valP     ),
	.cur_pc           	( cur_pc            ),
	.commit           	( commit            ),
	.commit_pc        	( commit_pc         ),
	.commit_instr     	( commit_instr      ),
	.commit_next_pc   	( commit_next_pc    ),
	.commit_mem_addr  	( commit_mem_addr   ),
	.commit_mem_wdata 	( commit_mem_wdata  ),
	.commit_mem_rdata 	( commit_mem_rdata  )
);

// outports wire
wire        	BR_JMP_o_br_eq;
wire        	BR_JMP_o_br_lt;

BR_JMP u_BR_JMP(
	.CTRL_i_br_un   	( CTRL_o_br_un     ),
	.IDU_i_valA     	( IDU_o_valA       ),
	.IDU_i_valB     	( IDU_o_valB       ),
	.BR_JMP_o_br_eq 	( BR_JMP_o_br_eq  ),
	.BR_JMP_o_br_lt 	( BR_JMP_o_br_lt  )
);

endmodule

