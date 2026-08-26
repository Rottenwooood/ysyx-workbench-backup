module ram #(parameter WIDTH = 8,parameter DATA_WIDTH = 8)(
  input clk,
  input [WIDTH-1:0] r_addr0,
  input [WIDTH-1:0] r_addr1,
  input [WIDTH-1:0] w_addr,
  input [DATA_WIDTH-1:0] w_data,
  input wen,
  input ren,
  input reset,
  output reg [DATA_WIDTH-1:0] r_data0,
  output reg [DATA_WIDTH-1:0] r_data1
);
  reg [DATA_WIDTH-1:0] mem [0:(1<<WIDTH)-1];
  integer i;
  initial begin
    for (i = 0; i < (1<<WIDTH); i = i + 1) mem[i] = {DATA_WIDTH{1'b0}};
  end
  always @(posedge clk) begin
    if(reset)
      for (i = 0; i < (1<<WIDTH); i = i + 1) mem[i] = {DATA_WIDTH{1'b0}};
    else if(wen)
      mem[w_addr] <= w_data;
    else if(ren) begin
      r_data0 <= mem[r_addr0];
      r_data1 <= mem[r_addr1];
    end
  end
endmodule
