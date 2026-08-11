module top(
  input clk,
  input rst,
  output reg[15:0] ledr
);
always@(posedge clk)begin
	if(rst || ledr == 16'b1 << 15)
		ledr <= 16'b1;
	else
		ledr <= ledr << 1;
end
endmodule
