#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <cassert>
#include <sys/time.h>
#include <VSimTop.h>

static TOP_NAME dut;

#define FLASH_SIZE (16u * 1024u * 1024u)
static uint8_t flash[FLASH_SIZE];

extern "C" void flash_read(int32_t addr, int32_t *data){
  uint32_t a = (uint32_t)addr & (FLASH_SIZE - 1);
  *data = flash[a] | flash[a+1]<<8 | flash[a+2]<<16 | flash[a+3]<<24;
}
static volatile bool sim_finish_flag = false;
extern "C" void sim_finish() {
  sim_finish_flag = true;
}

static void load_flash(const char *path) {
  FILE *fp = fopen(path, "rb");
  if (fp == NULL) {
    printf("Can not open '%s'\n", path);
    exit(1);
  }
  size_t sz = fread(flash, 1, FLASH_SIZE, fp);
  fclose(fp);
  printf("flash image: %s (%zu bytes)\n", path, sz);
}

static void single_cycle() {
  dut.clock = 0; dut.cpuClock = 0; dut.eval();
  dut.clock = 1; dut.cpuClock = 1; dut.eval();
}

int main(int argc, char *argv[]) {
  if (argc < 2) {
    printf("Usage: %s <flash.bin>\n", argv[0]);
    return 1;
  }
  load_flash(argv[1]);

  dut.reset = 1;
  dut.coreSel = 0;
  dut.externalPins_uart0_rx = 1;
  dut.externalPins_mygpio_in = 0;
  for (int i = 0; i < 100; i++) // 复位保持至少100个周期
    single_cycle();
  dut.reset = 0;

  long long cycle = 0;
  struct timeval start, now;
  gettimeofday(&start, NULL);
  while (!sim_finish_flag) {
    single_cycle();
    cycle++;
    if ((cycle & 0xffffff) == 0) {
      gettimeofday(&now, NULL);
      if (now.tv_sec - start.tv_sec >= 120) break; // 程序约需运行30秒, 打印Hello后陷入死循环
    }
  }

  printf("sim %s, cycles=%lld\n", sim_finish_flag ? "finish" : "timeout", cycle);
  dut.final();
  return 0;
}
