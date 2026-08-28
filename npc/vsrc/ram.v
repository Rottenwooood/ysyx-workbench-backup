module ram #(parameter WIDTH = 8,parameter DATA_WIDTH = 8)(
  input clk,
  input [WIDTH-1:0] rs1,
  input [WIDTH-1:0] rs2,
  input [WIDTH-1:0] w_addr,
  input [DATA_WIDTH-1:0] w_data,
  input wen,
  input ren,
  input reset,
  output [DATA_WIDTH-1:0] r_data0,
  output [DATA_WIDTH-1:0] r_data1
);
  reg [DATA_WIDTH-1:0] mem [0:(1<<WIDTH)-1];
  integer i;
  always @(posedge clk) begin
    if(reset)
      for (i = 0; i < (1<<WIDTH); i = i + 1) mem[i] <= {DATA_WIDTH{1'b0}};
    else if(wen)
      mem[w_addr] <= w_data;
  end
  assign r_data0 = (ren && rs1) ? mem[rs1] : {DATA_WIDTH{1'b0}};
  assign r_data1 = (ren && rs2) ? mem[rs2] : {DATA_WIDTH{1'b0}};
endmodule
