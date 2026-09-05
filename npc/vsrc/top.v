`timescale 1ns / 1ps
`ifndef SYNTHESIS
import "DPI-C" function void sim_finish();
import "DPI-C" function int pmem_read(input int ram_raddr);
import "DPI-C" function void pmem_write(input int ram_waddr, input int ram_wdata, input byte ram_wmask);
`endif

/* 仿真顶层: 例化CPU + 存储/外设应答模型 */
module top(
    input clk,reset,
    output commit,
    output [6:0] reg0,
    output [6:0] reg1,
    output [6:0] reg2,
    output [6:0] reg3,
    output [31:0] pc_val
);
wire io_ifu_reqValid;
wire [31:0] io_ifu_addr;
wire io_ifu_respValid;
wire [31:0] io_ifu_rdata;
wire io_lsu_reqValid;
wire [31:0] io_lsu_addr;
wire [1:0] io_lsu_size;
wire io_lsu_wen;
wire [31:0] io_lsu_wdata;
wire [3:0] io_lsu_wmask;
wire io_lsu_respValid;
wire [31:0] io_lsu_rdata;

ysyx_100022825 #(.PC_RESET(32'h80000000)) cpu(
    .clock (clk),
    .reset (reset),
    .io_ifu_reqValid (io_ifu_reqValid),
    .io_ifu_addr (io_ifu_addr),
    .io_ifu_respValid (io_ifu_respValid),
    .io_ifu_rdata (io_ifu_rdata),
    .io_lsu_reqValid (io_lsu_reqValid),
    .io_lsu_addr (io_lsu_addr),
    .io_lsu_size (io_lsu_size),
    .io_lsu_wen (io_lsu_wen),
    .io_lsu_wdata (io_lsu_wdata),
    .io_lsu_wmask (io_lsu_wmask),
    .io_lsu_respValid (io_lsu_respValid),
    .io_lsu_rdata (io_lsu_rdata),
    .commit (commit),
    .reg0 (reg0),
    .reg1 (reg1),
    .reg2 (reg2),
    .reg3 (reg3),
    .pc_val (pc_val)
);

`ifndef SYNTHESIS
/* IFU应答: 请求拍采样并保持, 应答延迟由LFSR决定 */
reg [15:0] lfsr_i;
reg [7:0] sr_i;
reg [31:0] ifu_rdata;
reg ifu_respValid;
always @(posedge clk) begin
  if (reset) begin
    ifu_rdata <= 32'b0;
    ifu_respValid <= 1'b0;
    lfsr_i <= 16'hACE1;
    sr_i <= 8'b0;
  end
  else begin
    lfsr_i <= {lfsr_i[14:0], lfsr_i[15]^lfsr_i[13]^lfsr_i[12]^lfsr_i[10]};
    sr_i <= io_ifu_reqValid ? (8'b1 << lfsr_i[2:0]) : {sr_i[6:0], 1'b0};
    ifu_respValid <= sr_i[7];
    if (io_ifu_reqValid)
      ifu_rdata <= pmem_read(io_ifu_addr);
  end
end

