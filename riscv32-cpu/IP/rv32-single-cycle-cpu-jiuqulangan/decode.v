
module decode(
        input          clk,
		input          rst,
        input  [31:0]  inst_i,
	
	//from write back stage
	input          wb_rd_write_en_i,
	input  [4 :0]  wb_rd_id_i,
	input  [31:0]  wb_rd_write_data_i,         
	
	//rs1 rs2 rd 
	output [ 4:0]  decode_rs1_id_o,
	output [ 4:0]  decode_rs2_id_o,
	output [ 4:0]  decode_rd_id_o,
	output [11:0]  decode_csr_id_o,
	
	//to execute
	output [ 9:0]  decode_opcode_info_o,
	output [ 9:0]  decode_alu_info_o,
	output [ 5:0]  decode_branch_info_o,
	output [ 7:0]  decode_load_store_info_o,
	output [ 5:0]  decode_csr_info_o,
	
	// read data from regfile
	output [31:0]  regfile_rs1_rdata_o,
	output [31:0]  regfile_rs2_rdata_o,
	
	
	//to write back stage
	output         decode_rd_write_en_o,
	output [31:0]  decode_imm_o
        
	//for moniter
);

//for monitor


wire [6:0] opcode = inst_i[ 6: 0];
wire [4:0] rd     = inst_i[11: 7];
wire [2:0] funct3 = inst_i[14:12];
wire [4:0] rs1    = inst_i[19:15];
wire [4:0] rs2    = inst_i[24:20];
wire [6:0] funct7 = inst_i[31:25];

assign decode_rs1_id_o = rs1;
assign decode_rs2_id_o = rs2;
assign decode_rd_id_o  = rd;
assign decode_csr_id_o = inst_i[31:20];

