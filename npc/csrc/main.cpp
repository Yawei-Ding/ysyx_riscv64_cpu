#include "include/include.h"
#include "Vtop__Dpi.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

bool rst_n_sync = false; //read from rtl by dpi-c.

void step_and_dump_wave(VerilatedContext* contextp,VerilatedVcdC* tfp,Vtop* top)
{
  top->eval();
  contextp->timeInc(1);
  tfp->dump(contextp->time());
}

int main(int argc, char *argv[]) {
  ///////////////////////////////// verilator init: /////////////////////////////////
  VerilatedContext* contextp = new VerilatedContext;
  VerilatedVcdC* tfp = new VerilatedVcdC;
  Vtop* top = new Vtop;
  contextp->traceEverOn(true);
  top->trace(tfp, 0);                       // Trace 0 levels of hierarchy (or see below)
  tfp->open("dump.vcd");

  ///////////////////////////////// init npc status: ////////////////////////////////
  top->rst_n = !0;
  top->clk = 0;
  top->ins = 0;
  step_and_dump_wave(contextp,tfp,top);     //init reg status,use for difftest_init.
  npc_init(argc,argv);

  ///////////////////////////////// verilator doing: ///////////////////////////////
  while (!contextp->gotFinish())
  {
    top->clk = !top->clk;                   //clk = ~clk;
    if(top->clk){
      top->eval();                          //update rst_n_sync and pc to fetch ins.
      if(rst_n_sync){
#ifdef DIFFTEST_ON
        if(!difftest_check(top->pc)){       // check last cycle reg/mem, but pc is new(this time).
          print_regs();
          break; 
        }
        difftest_step();                    // ref step and update regs/mem.
#endif
        top->ins = pmem_read(top->pc,4);    // rtl step, but not update reg/mem, update reg/mem in next posedge clk.
        //printf("pc = 0x%lx, ins = 0x%08x\n", top->pc, top->ins);
      }
    }
    step_and_dump_wave(contextp,tfp,top);
  }

  ///////////////////////////////// exit: /////////////////////////////////
  step_and_dump_wave(contextp,tfp,top);
  tfp->close();
  delete tfp;
  delete top;
  delete contextp;

  return 0;
}
