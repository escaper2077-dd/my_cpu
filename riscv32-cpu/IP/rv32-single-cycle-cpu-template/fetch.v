module fetch(
    //其他信号
);

//通过DPI-C机制取指，固定取指4bit
import "DPI-C" function int  dpi_instr_mem_read   (input int addr);

assign instr = dpi_mem_read(pc);
endmodule