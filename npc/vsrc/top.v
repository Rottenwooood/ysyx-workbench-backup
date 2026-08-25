module top(
  input clk,
  input reset,
  output [14:0] led
);
  wire [2:0] mode;
  reg [7:0] y;
  MuxKeyWithDefault #(2, 1, 3) i0 (mode, reset, 3'b101, {
    1'b0, 3'b101, //x,y[7:1]
    1'b1, 3'b001  //reset
  });
  shift_reg #(8,1) sr(
    .x (y[4]^y[3]^y[2]^y[0]),
    .clk (clk),
    .mode (mode),
    .y (y)
  );
  hex7seg led1(
    .b (y[7:4]),
    .h (led[13:7])
  );
  hex7seg led2(
    .b (y[3:0]),
    .h (led[6:0])
  );
endmodule
