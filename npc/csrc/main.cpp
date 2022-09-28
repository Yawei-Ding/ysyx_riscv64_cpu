#include "include/include.h"
#include "Vtop__Dpi.h"
#include "verilated.h"
#include "verilated_fst_c.h"

#include <iostream>
#include <termios.h>
#include <unistd.h>
#include <thread>

bool rst_n_sync   = false; // read from rtl by dpi-c.
bool diff_skip    = false;
bool diff_commit  = false;
bool system_exit  = false;
int  good_trap    = false;

extern regfile dut_reg;

void connect_wire(axi4_ptr <32,64,4> &mem_ptr, Vtop *top);
void device_update();

#ifdef DUMPWAVE_ON
void dump_wave(VerilatedContext* contextp,VerilatedFstC* tfp,Vtop* top);
#endif

int main(int argc, char** argv, char** env) {

  VerilatedContext* contextp = new VerilatedContext;
  Vtop* top = new Vtop;
#ifdef DUMPWAVE_ON
  VerilatedFstC* tfp = new VerilatedFstC;
  contextp->traceEverOn(true);
  top->trace(tfp, 0);                         // Trace 0 levels of hierarchy (or see below)
  tfp->open("obj_dir/sim.fst");
#endif
  ///////////////////////////////// init axi4 connect:  ///////////////////////////////
  axi4_ptr <32,64,4> mem_ptr;
  connect_wire(mem_ptr,top);
  assert(mem_ptr.check());

  axi4_ref <32,64,4> mem_ref(mem_ptr);
  axi4     <32,64,4> mem_sigs;
  axi4_ref <32,64,4> mem_sigs_ref(mem_sigs);
  axi4_mem <32,64,4> mem;

  //////////////////////////// init npc status / difftest: /////////////////////////////
  top->i_rst_n = !0;
  top->i_clk = 0;
  top->eval();
  npc_init(argc,argv,&mem);                   // load img to mem, init difftest.
#ifdef DIFFTEST_ON
  bool diff_skip_r;
#endif

  ///////////////////////////////// verilator doing: ///////////////////////////////
  while (!contextp->gotFinish())
  {
    top->i_clk = !top->i_clk;                 // clk = ~clk;
    if(top->i_clk){
      mem_sigs.update_input(mem_ref);
      top->eval();
      if(rst_n_sync){
        mem.beat(mem_sigs_ref);
        mem_sigs.update_output(mem_ref);
        if(diff_commit || diff_skip){
          device_update();
#ifdef DIFFTEST_ON
          // 1. check last cycle reg status:
          if(diff_skip_r){ //skip write or read device ins.
            diff_cpdutreg2ref();
          }
          else{
            if(!difftest_check()){
              print_regs();
              break;
            }
          }
          // 2. nemu step and update nemu regs/mem:
          if(!diff_skip){
            difftest_step();
          }
          diff_skip_r = diff_skip;
#endif
        }
      }
    }
    top->eval();
#ifdef DUMPWAVE_ON
    dump_wave(contextp,tfp,top);
#endif
    if(system_exit){
      switch(good_trap){
        case 1: printf("\n----------EBREAK: HIT !! GOOD !! TRAP!!---------------\n\n"); break;
        case 0: printf("\n----------EBREAK: HIT !! BAD  !! TRAP!!---------------\n\n"); break;
      }
      break;
    }
  }

  ///////////////////////////////// exit: /////////////////////////////////
  top->final();
#ifdef DUMPWAVE_ON
  dump_wave(contextp,tfp,top);
  tfp->close();
  delete tfp;
#endif
  delete top;
  delete contextp;

  return 0;
}

#ifdef DUMPWAVE_ON
void dump_wave(VerilatedContext* contextp,VerilatedFstC* tfp,Vtop* top)
{
  contextp->timeInc(1);
  tfp->dump(contextp->time());
}
#endif


void connect_wire(axi4_ptr <32,64,4> &mem_ptr, Vtop *top) {
  // aw
  mem_ptr.awaddr  = &(top->o_axi_aw_addr);
  mem_ptr.awburst = &(top->o_axi_aw_burst);
  mem_ptr.awid    = &(top->o_axi_aw_id);
  mem_ptr.awlen   = &(top->o_axi_aw_len);
  mem_ptr.awready = &(top->i_axi_aw_ready);
  mem_ptr.awsize  = &(top->o_axi_aw_size);
  mem_ptr.awvalid = &(top->o_axi_aw_valid);
  // w
  mem_ptr.wdata   = &(top->o_axi_w_data);
  mem_ptr.wlast   = &(top->o_axi_w_last);
  mem_ptr.wready  = &(top->i_axi_w_ready);
  mem_ptr.wstrb   = &(top->o_axi_w_strb);
  mem_ptr.wvalid  = &(top->o_axi_w_valid);
  // b
  mem_ptr.bid     = &(top->i_axi_b_id);
  mem_ptr.bready  = &(top->o_axi_b_ready);
  mem_ptr.bresp   = &(top->i_axi_b_resp);
  mem_ptr.bvalid  = &(top->i_axi_b_valid);
  // ar
  mem_ptr.araddr  = &(top->o_axi_ar_addr);
  mem_ptr.arburst = &(top->o_axi_ar_burst);
  mem_ptr.arid    = &(top->o_axi_ar_id);
  mem_ptr.arlen   = &(top->o_axi_ar_len);
  mem_ptr.arready = &(top->i_axi_ar_ready);
  mem_ptr.arsize  = &(top->o_axi_ar_size);
  mem_ptr.arvalid = &(top->o_axi_ar_valid);
  // r
  mem_ptr.rdata   = &(top->i_axi_r_data);
  mem_ptr.rid     = &(top->i_axi_r_id);
  mem_ptr.rlast   = &(top->i_axi_r_last);
  mem_ptr.rready  = &(top->o_axi_r_ready);
  mem_ptr.rresp   = &(top->i_axi_r_resp);
  mem_ptr.rvalid  = &(top->i_axi_r_valid);
}
