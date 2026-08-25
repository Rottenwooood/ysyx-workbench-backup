// 桶形移位器
// 经典级联多路复用器结构: 共 $clog2(WIDTH) 级, 第 k 级根据 shamt 的对应位
// 决定是否移位 2^k 位, 可在单个周期内完成任意位数的移位/循环
// op: 000 逻辑左移(LSL), 001 逻辑右移(LSR), 010 算术右移(ASR),
//     011 循环左移(ROL), 100 循环右移(ROR), 其余 op 视为直通
module barrel_shifter #(
  parameter WIDTH = 32
)(
  input [WIDTH-1:0] in,
  input [$clog2(WIDTH)-1:0] shamt,
  input [2:0] op,
  output [WIDTH-1:0] out
);

  localparam NUM_STAGE = $clog2(WIDTH);

  wire [WIDTH-1:0] stage [NUM_STAGE:0];
  assign stage[0] = in;

  genvar k;
  generate
    for (k = 0; k < NUM_STAGE; k = k + 1) begin : shift_stage
      localparam SHIFT = 1 << k;
      wire [WIDTH-1:0] shifted;
      MuxKeyWithDefault #(5, 3, WIDTH) i_shift (
        shifted, op, stage[k], {
          3'b000, {stage[k][WIDTH-1-SHIFT:0], {SHIFT{1'b0}}},                  // LSL
          3'b001, {{SHIFT{1'b0}}, stage[k][WIDTH-1:SHIFT]},                    // LSR
          3'b010, {{SHIFT{stage[k][WIDTH-1]}}, stage[k][WIDTH-1:SHIFT]},       // ASR
          3'b011, {stage[k][WIDTH-1-SHIFT:0], stage[k][WIDTH-1:WIDTH-SHIFT]},  // ROL
          3'b100, {stage[k][SHIFT-1:0], stage[k][WIDTH-1:SHIFT]}               // ROR
        }
      );
      assign stage[k+1] = shamt[k] ? shifted : stage[k];
    end
  endgenerate

  assign out = stage[NUM_STAGE];
endmodule
