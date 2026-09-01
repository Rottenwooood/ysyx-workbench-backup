#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <Vtop.h>
#include <Vtop___024root.h>
#include <sys/time.h>

#define PMEM_BASE  0x80000000u
#define PMEM_SIZE  (128u * 1024u * 1024u)

static TOP_NAME dut;
static uint8_t M[PMEM_SIZE];
static size_t img_size = 0;
unsigned long long cnt = 0;

static volatile bool sim_finish_flag = false;

struct timeval start, end;
const unsigned long Converter = 1000 * 1000; // 1s == 1000 * 1000 us

unsigned long long get_time() {
  // 模拟时钟 100MHz: 100 周期 = 1 us (1e8 周期 = 1 秒)
  // 返回从仿真开始经过的微秒数
  return cnt / 100;
}

unsigned long long current_time = 0;

extern "C" void sim_finish() {
  sim_finish_flag = true;
}
extern int uart_status = 1;
extern "C" int pmem_read(int ram_raddr) {
  if (ram_raddr == 0x10000004) {  // 读出UART状态
    if (dut.clk == 0) uart_status = (rand() & 0x7) == 0 ? 1 : 0; // 就绪概率为12.5%
    return uart_status;
  }

  // 读出时钟的低32位
  else if (ram_raddr == 0x20000000) { return current_time & 0xffffffff; }
  // 读出时钟的高32位
  else if (ram_raddr == 0x20000004) { return current_time >> 32; }

  // 读存储器数组
  uint32_t a = ((uint32_t)ram_raddr & ~0x3u) - PMEM_BASE;
  if (a > PMEM_SIZE - 4) return 0;
  return M[a] | M[a+1]<<8 | M[a+2]<<16 | M[a+3]<<24;
}
extern "C" void pmem_write(int ram_waddr, int ram_wdata, char ram_wmask) {
  if (ram_waddr == 0x10000000) {  // 写入UART
    if (dut.clk) fputc(ram_wdata & 0xff, stderr);   // 组合逻辑块一拍会被求值两次, 只在写回那次打印
    return;
  }
  uint32_t a = ((uint32_t)ram_waddr & ~0x3u) - PMEM_BASE;
  if (a > PMEM_SIZE - 4) return;
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

int main(int argc, char *argv[]) {
  if (argc < 2) {
    printf("Usage: %s <image.bin>\n", argv[0]);
    return 1;
  }
  load_img(argv[1]);

  reset(10);
  ref_load_mem(M, img_size);

  const long CYCLE_LIMIT = 10000000;
  long cycle = 0;
  int ret = gettimeofday(&start, NULL);
  while (!sim_finish_flag) {
    current_time = get_time();
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
    // if (++cycle > CYCLE_LIMIT) {
    //   printf("cycle limit (%ld) reached, no diff found\n", CYCLE_LIMIT);
    //   break;
    // }
    cnt++;
  }
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