//reg-imm
wire inst_alu_imm   = (opcode == 7'b00_100_11);

//reg-reg
wire inst_alu       = (opcode == 7'b01_100_11);

wire inst_jal       = (opcode == 7'b11_011_11);
wire inst_jalr      = (opcode == 7'b11_001_11);
wire inst_branch    = (opcode == 7'b11_000_11);

wire inst_load      = (opcode == 7'b00_000_11);
wire inst_store     = (opcode == 7'b01_000_11);
wire inst_lui       = (opcode == 7'b01_101_11);

wire inst_auipc     = (opcode == 7'b00_101_11);

wire inst_system    = (opcode == 7'b111_00_11);


//ALU op reg-imm
wire inst_addi  = inst_alu_imm   & (funct3 == 3'b000);
wire inst_slli  = inst_alu_imm   & (funct3 == 3'b001) & (funct7 == 7'b00_000_00);
wire inst_slti  = inst_alu_imm   & (funct3 == 3'b010);
wire inst_sltiu = inst_alu_imm   & (funct3 == 3'b011);
wire inst_xori  = inst_alu_imm   & (funct3 == 3'b100);
wire inst_srli  = inst_alu_imm   & (funct3 == 3'b101) & (funct7 == 7'b00_000_00);
wire inst_srai  = inst_alu_imm   & (funct3 == 3'b101) & (funct7 == 7'b01_000_00);
wire inst_ori   = inst_alu_imm   & (funct3 == 3'b110);
wire inst_andi  = inst_alu_imm   & (funct3 == 3'b111);

wire inst_add   = inst_alu   & (funct3 == 3'b000) & (funct7 == 7'b00_000_00);
wire inst_sub   = inst_alu   & (funct3 == 3'b000) & (funct7 == 7'b01_000_00);
wire inst_sll   = inst_alu   & (funct3 == 3'b001) & (funct7 == 7'b00_000_00);
wire inst_slt   = inst_alu   & (funct3 == 3'b010) & (funct7 == 7'b00_000_00);
wire inst_sltu  = inst_alu   & (funct3 == 3'b011) & (funct7 == 7'b00_000_00);
wire inst_xor   = inst_alu   & (funct3 == 3'b100) & (funct7 == 7'b00_000_00);
wire inst_srl   = inst_alu   & (funct3 == 3'b101) & (funct7 == 7'b00_000_00);
wire inst_sra   = inst_alu   & (funct3 == 3'b101) & (funct7 == 7'b01_000_00);
wire inst_or    = inst_alu   & (funct3 == 3'b110) & (funct7 == 7'b00_000_00);
wire inst_and   = inst_alu   & (funct3 == 3'b111) & (funct7 == 7'b00_000_00);

wire inst_beq   = inst_branch & (funct3 == 3'b000);
wire inst_bne   = inst_branch & (funct3 == 3'b001);
wire inst_blt   = inst_branch & (funct3 == 3'b100);
wire inst_bge   = inst_branch & (funct3 == 3'b101);
wire inst_bltu  = inst_branch & (funct3 == 3'b110);
wire inst_bgeu  = inst_branch & (funct3 == 3'b111);

//load instruction
wire inst_lb  = inst_load & (funct3 == 3'b000);
wire inst_lh  = inst_load & (funct3 == 3'b001);
wire inst_lw  = inst_load & (funct3 == 3'b010);
wire inst_lbu = inst_load & (funct3 == 3'b100);
wire inst_lhu = inst_load & (funct3 == 3'b101);

//store
wire inst_sb  = inst_store & (funct3 == 3'b000);
wire inst_sh  = inst_store & (funct3 == 3'b001);
wire inst_sw  = inst_store & (funct3 == 3'b010);

wire inst_ecall  = inst_system & (funct3 == 3'b000) & (inst_i[31:20] == 12'b0000_0000_0000);
wire inst_ebreak = inst_system & (funct3 == 3'b000) & (inst_i[31:20] == 12'b0000_0000_0001);
wire inst_mret   = inst_system & (funct3 == 3'b000) & (inst_i[31:20] == 12'b0011_0000_0010);

wire inst_csrrw  = inst_system & (funct3 == 3'b001);
wire inst_csrrs  = inst_system & (funct3 == 3'b010);
wire inst_csrrc  = inst_system & (funct3 == 3'b011);
wire inst_csrrwi = inst_system & (funct3 == 3'b101);
wire inst_csrrsi = inst_system & (funct3 == 3'b110);
wire inst_csrrci = inst_system & (funct3 == 3'b111);

assign decode_opcode_info_o = {
			        inst_alu_imm,    //9
				inst_alu,        //8
			        inst_branch,     //7
			        inst_jal,        //6
			        inst_jalr,       //5
			        inst_load,       //4
			        inst_store,      //3
			        inst_lui,        //2
			        inst_auipc,      //1
			        inst_system      //0
};

assign decode_alu_info_o = {
			     (inst_add  | inst_addi ),  // 9
			     (inst_sub              ),  // 8
                             (inst_sll  | inst_slli ),  // 7
			     (inst_slt  | inst_slti ),  // 6
			     (inst_sltu | inst_sltiu),  // 5
			     (inst_xor  | inst_xori ),  // 4
			     (inst_srl  | inst_srli ),  // 3
			     (inst_sra  | inst_srai ),  // 2
			     (inst_or   | inst_ori  ),  // 1
			     (inst_and  | inst_andi )   // 0   

 };

assign decode_branch_info_o = {
			        inst_beq,  // 5
			        inst_bne,  // 4
			        inst_blt,  // 3
			        inst_bge,  // 2
			        inst_bltu, // 1
			        inst_bgeu  // 0						
};

assign decode_load_store_info_o = {
			           inst_lb,  // 7 
				   inst_lh,  // 6
				   inst_lw,  // 5
				   inst_lbu, // 4
				   inst_lhu, // 3
				   inst_sb,  // 2
				   inst_sh,  // 1
				   inst_sw   // 0								
};

assign decode_csr_info_o = {
		             inst_csrrw,   // 5
			     inst_csrrs,   // 4
			     inst_csrrc,   // 3
			     inst_csrrwi,  // 2
			     inst_csrrsi,  // 1
			     inst_csrrci   // 0
};

wire decode_ecall_o  = inst_ecall;
wire decode_ebreak_o = inst_ebreak;
wire decode_mret_o   = inst_mret;

//lui auipc jal 
//csr
//ecall
wire inst_need_rs1 = (~inst_lui)    & (~inst_auipc)  & (~inst_jal)    &
	            		 (~inst_csrrwi) & (~inst_csrrsi) & (~inst_csrrci) &
		    		 (~inst_ecall)  & (~inst_ebreak) & (~inst_mret);
					 

wire inst_need_rs2 = (inst_alu | inst_branch | inst_store);


wire inst_need_rd = (~inst_ecall)  & (~inst_ebreak) & (~inst_mret) &
                    (~inst_branch) & (~inst_store);

wire inst_need_csr = inst_csrrw  | inst_csrrs  | inst_csrrc |
                     inst_csrrwi | inst_csrrsi | inst_csrrci;

// to write back stage
assign decode_rd_write_en_o  = inst_need_rd;

//assign decode_csr_wen_o = inst_need_csr;	


wire [31:0] inst_i_imm = { {20{inst_i[31]}}, inst_i[31:20] };		
wire [31:0] inst_s_imm = { {20{inst_i[31]}}, inst_i[31:25], inst_i[11:7] };	
wire [31:0] inst_b_imm = { {19{inst_i[31]}}, inst_i[31],    inst_i[7],      inst_i[30:25], inst_i[11:8 ], 1'b0};
wire [31:0] inst_j_imm = { {11{inst_i[31]}}, inst_i[31],    inst_i[19:12],  inst_i[20],    inst_i[30:21], 1'b0};	
wire [31:0] inst_u_imm = { inst_i[31:12], 12'b0};			 

wire inst_imm_sel_i = inst_alu_imm | inst_load | inst_jalr;
wire inst_imm_sel_s = inst_store;
wire inst_imm_sel_b = inst_branch;
wire inst_imm_sel_j = inst_jal;
wire inst_imm_sel_u = inst_lui | inst_auipc;

wire [31:0] inst_imm = ({32{inst_imm_sel_i}} & inst_i_imm) |
		       ({32{inst_imm_sel_s}} & inst_s_imm) |
		       ({32{inst_imm_sel_b}} & inst_b_imm) |
		       ({32{inst_imm_sel_j}} & inst_j_imm) |
		       ({32{inst_imm_sel_u}} & inst_u_imm);
						 
assign decode_imm_o = inst_imm;

regfile regfile_module(
		.clk               (clk),
                .rst               (rst),		
		// rs1 rs2 
		.rs1_id_i          (decode_rs1_id_o),
		.rs2_id_i          (decode_rs2_id_o),
		
		.rs1_rdata_o       (regfile_rs1_rdata_o),
		.rs2_rdata_o       (regfile_rs2_rdata_o),
		
		// write data to regfile
		.w_en              (wb_rd_write_en_i),
		.rd_id_i           (wb_rd_id_i),
		.rd_write_data_i   (wb_rd_write_data_i)

		//for minitor
);
endmodule
