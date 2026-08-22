module top(x,en,y);
  input  [7:0] x;
  input  en;
  output reg [6:0]h;
  output flag;
  reg [2:0]y;
  decoder83 u_dec83(
	  .x (x),
	  .en (en),
	  .y (y)
  );
  bcd7seg u_seg(
  	.b (y),
	  .h (h)
  );
  
endmodule
