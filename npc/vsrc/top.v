`ifndef SYNTHESIS
import "DPI-C" function void sim_finish();
import "DPI-C" function int pmem_read(input int ram_raddr);
import "DPI-C" function void pmem_write(input int ram_waddr, input int ram_wdata, input byte ram_wmask);
`endif

module top(
    input clk,reset,
    output commit,
    output [6:0] reg0,
    output [6:0] reg1,
    output [6:0] reg2,
    output [6:0] reg3
);
wire [31:0] pc_val;
wire [31:0] lsu_addr,lsu_wdata;
wire [7:0] lsu_wmask;
wire lsu_wen;
`ifndef SYNTHESIS
reg [31:0] lsu_rdata;
reg [31:0] inst;
`else
wire [31:0] lsu_rdata;
wire [31:0] inst;
`endif

NPC npc(
    .clk (clk),
    .reset (reset),
    .commit (commit),
    .inst (inst),
    .reg0 (reg0),
    .reg1 (reg1),
    .reg2 (reg2),
    .reg3 (reg3),
    .pc_val (pc_val),
    .lsu_addr (lsu_addr),
    .lsu_wdata (lsu_wdata),
    .lsu_wmask (lsu_wmask),
    .lsu_wen (lsu_wen),
    .lsu_rdata (lsu_rdata)
);

`ifndef SYNTHESIS
always @(posedge clk) begin
  if (reset)
    inst <= 32'b0;
  else
    inst <= pmem_read(pc_val);
end

always @(posedge clk) begin
  if (reset)
    lsu_rdata <= 32'b0;
  else begin
    lsu_rdata <= (!lsu_wen) ? pmem_read(lsu_addr) : 32'b0;
    if (lsu_wen) begin
      pmem_write(lsu_addr, lsu_wdata, lsu_wmask);
    end
  end
end
`endif
endmodule

module NPC(
    input clk,reset,
    input [31:0] inst,
    output commit,
    output [6:0] reg0,
    output [6:0] reg1,
    output [6:0] reg2,
    output [6:0] reg3,
    output [31:0] pc_val,
    output [31:0] lsu_addr,
    output [31:0] lsu_wdata,
    output [7:0] lsu_wmask,
    output lsu_wen,
    input [31:0] lsu_rdata
);
wire [4:0] rs1;
wire [4:0] rs2;
wire [31:0] r_data0;
wire [31:0] r_data1;
wire [4:0] w_addr;
wire [31:0] w_data;
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
wire [31:0] ifu_inst;
wire is_load;
wire reg_wen;
assign is_load = opcode == 7'h03;
assign reg_wen = wen & commit;
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

`ifndef SYNTHESIS
always @(posedge clk) begin
  if (!reset && commit && ifu_inst == 32'h00100073)
    sim_finish();
end
`endif

IFU my_ifu(
    .clk (clk),
    .reset (reset),
    .ifu_rdata (inst),
    .is_load (is_load),
    .inst (ifu_inst),
    .commit (commit)
);

IDU my_idu(
    .inst (ifu_inst),
    .sum (sum),
    .equal (equal),
    .imm_i (imm_i),
    .imm_s (imm_s),
    .imm_u (imm_u),
    .pc_val (pc_val),
    .opcode (opcode),
    .func3 (func3),
    .lsu_rdata (lsu_rdata),
    .r_data1 (r_data1),
    .lsu_addr (lsu_addr),
    .lsu_wdata (lsu_wdata),
    .lsu_wmask (lsu_wmask),
    .lsu_wen (lsu_wen),
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

WBU my_wbu(
    .clk (clk),
    .reset (reset),
    .pc_en (commit),
    .wen (reg_wen),
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
    input [31:0] lsu_rdata,
    input [31:0] r_data1,
    output [31:0] imm_i,imm_s,imm_u,
    output [6:0] opcode,
    output [2:0] func3,
    output [31:0] lsu_addr,
    output [31:0] lsu_wdata,
    output [7:0] lsu_wmask,
    output lsu_wen,
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
assign lsu_addr = sum;
// sw (func3=2): 整字; sb (func3=0): 存 rs2 最低字节, 但要挪到地址对应的字节位
assign lsu_wdata = (func3 == 3'b000) ? ((r_data1 & 32'hFF) << (8 * sum[1:0])) : r_data1;

wire [7:0] lsu_wmask_raw;
MuxKeyWithDefault #(3, 3, 8) i0 (lsu_wmask_raw, func3, 8'h0, {
    3'h0, 8'h01,
    3'h2, 8'h0F,
    3'h4, 8'h01
});
// sb (func3=0): 写掩码按地址低 2 位偏移, 写到正确的字节
assign lsu_wmask = (func3 == 3'b000) ? (lsu_wmask_raw << sum[1:0]) : lsu_wmask_raw;
wire [31:0] load_data;
assign load_data = (func3 == 3'b010) ? lsu_rdata :                              // lw: 整字
                   (func3 == 3'b100) ? {24'b0, lsu_rdata[sum[1:0]*8 +: 8]} :    // lbu: 取对应字节并零扩展
                   32'b0;
assign rs1 = inst[19:15];
assign rs2 = inst[24:20];
MuxKeyWithDefault #(5, 7, 32) i1 (w_data, opcode, sum, {
    7'h13, sum,
    7'h67, pc_val + 4,
    7'h33, sum,
    7'h37, imm_u,
    7'h03, load_data
});
assign w_addr  = inst[11:7];
assign lsu_wen = opcode == 7'h23;
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

module WBU(
    input clk,wen,ren,ben,reset,pc_en,
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

wire [31:0] pc_b_addr;
wire pc_ben;
assign pc_ben    = pc_en ? ben   : 1'b1;
assign pc_b_addr = pc_en ? b_addr : pc_val;

pc #(32,4,32'h80000000) my_pc(
    .clk (clk),
    .reset (reset),
    .ben (pc_ben),
    .b_addr (pc_b_addr),
    .out (pc_val)
);

endmodule

module IFU(
    input clk,
    input reset,
    input [31:0] ifu_rdata,
    input is_load,
    output [31:0] inst,
    output commit
);
parameter IDLE = 2'd0, WAIT = 2'd1, MEM = 2'd2;
reg [1:0] state,next_state;
always@(*) begin
    case(state)
        IDLE: next_state = WAIT;
        WAIT: next_state = is_load ? MEM : IDLE;
        MEM:  next_state = IDLE;
        default: next_state = IDLE;
    endcase
end
always@(posedge clk) begin
    if(reset)
        state <= IDLE;
    else
        state <= next_state;
end
wire exe = state == WAIT || state == MEM;
assign commit = (state == WAIT && !is_load) || (state == MEM);
assign inst = exe ? ifu_rdata : 32'b0;
endmodule