/* LSU应答: 请求首拍采样并保持, 应答延迟由LFSR决定 */
reg [15:0] lfsr_d;
reg [7:0] sr_d;
reg lsu_reqValid_d;
reg [31:0] lsu_rdata;
reg lsu_respValid;
wire lsu_req_start = io_lsu_reqValid && !lsu_reqValid_d;
always @(posedge clk) begin
  if (reset) begin
    lsu_rdata <= 32'b0;
    lsu_respValid <= 1'b0;
    lfsr_d <= 16'hBEEF;
    sr_d <= 8'b0;
    lsu_reqValid_d <= 1'b0;
  end
  else begin
    lsu_reqValid_d <= io_lsu_reqValid;
    lfsr_d <= {lfsr_d[14:0], lfsr_d[15]^lfsr_d[13]^lfsr_d[12]^lfsr_d[10]};
    sr_d <= lsu_req_start ? (8'b1 << lfsr_d[2:0]) : {sr_d[6:0], 1'b0};
    lsu_respValid <= sr_d[7];
    if (lsu_req_start && io_lsu_wen) //写请求且第一拍
      pmem_write(io_lsu_addr, io_lsu_wdata, {4'b0, io_lsu_wmask});
    else if (lsu_req_start) //读请求且第一拍
      lsu_rdata <= pmem_read(io_lsu_addr);
  end
end

assign io_ifu_respValid = ifu_respValid;
assign io_ifu_rdata = ifu_rdata;
assign io_lsu_respValid = lsu_respValid;
assign io_lsu_rdata = lsu_rdata;
`endif

endmodule

/* CPU顶层, 接口与ysyxSoC/ready-to-run/minirv/cpu-interface.md一致 */
module ysyx_100022825 #(parameter PC_RESET = 32'h30000000)(
    input clock,
    input reset,
    output io_ifu_reqValid,
    output [31:0] io_ifu_addr,
    input io_ifu_respValid,
    input [31:0] io_ifu_rdata,
    output io_lsu_reqValid,
    output [31:0] io_lsu_addr,
    output [1:0] io_lsu_size,
    output io_lsu_wen,
    output [31:0] io_lsu_wdata,
    output [3:0] io_lsu_wmask,
    input io_lsu_respValid,
    input [31:0] io_lsu_rdata,
    output commit,
    output [6:0] reg0,
    output [6:0] reg1,
    output [6:0] reg2,
    output [6:0] reg3,
    output [31:0] pc_val
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
wire [31:0] load_data;
wire [31:0] imm_i;
wire [31:0] imm_s;
wire [31:0] imm_u;
wire [6:0] opcode;
wire [2:0] func3;
wire [31:0] ifu_inst;
wire is_load;
wire ifu_valid;
wire pc_en;
wire rf_wen;
wire is_store;
assign is_load = opcode == 7'h03;
assign is_store = opcode == 7'h23;
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
always @(posedge clock) begin
  if (!reset && commit && ifu_inst == 32'h00100073)
    sim_finish();
end
`endif

CTRL my_ctrl(
    .clk (clock),
    .reset (reset),
    .is_load (is_load),
    .is_store (is_store),
    .wen (wen),
    .io_ifu_reqValid (io_ifu_reqValid),
    .io_ifu_respValid (io_ifu_respValid),
    .io_lsu_reqValid (io_lsu_reqValid),
    .io_lsu_respValid (io_lsu_respValid),
    .ifu_valid (ifu_valid),
    .pc_en (pc_en),
    .rf_wen (rf_wen),
    .commit (commit)
);

IFU #(.PC_RESET(PC_RESET)) my_ifu(
    .clk (clock),
    .reset (reset),
    .pc_en (pc_en),
    .ben (ben),
    .b_addr (b_addr),
    .ifu_valid (ifu_valid),
    .ifu_rdata (io_ifu_rdata),
    .io_ifu_addr (io_ifu_addr),
    .pc_val (pc_val),
    .inst (ifu_inst)
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
    .load_data (load_data),
    .r_data1 (r_data1),
    .rs1 (rs1),
    .rs2 (rs2),
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
    .sum (sum),
    .r_data1 (r_data1),
    .func3 (func3),
    .opcode (opcode),
    .lsu_rdata (io_lsu_rdata),
    .lsu_addr (io_lsu_addr),
    .lsu_size (io_lsu_size),
    .lsu_wdata (io_lsu_wdata),
    .lsu_wmask (io_lsu_wmask),
    .lsu_wen (io_lsu_wen),
    .load_data (load_data)
);

WBU my_wbu(
    .clk (clock),
    .reset (reset),
    .wen (rf_wen),
    .ren (ren),
    .rs1 (rs1),
    .rs2 (rs2),
    .w_addr (w_addr),
    .sum (sum),
    .imm_u (imm_u),
    .load_data (load_data),
    .opcode (opcode),
    .pc_val (pc_val),
    .w_data (w_data),
    .r_data0 (r_data0),
    .r_data1 (r_data1)
);
endmodule

/*
负责状态机转移
*/
module CTRL(
    input clk,
    input reset,
    input is_load,
    input is_store,
    input wen,
    input io_ifu_respValid,
    input io_lsu_respValid,
    output io_ifu_reqValid,
    output io_lsu_reqValid,
    output ifu_valid,
    output pc_en,
    output rf_wen,
    output commit
);
localparam IDLE = 2'd0, WAIT = 2'd1, MEM = 2'd2;
reg [1:0] state,next_state;
always@(*) begin
    case(state)
        IDLE: next_state = WAIT;
        WAIT: next_state = io_ifu_respValid ? ((is_load || is_store) ? MEM : IDLE) : WAIT;
        MEM:  next_state = io_lsu_respValid ? IDLE : MEM;
        default: next_state = IDLE;
    endcase
end
always@(posedge clk) begin
    if(reset)
        state <= IDLE;
    else
        state <= next_state;
end
assign io_ifu_reqValid = (state == IDLE);
assign io_lsu_reqValid = (state == MEM);
assign ifu_valid = io_ifu_respValid;
assign commit = (state == WAIT && !(is_load || is_store) && io_ifu_respValid) || (state == MEM && io_lsu_respValid);
assign pc_en = commit;
assign rf_wen = commit && wen;

endmodule

/*
取指单元
维护pc
输入读取到的inst内容
输出pc_val inst
*/
module IFU #(parameter PC_RESET = 32'h30000000)(
    input clk,
    input reset,
    input pc_en,
    input ben,
    input [31:0] b_addr,
    input ifu_valid,
    input [31:0] ifu_rdata,
    output [31:0] io_ifu_addr,
    output [31:0] pc_val,
    output [31:0] inst
);
reg [31:0] inst_reg;
always @(posedge clk) begin
  if (reset)
    inst_reg <= 32'b0;
  else if (ifu_valid)
    inst_reg <= ifu_rdata;
