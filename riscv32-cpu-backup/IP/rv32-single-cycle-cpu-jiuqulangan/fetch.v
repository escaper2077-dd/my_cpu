module fetch(
       input   [31:0]  pc_i,
       output  [31:0]  inst_o
);

import "DPI-C" function int  dpi_instr_mem_read (input int addr, input int len);
assign inst_o = dpi_mem_read(pc_i, 4);
endmodule
