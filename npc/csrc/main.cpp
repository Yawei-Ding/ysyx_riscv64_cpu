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
  top->trace(tfp, 0);                         // Trace 0 levels of hierarchy (or see below)
  tfp->open("dump.vcd");

  ///////////////////////////////// init npc status: ////////////////////////////////
  top->i_rst_n = !0;
  top->i_clk = 0;
  top->i_ins = 0;
  step_and_dump_wave(contextp,tfp,top);       //init reg status,use for difftest_init.
  npc_init(argc,argv);

  ///////////////////////////////// verilator doing: ///////////////////////////////
  while (!contextp->gotFinish())
  {
    top->i_clk = !top->i_clk;                 //clk = ~clk;
    if(top->i_clk){
      top->eval();                            //update rst_n_sync and pc to fetch ins.
      if(rst_n_sync){
#ifdef DIFFTEST_ON
        if(!difftest_check(top->o_pc)){       // check last cycle reg/mem, but pc is new(this time).
          print_regs();
          break; 
        }
        difftest_step();                      // ref step and update regs/mem.
#endif
        top->i_ins = pmem_read(top->o_pc,4);  // rtl step, but not update reg/mem, update reg/mem in next posedge clk.
        //printf("pc = 0x%lx, ins = 0x%08x\n", top->o_pc, top->i_ins);
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
