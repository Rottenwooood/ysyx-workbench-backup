// DESCRIPTION: Verilator testbench for top.v (decode24)
// Drives en/x and checks y, dumping an FST waveform.

#include <verilated.h>
#include "Vtop.h"
#include "verilated_fst_c.h"

#include <cassert>
#include <cstdio>

static VerilatedContext* contextp = nullptr;
static Vtop* top = nullptr;
static VerilatedFstC* tfp = nullptr;
static vluint64_t sim_time = 0;

static void sim_init() {
  contextp = new VerilatedContext;
  contextp->traceEverOn(true);
  top = new Vtop{contextp};
  tfp = new VerilatedFstC;
  top->trace(tfp, 99);
  tfp->open("dump.fst");
}

static void step_and_dump_wave() {
  top->eval();
  tfp->dump(sim_time);
  sim_time += 1;
}

static void sim_exit() {
  top->final();
  tfp->close();
  delete top;
  delete tfp;
  delete contextp;
}

static void check() {
  int expected = top->en ? (1 << top->x) : 0;
  printf("en = %d, x = %02b, y = %04b\n", top->en, top->x, top->y);
  assert(top->y == expected);
}

int main(int argc, char** argv) {
  sim_init();

  top->en = 0b0;  top->x = 0b00;  step_and_dump_wave();  check();
                  top->x = 0b01;  step_and_dump_wave();  check();
                  top->x = 0b10;  step_and_dump_wave();  check();
                  top->x = 0b11;  step_and_dump_wave();  check();
  top->en = 0b1;  top->x = 0b00;  step_and_dump_wave();  check();
                  top->x = 0b01;  step_and_dump_wave();  check();
                  top->x = 0b10;  step_and_dump_wave();  check();
                  top->x = 0b11;  step_and_dump_wave();  check();

  sim_exit();
  printf("Test Passed!\n");
  return 0;
}
