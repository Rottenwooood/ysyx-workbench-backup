module top(x,en,h,flag);
  input  [7:0] x;
  input  en;
  output reg [6:0]h;
  output flag;
  reg [2:0]y;
  decoder83 u_dec83(
	  .x (x),
	  .en (en),
	  .y (y),
    .f (flag)
  );
  wire [3:0]b = {1'b0,y};
  bcd7seg u_seg(
  	.b (b),
	  .h (h)
  );
  
endmodule
