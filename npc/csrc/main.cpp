// DESCRIPTION: Verilator: Verilog example module
//
// This file ONLY is placed under the Creative Commons Public Domain.
// SPDX-FileCopyrightText: 2017 Wilson Snyder
// SPDX-License-Identifier: CC0-1.0
//======================================================================

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
// Include common routines
#include <verilated.h>

// Include model header, generated from Verilating "top.v"
#include "Vtop.h"
#include "verilated_fst_c.h"   // FST

vluint64_t sim_time = 0;       // 仿真时间（声明）

int main(int argc, char** argv) {
    // See a similar example walkthrough in the verilator manpage.

    // Construct a VerilatedContext to hold simulation time, etc.
    VerilatedContext* const contextp = new VerilatedContext;

    // Pass arguments so Verilated code can see them, e.g. $value$plusargs
    contextp->commandArgs(argc, argv);

    // Turn on tracing on THIS context (must match the one the model uses)
    contextp->traceEverOn(true);

    // Construct the Verilated model, from Vtop.h generated from Verilating "top.v"
    Vtop* const top = new Vtop{contextp};
    VerilatedFstC* tfp = new VerilatedFstC;
    top->trace(tfp, 99);           // 深度99级
    tfp->open("dump.fst");         // 打开波形文件

    // 用固定步数仿真，避免无限循环
    const int NUM_STEPS = 20;
    for (int i = 0; i < NUM_STEPS; i++) {
        int a = rand() & 1;
        int b = rand() & 1;
        top->a = a;
        top->b = b;
        // Evaluate model
        top->eval();
        tfp->dump(sim_time);           // 在每个时间点写入
        sim_time += 1;
        printf("a = %d, b = %d, f = %d\n", a, b, top->f);
        assert(top->f == (a ^ b));
    }

    // Final model cleanup
    top->final();
    tfp->close();               // 关闭波形文件

    // Destroy model
    delete top;
    delete tfp;
    delete contextp;

    // Return good completion status
    return 0;
}
