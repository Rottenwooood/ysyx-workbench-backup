#include <stdio.h>
#include <stdint.h>
#include <Vtop.h>
#include <Vtop___024root.h>

static TOP_NAME dut;

void ref_inst_cycle();
uint8_t *ref_get_regs();
uint8_t ref_get_pc();

static void dut_single_cycle() {
  dut.clk = 0; dut.eval();
  dut.clk = 1; dut.eval();
}

static void reset(int n) {
  dut.reset = 1;
  while (n-- > 0) dut_single_cycle();
  dut.reset = 0;
}

static int check_regs(const uint8_t *dut_regs, const uint8_t *ref_regs) {
  int is_diff = 0;
  for (int i = 0; i < 4; i++) {
    if (dut_regs[i] != ref_regs[i]) {
      printf("reg%d: DUT=%u REF=%u\n", i, dut_regs[i], ref_regs[i]);
      is_diff = 1;
    }
  }
  return is_diff;
}

static int check_pc(const uint8_t dut_pc, const uint8_t ref_pc) {
  int is_diff = 0;
  if (dut_pc != ref_pc) {
    printf("pc: DUT=%u REF=%u\n", dut_pc, ref_pc);
    is_diff = 1;
  }
  return is_diff;
}

uint8_t M[64];

uint32_t pmem_read(uint32_t pc){
  uint32_t inst = M[PC] | (M[PC+1] << 8) | (M[PC+2] << 16) | (M[PC+3] << 24);
  return inst;
}

int main() {
  reset(10);
  //	PC=0x00: lui  x1, 0x12345 -> x1=0x12345000
	//	PC=0x04: addi x2, x1, 0x678 -> x2=0x12345678
	//	PC=0x08: addi x3, x0, 0x30 -> x3=0x30
	//	PC=0x0c: sw   x2, 0(x3)   -> M[0x30]=0x12345678
	//	PC=0x10: lw   x4, 0(x3)   -> x4=0x12345678
	//	PC=0x14: sb   x2, 4(x3)   -> M[0x34]=0x78
	//	PC=0x18: lbu  x5, 4(x3)   -> x5=0x78
	//	PC=0x1c: add  x6, x4, x2  -> x6=0x2468ACF0
	//	PC=0x20: jalr x7, x3, -12 -> 跳到 0x24 的 ebreak
	//	PC=0x24: ebreak
	static const uint8_t prog[] = {
		0xb7,0x50,0x34,0x12, 
		0x13,0x81,0x80,0x67, 
		0x93,0x01,0x00,0x03 //,
		// 0x23,0xa0,0x21,0x00, 
		// 0x03,0xa2,0x01,0x00, 
		// 0x23,0x82,0x21,0x00,
		// 0x83,0xc2,0x41,0x00, 
		// 0x33,0x03,0x22,0x00, 
		// 0xe7,0x83,0x41,0xff,
		// 0x73,0x00,0x10,0x00
	};
	for(int i = 0;i < 40;i++) M[i] = prog[i];
  
  while (ref_get_pc() != 8) {
    dut_single_cycle();
    ref_inst_cycle();
    top->inst = pmem_read(top->pc_val);

    // DUT GPR: top.gpr.mem, see generated Vtop___024root.h
    uint8_t *dut_regs = dut.rootp->top__DOT__gpr__DOT__mem.data();
    uint8_t *ref_regs = ref_get_regs();
    uint8_t dut_pc = dut.rootp->top__DOT__pc_val;
    uint8_t ref_pc = ref_get_pc();

    int gpr_is_diff = check_regs(dut_regs, ref_regs);
    if (gpr_is_diff) {
      printf("GPR different\n");
      printf("Simulation stop\n");
      break;
    }
    int pc_is_diff = check_pc(dut_pc, ref_pc);
    if (pc_is_diff) {
      printf("PC different\n");
      printf("Simulation stop\n");
      break;
    }
    printf("PC: %u ",dut_pc);
    for(int i = 0;i < 4;i++){
      printf("REG[%d]= %u ", i, dut_regs[i]);
    }
    printf("\n");
  }

  dut.final();
  return 0;
}
