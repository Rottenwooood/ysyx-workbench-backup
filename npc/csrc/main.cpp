#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <Vtop.h>
#include <Vtop___024root.h>

#define PMEM_BASE  0x80000000u
#define PMEM_SIZE  (128u * 1024u * 1024u)

static TOP_NAME dut;
static uint8_t M[PMEM_SIZE];
static size_t img_size = 0;

static volatile bool sim_finish_flag = false;

extern "C" void sim_finish() {
  sim_finish_flag = true;
}
static uint64_t read_call_id = 0;
extern "C" int pmem_read(int ram_raddr) {
  uint32_t a = ((uint32_t)ram_raddr & ~0x3u) - PMEM_BASE;
  uint32_t r = 0;
  if (a <= PMEM_SIZE - 4)
    r = M[a] | M[a+1]<<8 | M[a+2]<<16 | M[a+3]<<24;
  printf("READ #%lu addr=%08x val=%08x pc=%08x inst=%08x\n",
      read_call_id++, (uint32_t)ram_raddr, r,
      (uint32_t)dut.rootp->top__DOT__pc_val, (uint32_t)dut.inst);
  return r;
}
extern "C" void pmem_write(int ram_waddr, int ram_wdata, char ram_wmask) {
  uint32_t a = ((uint32_t)ram_waddr & ~0x3u) - PMEM_BASE;
  if (a > PMEM_SIZE - 4) {
    printf("DBG: pmem_write OOB addr=%08x a=%08x pc=%08x inst=%08x\n",
        (uint32_t)ram_waddr, a,
        (uint32_t)dut.rootp->top__DOT__pc_val, (uint32_t)dut.inst);
    return;
  }
  for(int i = 0;i < 4;i++){
    if(a + i < PMEM_SIZE && ((1 << i) & (unsigned char)ram_wmask))
      M[a+i] = (ram_wdata >> (8*i)) & 0xFF;
  }
}

static uint32_t inst_fetch(uint32_t pc) {
  uint32_t off = pc - PMEM_BASE;
  return M[off] | (M[off+1]<<8) | (M[off+2]<<16) | (M[off+3]<<24);
}

static void load_img(const char *path) {
  FILE *fp = fopen(path, "rb");
  if (fp == NULL) {
    printf("Can not open '%s'\n", path);
    exit(1);
  }
  img_size = fread(M, 1, PMEM_SIZE, fp);
  fclose(fp);
  printf("image: %s (%zu bytes)\n", path, img_size);
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
  for (int i = 0; i < 32; i++) {
    if (dut_regs[i] != ref_regs[i]) {
      printf("reg%d: DUT=%08x REF=%08x\n", i, dut_regs[i], ref_regs[i]);
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

int main(int argc, char *argv[]) {
  if (argc < 2) {
    printf("Usage: %s <image.bin>\n", argv[0]);
    return 1;
  }
  load_img(argv[1]);

  reset(10);
  ref_load_mem(M, img_size);

  const long CYCLE_LIMIT = 1000000;
  long cycle = 0;

  while (!sim_finish_flag) {
    dut.inst = inst_fetch(dut.rootp->top__DOT__pc_val);
    dut_single_cycle();
    ref_inst_cycle();
    uint32_t *dr = dut.rootp->top__DOT__my_lsu__DOT__gpr__DOT__mem.data();
    printf("[%ld] dut_pc=%08x ref_pc=%08x dut_inst=%08x DUT[x15]=%08x REF[x15]=%08x DUT[sp]=%08x\n", cycle,
        (uint32_t)dut.rootp->top__DOT__pc_val, (uint32_t)ref_get_pc(), (uint32_t)dut.inst,
        dr[15], ref_get_regs()[15], dr[2]);

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
    if (++cycle > CYCLE_LIMIT) {
      printf("cycle limit (%ld) reached, no diff found\n", CYCLE_LIMIT);
      break;
    }
  }

  //
  uint32_t *dut_regs = dut.rootp->top__DOT__my_lsu__DOT__gpr__DOT__mem.data();
  //a0（x10）
  if (dut_regs[10] != 0) {
    printf("HIT BAD TRAP\n");
    return 1;
  }else {
    printf("HIT GOOD TRAP\n");
  }

  dut.final();
  return 0;
}
