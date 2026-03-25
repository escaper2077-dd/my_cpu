module regfile(
    //其他信号
);

//----------通过DPI-C机制将寄存器文件regfile传递给测试框架----------------
//代码已经写好固定，把它加到你的代码里即可。

reg [31:0] regfile[31:0];
import "DPI-C" function void dpi_read_regfile(input logic [31 : 0] a []);
initial begin
    dpi_read_regfile(regfile);
end

endmodule