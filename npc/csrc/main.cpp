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

int main() {
  reset(10);

  while (ref_get_pc() != 8) {
    dut_single_cycle();
    ref_inst_cycle();

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
  }

  dut.final();
  return 0;
}
