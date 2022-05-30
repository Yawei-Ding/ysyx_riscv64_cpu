#include "include/include.h"
#include "Vtop__Dpi.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

extern bool rst_n_sync; //read from rtl by dpi-c.

void step_and_dump_wave(VerilatedContext* contextp,VerilatedVcdC* tfp,Vtop* top)
{
  top->eval();
  contextp->timeInc(1);
  tfp->dump(contextp->time());
}

int main(int argc, char *argv[]) {
  ////////////////////// init npc status: /////////////////////
  npc_init(argc,argv);
  ////////////////////// verilator init: //////////////////////
  VerilatedContext* contextp = new VerilatedContext;
  VerilatedVcdC* tfp = new VerilatedVcdC;
  Vtop* top = new Vtop;
  
  contextp->randReset(2);
  contextp->traceEverOn(true);
  top->trace(tfp, 0); // Trace 0 levels of hierarchy (or see below)
  tfp->open("dump.vcd");

  ////////////////////// verilator doing: //////////////////////
  top->rst_n = !0;
  top->clk = 0;
  top->ins = 0;
  step_and_dump_wave(contextp,tfp,top);
  while (!contextp->gotFinish())
  {
    top->clk = !top->clk;  //clk = ~clk;
    if(top->clk){
      top->eval();  //update rst_n_sync and pc to fetch ins.
      if(rst_n_sync){
        top->ins = pmem_read(top->pc,4);
        printf("pc = 0x%lx, ins = 0x%08x\n", top->pc, top->ins);
      }
    }
    step_and_dump_wave(contextp,tfp,top);
  }

  ////////////////////// exit: //////////////////////
  step_and_dump_wave(contextp,tfp,top);
  tfp->close();
  delete tfp;
  delete top;
  delete contextp;

  return 0;
}
