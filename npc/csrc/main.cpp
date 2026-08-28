#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <Vtop.h>
#include <Vtop___024root.h>

static TOP_NAME dut;
uint8_t M[64];

static volatile bool sim_finish_flag = false;

extern "C" void sim_finish() {
  sim_finish_flag = true;
}
extern "C" int pmem_read(int ram_raddr) {
  uint32_t a = (uint32_t)ram_raddr & ~0x3u;
  if (a + 4 > sizeof(M)) return 0;
  return M[a] | M[a+1]<<8 | M[a+2]<<16 | M[a+3]<<24;
}
extern "C" void pmem_write(int ram_waddr, int ram_wdata, char ram_wmask) {
  uint32_t a = (uint32_t)ram_waddr & ~0x3u;
  for(int i = 0;i < 4;i++){
    if(a + i < sizeof(M) && ((1 << i) & (unsigned char)ram_wmask))
      M[a+i] = (ram_wdata >> (8*i)) & 0xFF; 
  }
}

static uint32_t inst_fetch(uint32_t pc) {
  return M[pc] | (M[pc+1]<<8) | (M[pc+2]<<16) | (M[pc+3]<<24);
}

void ref_inst_cycle();
void ref_load_mem(const uint8_t *img, int size);
uint32_t *ref_get_regs();
uint32_t ref_get_pc();

static void dut_single_cycle() {
  dut.clk = 0; dut.eval();
  dut.clk = 1; dut.eval();
}

static void reset(int n) {
  dut.reset = 1;
  while (n-- > 0) dut_single_cycle();
  dut.reset = 0;
}

static int check_regs(const uint32_t *dut_regs, const uint32_t *ref_regs) {
  int is_diff = 0;
  for (int i = 0; i < 4; i++) {
    if (dut_regs[i] != ref_regs[i]) {
      printf("reg%d: DUT=%u REF=%u\n", i, dut_regs[i], ref_regs[i]);
      is_diff = 1;
    }
  }
  return is_diff;
}

static int check_pc(const uint32_t dut_pc, const uint32_t ref_pc) {
  int is_diff = 0;
  if (dut_pc != ref_pc) {
    printf("pc: DUT=%u REF=%u\n", dut_pc, ref_pc);
    is_diff = 1;
  }
  return is_diff;
}

int main() {
  reset(10);
  //	PC=0x00: lui  x1, 0x12345   -> x1=0x12345000       (lui)
	//	PC=0x04: addi x2, x1, 0x678 -> x2=0x12345678       (addi)
	//	PC=0x08: addi x3, x0, 0x30  -> x3=0x30             (addi)
	//	PC=0x0c: sw   x2, 0(x3)     -> M[0x30]=0x12345678  (sw)
	//	PC=0x10: lw   x4, 0(x3)     -> x4=0x12345678       (lw)
	//	PC=0x14: sb   x2, 5(x3)     -> M[0x35]=0x78 (非对齐, 验证字节位置)  (sb)
	//	PC=0x18: lbu  x5, 5(x3)     -> x5=0x78                             (lbu)
	//	PC=0x1c: add  x6, x4, x2    -> x6=0x2468ACF0       (add)
	//	PC=0x20: jalr x7, x3, -12   -> x7=0x24, 跳到 0x24  (jalr)
	//	PC=0x24: ebreak
	static const uint8_t prog[] = {
		0xb7,0x50,0x34,0x12, // lui  x1, 0x12345
		0x13,0x81,0x80,0x67, // addi x2, x1, 0x678
		0x93,0x01,0x00,0x03, // addi x3, x0, 0x30
		0x23,0xa0,0x21,0x00, // sw   x2, 0(x3)
		0x03,0xa2,0x01,0x00, // lw   x4, 0(x3)
		0xa3,0x82,0x21,0x00, // sb   x2, 5(x3)   -> M[0x35]=0x78
		0x83,0xc2,0x51,0x00, // lbu  x5, 5(x3)   -> x5=0x78
		0x33,0x03,0x22,0x00, // add  x6, x4, x2
		0xe7,0x83,0x41,0xff, // jalr x7, x3, -12
		0x73,0x00,0x10,0x00  // 0x24 ebreak
	};
	memset(M, 0, sizeof(M));
	memcpy(M, prog, sizeof(prog));
	ref_load_mem(M, sizeof(M));

  // RTL 执行到 ebreak 时通过 DPI-C 调用 sim_finish() 结束仿真
  while (!sim_finish_flag) {
    dut.inst = inst_fetch(dut.rootp->top__DOT__pc_val);
    dut_single_cycle();
    ref_inst_cycle();

    // DUT GPR: top.my_lsu.gpr.mem, see generated Vtop___024root.h
    uint32_t *dut_regs = dut.rootp->top__DOT__my_lsu__DOT__gpr__DOT__mem.data();
    uint32_t *ref_regs = ref_get_regs();
    uint32_t dut_pc = dut.rootp->top__DOT__pc_val;
    uint32_t ref_pc = ref_get_pc();

    int gpr_is_diff = check_regs(dut_regs, ref_regs);
    int pc_is_diff = check_pc(dut_pc, ref_pc);
    if (gpr_is_diff || pc_is_diff) {
      printf("Simulation stop\n");
      break;
    }
    // printf("PC: %u ", dut_pc);
    // for(int i = 0;i < 4;i++){
    //   printf("REG[%d]= %u ", i, dut_regs[i]);
    // }
    // printf("\n");
  }

  dut.final();
  return 0;
}
