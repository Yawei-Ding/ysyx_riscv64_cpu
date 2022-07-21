#include "include/include.h"
#include "Vtop__Dpi.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

#include <iostream>
#include <termios.h>
#include <unistd.h>
#include <thread>

bool rst_n_sync = false; //read from rtl by dpi-c.
extern uint64_t dut_pc;

void connect_wire(axi4_ptr <64,64,4> &mem_ptr, Vtop *top);
void dump_wave(VerilatedContext* contextp,VerilatedVcdC* tfp,Vtop* top);

int main(int argc, char** argv, char** env) {

  VerilatedContext* contextp = new VerilatedContext;
  VerilatedVcdC* tfp = new VerilatedVcdC;
  Vtop* top = new Vtop;
  contextp->traceEverOn(true);
  top->trace(tfp, 0);                         // Trace 0 levels of hierarchy (or see below)
  tfp->open("obj_dir/sim.vcd");

  ///////////////////////////////// init axi4 connect:  ///////////////////////////////
  axi4_ptr <64,64,4> mem_ptr;
  connect_wire(mem_ptr,top);
  assert(mem_ptr.check());
  axi4_ref <64,64,4> mem_ref(mem_ptr);
  axi4     <64,64,4> mem_sigs;
  axi4_ref <64,64,4> mem_sigs_ref(mem_sigs);
  axi4_mem <64,64,4> mem(4096l*1024*1024);

  //////////////////////////// init npc status / difftest: /////////////////////////////
  top->i_rst_n = !0;
  top->i_clk = 0;
  top->eval();
  dump_wave(contextp,tfp,top);       // init reg status,use for difftest_init.
  npc_init(argc,argv,&mem);                   // load img to mem, init difftest.
#ifdef DIFFTEST_ON
  uint64_t lastpc;
#endif

  ///////////////////////////////// verilator doing: ///////////////////////////////
  while (!contextp->gotFinish())
  {
    top->i_clk = !top->i_clk;                 // clk = ~clk;
    if(top->i_clk){
      mem_sigs.update_input(mem_ref);
      top->eval();
      mem.beat(mem_sigs_ref);
      mem_sigs.update_output(mem_ref);
#ifdef DIFFTEST_ON
      // 0 means branch bubble, 1 means data bubble, dut_pc != lastpc means more than one cycle:
      if(dut_pc != 0 && dut_pc != 1 && rst_n_sync && dut_pc != lastpc){ 
        if(!difftest_check()){                // check last cycle reg/mem.
          print_regs();
          break;
        }
        difftest_step();                      // nemu step and update regs/mem.
      }
      lastpc = dut_pc;
#endif
    }
    else{
      top->eval();
    }
    dump_wave(contextp,tfp,top);
  }

  ///////////////////////////////// exit: /////////////////////////////////
  top->final();
  dump_wave(contextp,tfp,top);
  tfp->close();
  delete tfp;
  delete top;
  delete contextp;

  return 0;
}

void dump_wave(VerilatedContext* contextp,VerilatedVcdC* tfp,Vtop* top)
{
  contextp->timeInc(1);
  tfp->dump(contextp->time());
}

void connect_wire(axi4_ptr <64,64,4> &mem_ptr, Vtop *top) {
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
