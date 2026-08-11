module top(
  input clk,
  input rst,
  output reg[15:0] ledr
);
reg [3:0] cnt;
always@(posedge clk)begin
	if(rst)begin
		cnt <= 0;
		ledr <= 16'b1;
	end
	else begin
		cnt <= cnt + 1;
		if(cnt == 4'b1111)begin
			if(ledr == 16'b1 << 15)
				ledr <= 16'b1;
			else if(ledr == 0)
				ledr <= 16'b1;
			else
				ledr <= ledr << 1;
		end
	end
end
endmodule
