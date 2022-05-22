#include "Vtop.h"
#include "Vtop__Dpi.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

#define MEM_START 0x80000000
#define MEM_END   0x87ffffff

uint32_t memory[10] = {0xffc10113,0x100073,0x100073,0x100073,0x100073};

void step_and_dump_wave(VerilatedContext* contextp,VerilatedVcdC* tfp,Vtop* top)
{
  top->eval();
  contextp->timeInc(1);
  tfp->dump(contextp->time());
}

uint32_t pmem_read(uint64_t addr) {
  addr = (addr - 0x80000000)/4;
  return memory[addr];
}

svBit check_finsih(int inst){
  if(inst == 0x100073) //ebreak;
    return 1;
  else 
    return 0;
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
  top->clk = 0;
  top->rst_n = 1;
  step_and_dump_wave(contextp,tfp,top);
  while (!contextp->gotFinish())
  {
    top->clk = 1 ^ top->clk;
    if(top->pc >= MEM_START && top->pc <= MEM_END  ){
      top->inst = pmem_read(top->pc);
    }
    printf("pc = %lx, ins = %x\n", top->pc, top->inst);
    step_and_dump_wave(contextp,tfp,top);
    //assert(top->f == (top->a) ^ (top->b) );
  }
  ////////////////////// exit: //////////////////////
  step_and_dump_wave(contextp,tfp,top);
  tfp->close();
  delete tfp;
  delete top;
  delete contextp;
  return 0;
}
