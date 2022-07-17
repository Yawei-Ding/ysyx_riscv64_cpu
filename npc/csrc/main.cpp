#include "include/include.h"
#include "Vtop__Dpi.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

bool rst_n_sync = false; //read from rtl by dpi-c.
extern uint64_t dut_pc;

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
  tfp->open("obj_dir/sim.vcd");

  ///////////////////////////////// init npc status: ////////////////////////////////
  top->i_rst_n = !0;
  top->i_clk = 0;
  step_and_dump_wave(contextp,tfp,top);       //init reg status,use for difftest_init.
  npc_init(argc,argv);
#ifdef DIFFTEST_ON
  uint64_t lastpc;
#endif

  ///////////////////////////////// verilator doing: ///////////////////////////////
  while (!contextp->gotFinish())
  {
    top->i_clk = !top->i_clk;                 // clk = ~clk;
#ifdef DIFFTEST_ON
    top->eval();                              // update rst_n_sync
    if(top->i_clk && rst_n_sync){
      // 0 means branch bubble, 1 means data bubble, dut_pc != lastpc means more than one cycle:
      if(dut_pc != 0 && dut_pc != 1 && dut_pc != lastpc){ 
        if(!difftest_check()){                // check last cycle reg/mem.
          print_regs();
          break;
        }
        difftest_step();                      // nemu step and update regs/mem.
      }
      lastpc = dut_pc;
    }
#endif
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