end
assign inst = ifu_valid ? ifu_rdata : inst_reg;

wire [31:0] pc_b_addr;
wire pc_ben;
assign pc_ben    = pc_en ? ben   : 1'b1;
assign pc_b_addr = pc_en ? b_addr : pc_val;
assign io_ifu_addr = pc_val;

pc #(32,4,PC_RESET) my_pc(
    .clk (clk),
    .reset (reset),
    .ben (pc_ben),
    .b_addr (pc_b_addr),
    .out (pc_val)
);
endmodule

/*
组合逻辑
负责连线，译码，
*/
module IDU(
    input [31:0] inst,sum,equal,pc_val,
    input [31:0] load_data,
    input [31:0] r_data1,
    output [31:0] imm_i,imm_s,imm_u,
    output [6:0] opcode,
    output [2:0] func3,
    output [4:0] rs1,
    output [4:0] rs2,
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
assign w_addr  = inst[11:7];
assign ben = opcode == 7'h67 && func3 == 3'b0;
assign wen = opcode == 7'h13 || opcode == 7'h67 || opcode == 7'h33 || opcode == 7'h37 || opcode == 7'h03;
assign ren = opcode == 7'h13 || opcode == 7'h67 || opcode == 7'h33 || opcode == 7'h03 || opcode == 7'h23;
assign b_addr  = sum & ~1;
assign reg_en  = 1'b1;

endmodule

/*
执行单元
输出运算结果与跳转flag
*/
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
    input [31:0] sum,
    input [31:0] r_data1,
    input [2:0] func3,
    input [6:0] opcode,
    input [31:0] lsu_rdata,
    output [31:0] lsu_addr,
    output [1:0] lsu_size,
    output [31:0] lsu_wdata,
    output [3:0] lsu_wmask,
    output lsu_wen,
    output [31:0] load_data
);
assign lsu_addr = sum;
assign lsu_wdata = (func3 == 3'b000) ? ((r_data1 & 32'hFF) << (8 * sum[1:0])) : r_data1;
assign lsu_size = (func3 == 3'b000) ? 2'b00 :
                  (func3 == 3'b001) ? 2'b01 :
                  2'b10;

wire [3:0] lsu_wmask_raw;
MuxKeyWithDefault #(3, 3, 4) i0 (lsu_wmask_raw, func3, 4'h0, {
    3'h0, 4'h1,
    3'h2, 4'hF,
    3'h4, 4'h1
});
assign lsu_wmask = (func3 == 3'b000) ? (lsu_wmask_raw << sum[1:0]) : lsu_wmask_raw;
assign load_data = (func3 == 3'b010) ? lsu_rdata :
                   (func3 == 3'b100) ? {24'b0, lsu_rdata[sum[1:0]*8 +: 8]} :
                   32'b0;
assign lsu_wen = opcode == 7'h23;

endmodule

/*
写入单元
将数据写入寄存器
*/
module WBU(
    input clk,wen,ren,reset,
    input [31:0] pc_val,
    input [4:0] rs1,
    input [4:0] rs2,
    input [4:0] w_addr,
    input [31:0] sum,
    input [31:0] imm_u,
    input [31:0] load_data,
    input [6:0] opcode,
    output [31:0] r_data0,
    output [31:0] r_data1,
    output [31:0] w_data
);

MuxKeyWithDefault #(5, 7, 32) i0 (w_data, opcode, sum, {
    7'h13, sum,
    7'h67, pc_val + 4,
    7'h33, sum,
    7'h37, imm_u,
    7'h03, load_data
});

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

endmodule
