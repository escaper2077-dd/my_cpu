module csrfile(

);


//----------通过Verilator DPI-C机制将csrfile传递给测试框架----------------
//代码已经写好固定，把它加到你的代码里即可。
//只有你需要写csr指令的时候，才需要添加这部分代码，否则忽略即可。
reg [31:0] csrfile[4096];
import "DPI-C" function void dpi_read_csrfile(input logic [31 : 0] a []); 
initial begin
    integer i;
    for (i = 0; i < 4096; i = i + 1) begin
        csrfile[i] = 32'd0; 
    end
    dpi_read_csrfile(csrfile);
end

endmodule