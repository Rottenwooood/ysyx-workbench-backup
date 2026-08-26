module rom #(parameter WIDTH = 8,parameter DATA_WIDTH = 8)(
  input clk,
  input [WIDTH-1:0] addr,
  input en,
  output reg [DATA_WIDTH-1:0] data
);
  reg [DATA_WIDTH-1:0] mem [0:(1<<WIDTH)-1];
  integer i;
  initial begin
    for (i = 0; i < (1<<WIDTH); i = i + 1) mem[i] = {DATA_WIDTH{1'b0}};
    // 放置ROM的数据
    mem[8'h00] = 8'h8A; // 1000 1010 li r0 10
    mem[8'h01] = 8'h91; // 1001 0001 li r1 1
    mem[8'h02] = 8'hA1; // 1010 0001 li r2 1
    mem[8'h03] = 8'hB1; // 1011 0001 li r3 1
    mem[8'h04] = 8'h2B; // 0010 1011 add r2 r2 r3
    mem[8'h05] = 8'h16; // 0001 0110 add r1 r1 r2
    mem[8'h06] = 8'hD2; // 1101 0010 bner0 r2 04
    mem[8'h07] = 8'h41; // 0100 0001 out r1
  end
  always @(posedge clk) 
    if(en)
      data <= mem[addr];
    else
      data <= {DATA_WIDTH{1'b0}};
endmodule
