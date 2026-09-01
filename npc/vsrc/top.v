// ============ 处理器模块(综合顶层): 不含存储器与不可综合代码 ============
module NPC(
    input clk,reset,
    // 指令访存接口
    output [31:0] inst_req_addr,   // 取指地址(PC)
    input  [31:0] inst,            // 指令
    // 数据访存接口
    output [31:0] dmem_raddr,
    output [31:0] dmem_waddr,
    output [31:0] dmem_wdata,
    output [7:0]  dmem_wmask,
    output        dmem_en,
    output        dmem_wen,
    input  [31:0] dmem_rdata,
    // 供外部观测(显示用)
    output [31:0] pc_val,
    output [31:0] r_data1,
    output        reg_en,
    // ebreak 检测信号(顶层在仿真时调用 sim_finish)
    output        ebreak
);
reg [31:0] pc_val_r;
wire [4:0] rs1;
wire [4:0] rs2;
wire [31:0] r_data0;
wire [31:0] r_data1_r;
wire [31:0] w_data;
wire [4:0] w_addr;
wire ben,wen,ren;
wire [31:0] b_addr;
wire [31:0] sum;
wire [31:0] equal;
wire [31:0] imm_i;
wire [31:0] imm_s;
wire [31:0] imm_u;
wire [6:0] opcode;
wire [2:0] func3;
wire ram_en,ram_wen;
wire [31:0] ram_raddr,ram_waddr,ram_wdata,ram_rdata;
wire [7:0] ram_wmask;

assign pc_val = pc_val_r;
assign r_data1 = r_data1_r;

// 数据访存接口: NPC 内部访存信号 <-> 顶层访存总线
assign dmem_raddr = ram_raddr;
assign dmem_waddr = ram_waddr;
assign dmem_wdata = ram_wdata;
assign dmem_wmask = ram_wmask;
assign dmem_en    = ram_en;
assign dmem_wen   = ram_wen;
assign ram_rdata  = dmem_rdata;

// 指令访存接口: 取指地址
assign inst_req_addr = pc_val_r;

// ebreak 检测(纯组合, 可综合; 顶层在仿真时据此调用 sim_finish)
assign ebreak = (inst == 32'h00100073);

IDU my_idu(
    .inst (inst),
    .sum (sum),
    .equal (equal),
    .imm_i (imm_i),
    .imm_s (imm_s),
    .imm_u (imm_u),
    .pc_val (pc_val_r),
    .opcode (opcode),
    .func3 (func3),
    .ram_rdata (ram_rdata),
    .r_data1 (r_data1_r),
    .ram_raddr (ram_raddr),
    .ram_waddr (ram_waddr),
    .ram_wdata (ram_wdata),
    .ram_wmask (ram_wmask),
    .ram_en (ram_en),
    .ram_wen (ram_wen),
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
    .r_data1 (r_data1_r),
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
    .r_data1 (r_data1_r),
    .pc_val (pc_val_r)
);
endmodule

// ============ 仿真顶层: NPC + 外部存储器(访存通过 DPI-C) ============
`ifndef SYNTHESIS
import "DPI-C" function void sim_finish();
import "DPI-C" function int pmem_read(input int ram_raddr);
import "DPI-C" function void pmem_write(input int ram_waddr, input int ram_wdata, input byte ram_wmask);
`endif

module top(
    input clk,reset,
    output [6:0] reg0,
    output [6:0] reg1,
    output [6:0] reg2,
    output [6:0] reg3
);
wire [31:0] inst_req_addr;
wire [31:0] inst;
wire [31:0] dmem_raddr,dmem_waddr,dmem_wdata,dmem_rdata;
wire [7:0] dmem_wmask;
wire dmem_en,dmem_wen;
wire [31:0] pc_val,r_data1;
wire reg_en,ebreak;

NPC npc(
    .clk (clk),
    .reset (reset),
    .inst_req_addr (inst_req_addr),
    .inst (inst),
    .dmem_raddr (dmem_raddr),
    .dmem_waddr (dmem_waddr),
    .dmem_wdata (dmem_wdata),
    .dmem_wmask (dmem_wmask),
    .dmem_en (dmem_en),
    .dmem_wen (dmem_wen),
    .dmem_rdata (dmem_rdata),
    .pc_val (pc_val),
    .r_data1 (r_data1),
    .reg_en (reg_en),
    .ebreak (ebreak)
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
    .en (1'b1),
    .out (reg2)
);
hex7seg my_seg3(
    .in (pc_val[7:4]),
    .en (1'b1),
    .out (reg3)
);

`ifndef SYNTHESIS
// ---- 存储器(仅仿真): 通过 DPI-C 访问 C++ 侧内存, 综合时在芯片外部 ----
reg [31:0] ram_rdata_r;
always @(*) begin
  if (dmem_en) begin // 有读写请求时
    ram_rdata_r = pmem_read(dmem_raddr);
    if (dmem_wen) begin // 有写请求时
      pmem_write(dmem_waddr, dmem_wdata, dmem_wmask);
    end
  end
  else begin
    ram_rdata_r = 0;
  end
end
assign dmem_rdata = ram_rdata_r;

// 取指: 按 PC 从存储器读指令
assign inst = pmem_read(inst_req_addr);

// 程序执行到 ebreak 时通知仿真环境结束
always @(posedge clk) begin
  if (!reset && ebreak)
    sim_finish();
end
`else
// ---- 综合: 存储器在芯片外部, NPC 为综合顶层 ----
assign dmem_rdata = 32'b0;
assign inst = 32'b0;
`endif

endmodule

module IDU(
    input [31:0] inst,sum,equal,pc_val,
    input [31:0] ram_rdata,
    input [31:0] r_data1,
    output [31:0] imm_i,imm_s,imm_u,
    output [6:0] opcode,
    output [2:0] func3,
    output [31:0] ram_raddr,
    output [31:0] ram_waddr,
    output [31:0] ram_wdata,
    output [7:0] ram_wmask,
    output ram_en,
    output ram_wen,
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
assign ram_raddr = sum;
assign ram_waddr = sum;
// sw (func3=2): 整字; sb (func3=0): 存 rs2 最低字节, 但要挪到地址对应的字节位
assign ram_wdata = (func3 == 3'b000) ? ((r_data1 & 32'hFF) << (8 * sum[1:0])) : r_data1;

wire [7:0] ram_wmask_raw;
MuxKeyWithDefault #(3, 3, 8) i0 (ram_wmask_raw, func3, 8'h0, {
    3'h0, 8'h01,
    3'h2, 8'h0F,
    3'h4, 8'h01
});
// sb (func3=0): 写掩码按地址低 2 位偏移, 写到正确的字节
assign ram_wmask = (func3 == 3'b000) ? (ram_wmask_raw << sum[1:0]) : ram_wmask_raw;
wire [31:0] load_data;
assign load_data = (func3 == 3'b010) ? ram_rdata :                              // lw: 整字
                   (func3 == 3'b100) ? {24'b0, ram_rdata[sum[1:0]*8 +: 8]} :    // lbu: 取对应字节并零扩展
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
assign ram_en = opcode == 7'h23 || opcode == 7'h03;
assign ram_wen = opcode == 7'h23;
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

pc #(32,4,32'h80000000) my_pc(
    .clk (clk),
    .reset (reset),
    .ben (ben),
    .b_addr (b_addr),
    .out (pc_val)
);

endmodule
