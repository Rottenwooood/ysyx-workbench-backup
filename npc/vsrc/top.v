module top(
    input clk,reset,
    output [6:0] reg0,
    output [6:0] reg1,
    output [6:0] reg2,
    output [6:0] reg3
);
reg [7:0] pc_val;
wire [7:0] inst;
wire [1:0] r_addr0;
wire [1:0] r_addr1;
wire [7:0] r_data0;
wire [7:0] r_data1;
wire [7:0] w_data;
wire [1:0] w_addr;
wire ben,wen,ren;
wire [7:0] b_addr;
wire reg_en;
wire [7:0] sum;
wire [7:0] equal;


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
    .en (1'b1),
    .out (reg2)
);
hex7seg my_seg3(
    .in (pc_val[7:4]),
    .en (1'b1),
    .out (reg3)
);

IFU my_ifu(
    .pc_val (pc_val),
    .inst (inst)
);

IDU my_idu(
    .inst (inst),
    .r_addr0 (r_addr0),
    .r_addr1 (r_addr1),
    .w_data (w_data),
    .w_addr (w_addr),
    .ben (ben),
    .wen (wen),
    .ren (ren),
    .b_addr (b_addr),
    .reg_en (reg_en)
);

EXU my_exu(
    .r_addr0 (r_addr0),
    .r_addr1 (r_addr1),
    .sum (sum),
    .equal (equal)
);

LSU my_lsu(
    .clk (clk),
    .reset (reset),
    .wen (wen),
    .ren (ren),
    .ben (ben),
    .b_addr (b_addr),
    .r_addr0 (r_addr0),
    .r_addr1 (r_addr1),
    .w_addr (w_addr),
    .w_data (w_data),
    .r_data0 (r_data0),
    .r_data1 (r_data1),
    .pc_val (pc_val)
);
endmodule

module IFU(
    input pc_val,
    output [7:0] inst
);

rom #(8,8) my_rom(
    .addr (pc_val),
    .en (1'b1),
    .data (inst)
);

endmodule

module IDU(
    input inst,
    output [1:0] r_addr0;
    output [1:0] r_addr1;
    output [7:0] w_data;
    output [1:0] w_addr;
    output ben,wen,ren;
    output [7:0] b_addr;
    output reg_en;
);

assign r_addr0 = (inst[7:6] == 2'b11) ? 2'b0 : inst[3:2];
assign r_addr1 = inst[1:0];
assign w_data  = inst[7] ? 8'(inst[3:0]) : sum;
assign w_addr  = inst[5:4];
assign ben     = ~equal[0] && inst[7:6] == 2'b11;
assign wen = ~inst[6];
assign ren = inst[7:6] != 2'b10;
assign b_addr  = 8'(inst[5:2]);
assign reg_en  = inst[7:6] == 2'b01;

endmodule

module EXU(
    input [1:0] r_addr0;
    input [1:0] r_addr1;
    output [7:0] sum;
    output [7:0] equal;
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

endmodule

module LSU(
    input clk.wen,ren,ben,b_addr,reset
    input [1:0] r_addr0,
    input [1:0] r_addr1,
    input [1:0] w_addr,
    input [7:0] w_data,
    output [7:0] r_data0,
    output [7:0] r_data1,
    output pc_val
);

ram #(2,8) gpr(
    .clk (clk),
    .r_addr0 (r_addr0),
    .r_addr1 (r_addr1),
    .w_addr (w_addr),
    .w_data (w_data),
    .wen (wen),
    .ren (ren),
    .reset (reset),
    .r_data0 (r_data0),
    .r_data1 (r_data1)
);

pc #(8) my_pc(
    .clk (clk),
    .reset (reset),
    .ben (ben),
    .b_addr (b_addr),
    .out (pc_val)
);

endmodule