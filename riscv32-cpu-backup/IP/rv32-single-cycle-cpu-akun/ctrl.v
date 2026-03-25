`include "define.v"
module CTRL(
	input  wire [31:0] IFU_i_instr,
	input  wire        BR_JMP_i_br_lt,
	input  wire        BR_JMP_i_br_eq,
	output wire        CTRL_o_valA_sel,
	output wire        CTRL_o_valB_sel,
	output wire  [3:0] CTRL_o_ALU_sel,
	output wire        CTRL_o_reg_wen,
	output wire  [1:0] CTRL_o_wb_sel,
	output wire        CTRL_o_br_un,
	output wire  [2:0] CTRL_o_valC_sel, 
	output wire  [1:0] CTRL_o_pc_sel,
	output wire  [3:0] CTRL_o_mem_rw,
	output wire  [2:0] CTRL_o_csr_flag
);
wire [31:0]instr = IFU_i_instr;
wire [4:0] opcode= instr[6:2]; 
wire [2:0] func3  = instr[14:12];
wire [6:0] func7  = instr[31:25];

wire opcode_5_11001 = (opcode ==    5'b11001); //jalr
wire opcode_5_11011 = (opcode ==    5'b11011); //jal
wire opcode_5_11000 = (opcode ==    5'b11000); //beq
wire opcode_5_01000 = (opcode ==    5'b01000); //save
wire opcode_5_00000 = (opcode ==    5'b00000); //load
wire opcode_5_01100 = (opcode ==    5'b01100); //add
wire opcode_5_00100 = (opcode ==    5'b00100); //addi
wire opcode_5_00101 = (opcode ==    5'b00101); //auipc
wire opcode_5_01101 = (opcode ==    5'b01101); //lui
wire opcode_5_11100 = (opcode ==    5'b11100); //ecall

wire func3_000 	= (func3 == 3'b000);
wire func3_001  = (func3 == 3'b001);
wire func3_010  = (func3 == 3'b010);
wire func3_011  = (func3 == 3'b011);
wire func3_100 	= (func3 == 3'b100);
wire func3_101  = (func3 == 3'b101);
wire func3_110	= (func3 == 3'b110);
wire func3_111	= (func3 == 3'b111);

wire func7_00 = (func7[6:5] == 2'b00);
wire func7_01 = (func7[6:5] == 2'b01);

//----------
wire rv32_ecall = (instr == 32'h00000073);
wire rv32_mret  = (instr == 32'h30200073);
wire rv32_csrrw = (opcode_5_11100 & func3_001); //I型指令
wire rv32_csrrs = (opcode_5_11100 & func3_010); //I型指令




//2
wire rv32_lui   = (opcode_5_01101);
wire rv32_auipc = (opcode_5_00101);
//9
wire rv32_ADDI_FAM 	=	(opcode_5_00100); 
wire rv32_addi  = (opcode_5_00100 & func3_000 );
wire rv32_slli  = (opcode_5_00100 & func3_001 & func7_00);
wire rv32_slti  = (opcode_5_00100 & func3_010 );
wire rv32_sltiu = (opcode_5_00100 & func3_011 ); 

wire rv32_xori  = (opcode_5_00100 & func3_100 );
wire rv32_srli  = (opcode_5_00100 & func3_101 & func7_00);
wire rv32_srai  = (opcode_5_00100 & func3_101 & func7_01); //01
wire rv32_ori   = (opcode_5_00100 & func3_110 );
wire rv32_andi  = (opcode_5_00100 & func3_111 );


//10
wire rv32_ADD_FAM  	=	(opcode_5_01100);
wire rv32_add   = (opcode_5_01100 & func3_000 & func7_00);
wire rv32_sub   = (opcode_5_01100 & func3_000 & func7_01); //01
wire rv32_sll   = (opcode_5_01100 & func3_001 & func7_00);
wire rv32_slt   = (opcode_5_01100 & func3_010 & func7_00);
wire rv32_sltu  = (opcode_5_01100 & func3_011 & func7_00);
wire rv32_xor   = (opcode_5_01100 & func3_100 & func7_00);
wire rv32_srl   = (opcode_5_01100 & func3_101 & func7_00);
wire rv32_sra   = (opcode_5_01100 & func3_101 & func7_01); //01
wire rv32_or    = (opcode_5_01100 & func3_110 & func7_00); 
wire rv32_and   = (opcode_5_01100 & func3_111 & func7_00); 

//5
wire rv32_LOAD   	= 	(opcode_5_00000);
wire rv32_lb    = (opcode_5_00000 & func3_000);
wire rv32_lh    = (opcode_5_00000 & func3_001);
wire rv32_lw    = (opcode_5_00000 & func3_010);
wire rv32_lbu   = (opcode_5_00000 & func3_100);
wire rv32_lhu   = (opcode_5_00000 & func3_101);


//3
wire rv32_SAVE  	= 	(opcode_5_01000);
wire rv32_sb    = (opcode_5_01000 & func3_000);
wire rv32_sh    = (opcode_5_01000 & func3_001);
wire rv32_sw    = (opcode_5_01000 & func3_010);
//2
wire rv32_jal   = (opcode_5_11011);
wire rv32_jalr  = (opcode_5_11001 & func3_000);

//6
wire rv32_BEQ_FAM  	=	(opcode_5_11000);
wire rv32_beq   = (opcode_5_11000 & func3_000);
wire rv32_bne   = (opcode_5_11000 & func3_001);
wire rv32_blt   = (opcode_5_11000 & func3_100);
wire rv32_bge   = (opcode_5_11000 & func3_101);
wire rv32_bltu  = (opcode_5_11000 & func3_110);
wire rv32_bgeu  = (opcode_5_11000 & func3_111);


wire rv32_I_TYPE    = (rv32_LOAD | rv32_ADDI_FAM | rv32_jalr | rv32_csrrs | rv32_csrrw);
wire rv32_R_TYPE    = (rv32_ADD_FAM);
wire rv32_U_TYPE    = (rv32_lui | rv32_auipc);
wire rv32_J_TYPE    = (rv32_jal);
wire rv32_S_TYPE    = (rv32_SAVE);
wire rv32_B_TYPE    = (rv32_BEQ_FAM);




//这三个信号是相关联的
assign  CTRL_o_valA_sel =  (rv32_I_TYPE | rv32_R_TYPE | rv32_S_TYPE ) ?  `valA_sel_valA  : 
					  	   (rv32_U_TYPE | rv32_J_TYPE | rv32_B_TYPE)  ? `valA_sel_pc : `valA_sel_valA;


