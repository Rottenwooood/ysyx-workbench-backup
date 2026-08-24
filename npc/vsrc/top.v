module top(
  input [3:0] A,
  input [3:0] B,
  input [2:0] flag,
  output carry,
  output zero,
  output overflow,
  output [6:0] led
);
    wire [3:0] result;
    alu4 alu(
      .A (A),
      .B (B),
      .flag (flag),
      .carry (carry),
      .zero (zero),
      .overflow (overflow),
      .result (result)
    );
    bcd7seg u_seg(
      .b (result),
      .h (led)
    );
endmodule
