module top(
  input clk, resetn, ps2_clk, ps2_data,
  output [6:0] led1,
  output [6:0] led2,
  output [6:0] led3,
  output [6:0] led4
);
reg [7:0] word_cnt;
reg [9:0] buffer;
ps2_keyboard my_keyborad(clk,resetn,ps2_clk,ps2_data,word_cnt,buffer);

hex7seg my_led1(
    .b (buffer[8:5]),
    .h (led1)
  );
hex7seg my_led2(
    .b (buffer[4:1]),
    .h (led2)
  );
hex7seg my_led3(
    .b (word_cnt[7:4]),
    .h (led3)
  );
hex7seg my_led4(
    .b (word_cnt[3:0]),
    .h (led4)
  );
endmodule