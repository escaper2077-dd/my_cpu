
 extern int dpi_instr_mem_read(/* INPUT */int addr);

 extern void dpi_read_regfile(const /* INPUT */svOpenArrayHandle a);

 extern void dpi_read_csrfile(const /* INPUT */svOpenArrayHandle a);

 extern int dpi_mem_read(/* INPUT */int addr, /* INPUT */int len, /* INPUT */unsigned long long pc);

 extern void dpi_mem_write(/* INPUT */int addr, /* INPUT */int data, /* INPUT */int len, /* INPUT */unsigned long long pc);
