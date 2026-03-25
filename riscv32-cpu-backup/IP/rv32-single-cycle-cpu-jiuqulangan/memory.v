
module memory(
	   input         clk,	   
	   input [7:0]   load_store_info_i,
	   
	   //from execute alu 
	   input [31:0]   mem_addr_i,	   	   
	   input [31:0]   mem_write_data_i,
	  	   
	   // read data from memory to writeback stage
	   output[31:0]   mem_read_data_o  
);

import "DPI-C" function void dpi_mem_write(input int addr, input int data, int len);
import "DPI-C" function int  dpi_mem_read (input int addr, input int len);

reg[31:0] mem_data_o;

wire [31:0] addr = mem_addr_i;
wire [31:0] data = mem_write_data_i;


wire load_byte         = load_store_info_i[7];
wire load_half_word    = load_store_info_i[6];
wire load_word         = load_store_info_i[5];
wire load_byte_u       = load_store_info_i[4];
wire load_half_word_u  = load_store_info_i[3];

wire store_byte        = load_store_info_i[2];
wire store_half_word   = load_store_info_i[1];
wire store_word        = load_store_info_i[0];

wire [31:0] ram_read_data;
wire [31:0] ram_addr;
wire [ 7:0] ram_byte_en;
wire [31:0] ram_write_data;


wire   ram_read_en =   (load_byte        | 
                        load_half_word   |
			load_word        |
			load_byte_u      |
			load_half_word_u 
			);

wire[31:0] load_byte_data        = {{24{mem_data_o[ 7]}}, mem_data_o[ 7:0]};
wire[31:0] load_half_word_data   = {{16{mem_data_o[15]}}, mem_data_o[15:0]};
wire[31:0] load_word_data        = mem_data_o;
wire[31:0] load_byte_data_u      = {{24'b0},  mem_data_o[ 7:0]};
wire[31:0] load_half_word_data_u = {{16'b0},  mem_data_o[15:0]};


assign mem_read_data_o = (load_byte)             ? load_byte_data        :
                         (load_half_word)        ? load_half_word_data   :
			 (load_word)             ? load_word_data        :
			 (load_byte_u)           ? load_byte_data_u      :
			 (load_half_word_u)      ? load_half_word_data_u : mem_data_o;

always @(*) begin
    if(ram_read_en) begin
	mem_data_o = dpi_mem_read(addr, 4);
    end
    else begin
	mem_data_o = 32'b0;
    end
end
always @(posedge clk) begin
    if(store_byte) begin
	dpi_mem_write(addr, data, 1);
    end
    else if(store_half_word) begin
	dpi_mem_write(addr, data, 2);
    end
    else if(store_word) begin
	dpi_mem_write(addr, data, 4);
    end
end
endmodule
					
					
