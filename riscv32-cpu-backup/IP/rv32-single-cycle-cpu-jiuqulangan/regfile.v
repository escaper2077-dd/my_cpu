module regfile(
	input            clk,
	input            rst,	
	//from decode
	input   [ 4:0]   rs1_id_i,
	input   [ 4:0]   rs2_id_i,
	
	output  [31:0]   rs1_rdata_o,
	output  [31:0]   rs2_rdata_o,

	//write 
	input            w_en,        //write enable
	input   [ 4:0]   rd_id_i,
	input   [31:0]   rd_write_data_i
	
	//for moniter regfile status 

);

reg [31:0] rf[31:0];

assign rs1_rdata_o = (rs1_id_i == 5'b0) ? 32'b0 : rf[rs1_id_i];
assign rs2_rdata_o = (rs2_id_i == 5'b0) ? 32'b0 : rf[rs2_id_i];


import "DPI-C" function void dpi_read_regfile(input logic [31 : 0] a []);
initial begin
	dpi_read_regfile(rf);
end


always @(posedge clk) begin
    if(rst) begin
        rf[0] <= 32'h0;
    end
    else if(w_en && rd_id_i != 0) begin
	rf[rd_id_i] <= rd_write_data_i;
    end
end   



endmodule
