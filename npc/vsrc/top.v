module top(
    input clk,reset,
    output [6:0] reg0,
    output [6:0] reg1,
    output [6:0] reg2,
    output [6:0] reg3
);
reg [7:0] pc_val;
reg [7:0] inst;
wire [1:0] r_addr0;
wire [1:0] r_addr1;
reg [7:0] r_data0;
reg [7:0] r_data1;
wire [7:0] w_data;
wire [1:0] w_addr;
wire [7:0] sum;
wire [7:0] equal;
wire ben;
wire [7:0] b_addr;
wire reg_en;


assign w_addr  = inst[5:4];
assign b_addr  = 8'(inst[5:2]);
assign r_addr1 = inst[1:0];
assign reg_en  = inst[7:6] == 2'b01;
assign ben     = ~equal[0] && inst[7:6] == 2'b11;
assign w_data  = inst[7] ? 8'(inst[3:0]) : sum;
assign r_addr0 = (inst[7:6] == 2'b11) ? 2'b0 : inst[3:2];

pc #(8) my_pc(
    .clk (clk),
    .reset (reset),
    .ben (ben),
    .b_addr (b_addr),
    .out (pc_val)
);

rom #(8,8) my_rom(
    .clk (clk),
    .addr (pc_val),
    .en (1'b1),
    .data (inst)
);

alu #(8) adder(
    .A (r_data0),
    .B (r_data1),
    .flag (3'b000),
    .carry (),
    .zero (),
    .overflow (),
    .result (sum)
);

alu #(8) my_equal(
    .A (r_data0),
    .B (r_data1),
    .flag (3'b111),
    .carry (),
    .zero (),
    .overflow (),
    .result (equal)
);

ram #(2,8) gpr(
    .clk (clk),
    .r_addr0 (r_addr0),
    .r_addr1 (r_addr1),
    .w_addr (w_addr),
    .w_data (w_data),
    .wen (~inst[6]),
    .ren (inst[7:6] != 2'b10),
    .reset (reset),
    .r_data0 (r_data0),
    .r_data1 (r_data1)
);

hex7seg my_seg0(
    .in (r_data1[3:0]),
    .en (reg_en),
    .out (reg0)
);
hex7seg my_seg1(
    .in (r_data1[7:4]),
    .en (reg_en),
    .out (reg1)
);
hex7seg my_seg2(
    .in (pc_val[3:0]),
    .en (reg_en),
    .out (reg2)
);
hex7seg my_seg3(
    .in (pc_val[7:4]),
    .en (reg_en),
    .out (reg3)
);
endmodule