assign  CTRL_o_valB_sel = 	(rv32_R_TYPE) ? `valB_sel_valB: 
				  		 	(rv32_I_TYPE | rv32_S_TYPE | rv32_B_TYPE | rv32_U_TYPE | rv32_J_TYPE) ? `valB_sel_valC : `valB_sel_valB;

assign CTRL_o_reg_wen = (rv32_I_TYPE | rv32_R_TYPE | rv32_U_TYPE | rv32_J_TYPE)  ? `reg_wen_w : `reg_wen_no_w;


assign CTRL_o_ALU_sel = 	(rv32_add | rv32_addi  )  ? `FUNC_ADD:
							(rv32_sub              )  ? `FUNC_SUB:
							(rv32_sll | rv32_slli  )  ? `FUNC_SLL:
							(rv32_slt | rv32_slti  )  ? `FUNC_SLT:
							(rv32_sltu| rv32_sltiu )  ? `FUNC_SLTU:
							(rv32_xor | rv32_xori  )  ? `FUNC_XOR:
							(rv32_srl | rv32_srli  )  ? `FUNC_SRL:
							(rv32_sra | rv32_srai  )  ? `FUNC_SRA:
							(rv32_or  | rv32_ori   )  ? `FUNC_OR :
							(rv32_and | rv32_andi  )  ? `FUNC_AND:
							(rv32_jalr             )  ? `FUNC_JALR: 
							(rv32_lui)                ? `FUNC_SEL_VALC : `FUNC_ADD;


//B型指令，只修改pc
//S型指令，写入内存，不写入寄存器
//这两个信号是相关联的
assign CTRL_o_reg_wen = (rv32_I_TYPE | rv32_R_TYPE | rv32_U_TYPE | rv32_J_TYPE)  ? `reg_wen_w : `reg_wen_no_w;

assign CTRL_o_wb_sel  = (rv32_R_TYPE | rv32_ADDI_FAM | rv32_U_TYPE)  ? `wb_sel_valE :
						(rv32_LOAD)                  				 ? `wb_sel_valM :
						(rv32_jalr   | rv32_J_TYPE)               	 ? `wb_sel_valP : 
						(rv32_csrrw  | rv32_csrrs)                   ? `wb_sel_valR : `wb_sel_valM;


assign CTRL_o_br_un  =  (rv32_bltu | rv32_bgeu) ? 1'b1 : 1'b0;

assign CTRL_o_pc_sel =  (rv32_beq   &  BR_JMP_i_br_eq)   ? `pc_sel_valE :
						(rv32_bne   & (~BR_JMP_i_br_eq)) ? `pc_sel_valE :
						(rv32_blt   &  BR_JMP_i_br_lt)   ? `pc_sel_valE :
						(rv32_bge   & (~BR_JMP_i_br_lt)) ? `pc_sel_valE :
						(rv32_bltu  &   BR_JMP_i_br_lt ) ? `pc_sel_valE :
						(rv32_bgeu  & (~BR_JMP_i_br_lt)) ? `pc_sel_valE :
						(rv32_jal | rv32_jalr)           ? `pc_sel_valE : 
						(rv32_ecall | rv32_mret)   	     ? `pc_sel_CSR_valP : `pc_sel_valP;


assign CTRL_o_mem_rw =  (rv32_lb) ? `mem_lb  :
						(rv32_lbu)? `mem_lbu :
						(rv32_lh) ? `mem_lh  :
						(rv32_lhu)? `mem_lhu :
						(rv32_lw) ? `mem_lw  :
						(rv32_sb) ? `mem_sb  :
						(rv32_sh) ? `mem_sh  :
						(rv32_sw) ? `mem_sw  : `mem_no_rw; 


assign CTRL_o_valC_sel = (rv32_U_TYPE) ? `valC_U_TYPE : 
						 (rv32_I_TYPE) ? (rv32_slli | rv32_srli | rv32_srai) ?   `valC_I_SHAMT : `valC_I_TYPE :
						 (rv32_S_TYPE) ? `valC_S_TYPE : 
						 (rv32_R_TYPE) ? `valC_R_TYPE :
						 (rv32_B_TYPE) ? `valC_B_TYPE :
						 (rv32_J_TYPE) ? `valC_J_TYPE :  `valC_ZERO;

assign CTRL_o_csr_flag  = (rv32_csrrw) ? `csr_csrrw :
                      	  (rv32_csrrs) ? `csr_csrrs :
						  (rv32_ecall) ? `csr_ecall :
						  (rv32_mret ) ? `csr_mret  : `csr_none;
endmodule


