#include "Vtop.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

void step_and_dump_wave(VerilatedContext* contextp,VerilatedVcdC* tfp,Vtop* top)
{
    top->eval();
    contextp->timeInc(1);
    tfp->dump(contextp->time());
}

int main() {
    ////////////////////// init: //////////////////////
    VerilatedContext* contextp = new VerilatedContext;
    VerilatedVcdC* tfp = new VerilatedVcdC;
    Vtop* top = new Vtop;
    
    contextp->traceEverOn(true);
    top->trace(tfp, 0); // Trace 0 levels of hierarchy (or see below)
    tfp->open("dump.vcd");
    
    ////////////////////// doing: //////////////////////
	while (!contextp->gotFinish())
	{
        top->a =rand() & 1 ;top->b = rand() & 1;
        step_and_dump_wave(contextp,tfp,top);
        printf("a = %d, b = %d, f = %d\n", top->a, top->b, top->f);
        assert(top->f == (top->a) ^ (top->b) );
	}
	
    ////////////////////// exit: //////////////////////
  	step_and_dump_wave(contextp,tfp,top);
    tfp->close();
    delete tfp;
    delete top;
    delete contextp;
    return 0;
}
