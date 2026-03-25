`define FUNC_ADD 		4'b0000
`define FUNC_SUB 		4'b0001
`define FUNC_SLL 		4'b0010
`define FUNC_SLT 		4'b0011
`define FUNC_SLTU 		4'b0100
`define FUNC_XOR  		4'b0101
`define FUNC_SRL  		4'b0110
`define FUNC_SRA  		4'b0111
`define FUNC_OR   		4'b1000
`define FUNC_AND  		4'b1001
`define FUNC_JALR 		4'b1010
`define FUNC_SEL_VALC 	4'b1011

//for valcC
`define valC_U_TYPE  3'b000
`define valC_I_TYPE  3'b001
`define valC_I_SHAMT 3'b010
`define valC_S_TYPE  3'b011
`define valC_R_TYPE  3'b100
`define valC_B_TYPE  3'b101
`define valC_J_TYPE  3'b110
`define valC_ZERO    3'b111

//for mem
`define mem_lb  	4'b0000
`define mem_lbu 	4'b0001
`define mem_lh  	4'b0010
`define mem_lhu 	4'b0011
`define mem_lw  	4'b0100
`define mem_sb  	4'b0101
`define mem_sh 		4'b0110
`define mem_sw  	4'b0111
`define mem_no_rw 	4'b1000

`define pc_sel_valP 	2'b00
`define pc_sel_valE 	2'b01
`define pc_sel_CSR_valP 2'b10

`define wb_sel_valE 2'b00
`define wb_sel_valM 2'b01
`define wb_sel_valP 2'b10
`define wb_sel_valR 2'b11


`define valB_sel_valB 1'b1
`define valB_sel_valC 1'b0
`define valA_sel_valA 1'b1
`define valA_sel_pc   1'b0


`define reg_wen_w 1'b1
`define reg_wen_no_w 1'b0


`define csr_none  3'b000
`define csr_csrrw 3'b001
`define csr_csrrs 3'b010
`define csr_ecall 3'b011
`define csr_mret  3'b100
// 如果你需要保留原始命名风格
`define mstatus      12'h300
`define mtvec        12'h305
`define mepc         12'h341
`define mcause       12'h342