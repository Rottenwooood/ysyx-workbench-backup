module top(
    input clk,reset,
    input [31:0] inst,
    output [6:0] reg0,
    output [6:0] reg1,
    output [6:0] reg2,
    output [6:0] reg3
);
reg [31:0] pc_val;
wire [4:0] rs1;
wire [4:0] rs2;
wire [31:0] r_data0;
wire [31:0] r_data1;
reg [31:0] w_data;
wire [4:0] w_addr;
wire ben,wen,ren;
wire [31:0] b_addr;
wire reg_en;
wire [31:0] sum;
wire [31:0] equal;
wire [31:0] imm_i;
wire [31:0] imm_s;
wire [31:0] imm_u;
wire [6:0] opcode;
wire [2:0] func3;
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

IDU my_idu(
    .inst (inst),
    .sum (sum),
    .equal (equal),
    .imm_i (imm_i),
    .imm_s (imm_s),
    .imm_u (imm_u),
    .pc_val (pc_val),
    .opcode (opcode),
    .func3 (func3),
    .rs1 (rs1),
    .rs2 (rs2),
    .w_data (w_data),
    .w_addr (w_addr),
    .ben (ben),
    .wen (wen),
    .ren (ren),
    .b_addr (b_addr),
    .reg_en (reg_en)
);

EXU my_exu(
    .r_data0 (r_data0),
    .r_data1 (r_data1),
    .imm_i (imm_i),
    .imm_s (imm_s),
    .opcode (opcode),
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
    .rs1 (rs1),
    .rs2 (rs2),
    .w_addr (w_addr),
    .w_data (w_data),
    .r_data0 (r_data0),
    .r_data1 (r_data1),
    .pc_val (pc_val)
);
endmodule

module IDU(
    input [31:0] inst,sum,equal,pc_val,
    output [31:0] imm_i,imm_s,imm_u,
    output [6:0] opcode,
    output [2:0] func3,
    output [4:0] rs1,
    output [4:0] rs2,
    output [31:0] w_data,
    output [4:0] w_addr,
    output ben,wen,ren,
    output [31:0] b_addr,
    output reg_en
);

assign imm_i = inst[31] ? {20'hFFFFF,inst[31:20]} : {20'h00000,inst[31:20]}; 
assign imm_s = inst[31] ? {20'hFFFFF,inst[31:25],inst[11:7]} : {20'h00000,inst[31:25],inst[11:7]}; 
assign imm_u = {inst[31:12],12'b000};
assign opcode = inst[6:0];
assign func3 = inst[14:12];

assign rs1 = inst[19:15];
assign rs2 = inst[24:20];
MuxKeyWithDefault #(5, 7, 32) i0 (w_data, opcode, sum, {
    7'h13, sum,
    7'h67, pc_val + 4,
    7'h33, sum,
    7'h37, imm_u,
    7'h03, imm_s
});

assign w_addr  = inst[11:7];

assign ben = opcode == 7'h67 && func3 == 3'b0;
assign wen = opcode == 7'h13 || opcode == 7'h67 || opcode == 7'h33 || opcode == 7'h37 || opcode == 7'h03;
assign ren = opcode == 7'h13 || opcode == 7'h67 || opcode == 7'h33 || opcode == 7'h03 || opcode == 7'h23;
assign b_addr  = sum & ~1;
assign reg_en  = 1'b1;

endmodule

module EXU(
    input [31:0] r_data0,
    input [31:0] r_data1,
    input [31:0] imm_i,
    input [31:0] imm_s,
    input [6:0] opcode,
    output [31:0] sum,
    output [31:0] equal
);
wire [31:0] r_data1_;
MuxKeyWithDefault #(5, 7, 32) i0 (r_data1_, opcode, 32'b0, {
    7'h13, imm_i,
    7'h67, imm_i,
    7'h33, r_data1,
    7'h03, imm_i,
    7'h23, imm_s
});
alu #(32) adder(
    .A (r_data0),
    .B (r_data1_),
    .flag (3'b000),
    .carry (),
    .zero (),
    .overflow (),
    .result (sum)
);

alu #(32) my_equal(
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
    input clk,wen,ren,ben,reset,
    input [31:0] b_addr,
    input [4:0] rs1,
    input [4:0] rs2,
    input [4:0] w_addr,
    input [31:0] w_data,
    output [31:0] r_data0,
    output [31:0] r_data1,
    output [31:0] pc_val
);

ram #(5,32) gpr(
    .clk (clk),
    .rs1 (rs1),
    .rs2 (rs2),
    .w_addr (w_addr),
    .w_data (w_data),
    .wen (wen),
    .ren (ren),
    .reset (reset),
    .r_data0 (r_data0),
    .r_data1 (r_data1)
);

pc #(32,4) my_pc(
    .clk (clk),
    .reset (reset),
    .ben (ben),
    .b_addr (b_addr),
    .out (pc_val)
);

endmodule