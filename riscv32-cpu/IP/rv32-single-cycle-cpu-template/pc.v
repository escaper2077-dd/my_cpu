

module pc(

);
always @(posedge clk) begin
    if(rst) begin
        pc <= 32'h80000000; //pc复位值为32'h8000_0000
    end
    else begin
        pc <= xxxx;
    end
end


endmodule