
module clk-rst(

)



//clk的处理， 只捕捉时钟上升沿的信号
always @(posedge clk) begin

end

//rst的处理，rst在高电平时进行复位
always @(posedge clk) begin
    if(rst) begin        //高电平时进行复位
        regfile[0] <= 32'h0
    end 
    else begin
        //other code
    end
end

endmodule