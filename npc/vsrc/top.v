module top(
  input clk,
  input rst,
  output reg[15:0] LED
);
always@(posedge clk)begin
	if(rst || LED == 16'b1 << 15)
		LED <= 16'b1;
	else
		LED <= LED << 1;
end
endmodule
