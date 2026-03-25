
`include "define.v"
module CSR(
	input wire         clk,
	input wire         rst,
	input wire  [31:0] IFU_i_instr,
	input wire  [31:0] PCU_i_pc, 
	input wire  [31:0] IDU_i_valA,
	output wire [31:0] CSR_o_valR,  
	output wire [31:0] CSR_o_CSR_valP
);

reg [31:0] csrfile[4096];
import "DPI-C" function void dpi_read_csrfile(input logic [31 : 0] a []); 
initial begin
    integer i;
    for (i = 0; i < 4096; i = i + 1) begin
        csrfile[i] = 32'd0; 
    end
    dpi_read_csrfile(csrfile);
end

wire [31:0]  instr  = IFU_i_instr;
wire [11:0]  csr_id = instr[31:20];


wire [31:0] mstatus = csrfile[`mstatus];
wire [31:0] mtvec   = csrfile[`mtvec];
wire [31:0] mepc	 = csrfile[`mepc ];
wire [31:0] mcasue  = csrfile[`mcause];

wire inst_csrrw = instr[6:0] == 7'b1110011 && instr[14:12] == 3'b010;
wire inst_csrrs = instr[6:0] == 7'b1110011 && instr[14:12] == 3'b001;
wire inst_ecall = (instr == 32'b000000000000_00000_000_00000_1110011);
wire inst_mret  = (instr == 32'b001100000010_00000_000_00000_1110011);


wire right_csr_id = (csr_id == `mstatus) | (csr_id == `mtvec) | (csr_id == `mepc) | (csr_id == `mcause);  

wire   		 csr_wen   = inst_csrrw | inst_csrrs;
wire [31:0]  csr_wdata  = (inst_csrrw)   ?   IDU_i_valA : 
						  (inst_csrrs)   ?   csrfile[csr_id] | IDU_i_valA: 32'hFFFF_FFFF;

assign 		CSR_o_valR 	   = (right_csr_id) ?   csrfile[csr_id] : 32'hFFFF_FFFF;

assign 		CSR_o_CSR_valP = (inst_ecall)   ?   mtvec			:
							 (inst_mret)    ?   mepc			: 32'hFFFF_FFFF;

always @(posedge clk) begin
	if(rst) begin
		csrfile[`mstatus]  <= 32'h1800;
		csrfile[`mtvec]    <= 32'd0;
		csrfile[`mepc]     <= 32'd0;
		csrfile[`mcause]   <= 32'd0; 
	end
	else if(inst_ecall) begin
		csrfile[`mepc]     <= PCU_i_pc + 32'd4;
		csrfile[`mcause]   <= 32'd1;
	end
	//do nothing
	else if(inst_mret) begin
	end
    else if(csr_wen && right_csr_id) begin
        csrfile[csr_id] <= csr_wdata;
    end
end
endmodule

