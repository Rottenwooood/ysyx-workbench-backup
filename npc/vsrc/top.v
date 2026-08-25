module top(
  input clk, resetn, ps2_clk, ps2_data,
  output [6:0] led1,
  output [6:0] led2,
  output [6:0] led3,
  output [6:0] led4
);
reg [7:0] word_cnt;
reg [9:0] buffer;
wire [7:0] ascii;
ps2_keyboard my_keyborad(clk,resetn,ps2_clk,ps2_data,word_cnt,buffer);

ascii_rom my_rom(
    .clk  (clk),
    .addr (buffer[8:1]),
    .data (ascii)
  );
hex7seg my_led1(
    .b (buffer[8:5]),
    .h (led1)
  );
hex7seg my_led2(
    .b (buffer[4:1]),
    .h (led2)
  );
hex7seg my_led3(
    .b (ascii[7:4]),
    .h (led3)
  );
hex7seg my_led4(
    .b (ascii[3:0]),
    .h (led4)
  );
hex7seg my_led5(
    .b (word_cnt[7:4]),
    .h (led3)
  );
hex7seg my_led6(
    .b (word_cnt[3:0]),
    .h (led4)
  );
endmodule