#include "include/include.h"
#include "Vtop__Dpi.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

#include <iostream>
#include <termios.h>
#include <unistd.h>
#include <thread>

bool rst_n_sync   = false; // read from rtl by dpi-c.
bool deal_device  = false;
bool system_exit  = false;
int  good_trap    = false;
extern uint64_t dut_pc;

void uart_input(uartlite &uart);
void connect_wire(axi4_ptr <64,64,4> &mmio_ptr, axi4_ptr <64,64,4> &mem_ptr, Vtop *top);

#ifdef DUMPWAVE_ON
void dump_wave(VerilatedContext* contextp,VerilatedVcdC* tfp,Vtop* top);
#endif

int main(int argc, char** argv, char** env) {

  VerilatedContext* contextp = new VerilatedContext;
  Vtop* top = new Vtop;
#ifdef DUMPWAVE_ON
  VerilatedVcdC* tfp = new VerilatedVcdC;
  contextp->traceEverOn(true);
  top->trace(tfp, 0);                         // Trace 0 levels of hierarchy (or see below)
  tfp->open("obj_dir/sim.vcd");
#endif
  ///////////////////////////////// init axi4 connect:  ///////////////////////////////
  axi4_ptr <64,64,4> mmio_ptr;
  axi4_ptr <64,64,4> mem_ptr;
  connect_wire(mmio_ptr,mem_ptr,top);
  assert(mmio_ptr.check());
  assert(mem_ptr.check());

  axi4_ref <64,64,4> mmio_ref(mmio_ptr);
  axi4     <64,64,4> mmio_sigs;
  axi4_ref <64,64,4> mmio_sigs_ref(mmio_sigs);
  axi4_xbar<64,64,4> mmio;

  uartlite           uart;
  std::thread        uart_input_thread(uart_input,std::ref(uart));
  uart_input_thread.detach();
  assert(mmio.add_dev(SERIAL_PORT,0x1000,&uart));

  axi4_ref <64,64,4> mem_ref(mem_ptr);
  axi4     <64,64,4> mem_sigs;
  axi4_ref <64,64,4> mem_sigs_ref(mem_sigs);
  axi4_mem <64,64,4> mem(4096l*1024*1024);

  //////////////////////////// init npc status / difftest: /////////////////////////////
  top->i_rst_n = !0;
  top->i_clk = 0;
  top->eval();
  npc_init(argc,argv,&mem);                   // load img to mem, init difftest.
#ifdef DIFFTEST_ON
  uint64_t lastpc;
  bool last_deal_device;
#endif

  ///////////////////////////////// verilator doing: ///////////////////////////////
  while (!contextp->gotFinish())
  {
    top->i_clk = !top->i_clk;                 // clk = ~clk;
    if(top->i_clk){
      mmio_sigs.update_input(mmio_ref);
      mem_sigs.update_input(mem_ref);
      top->eval();
      if(rst_n_sync){
        mem.beat(mem_sigs_ref);
        mmio.beat(mmio_sigs_ref);
        while (uart.exist_tx()) {
          char c = uart.getc();
          printf("%c",c);
          fflush(stdout);
        }
        mmio_sigs.update_output(mmio_ref);
        mem_sigs.update_output(mem_ref);
#ifdef DIFFTEST_ON
        // 0 means branch bubble, 1 means data bubble, 2 means write serial, dut_pc != lastpc means more than one cycle:
        if(dut_pc != 0 && dut_pc != 1 && dut_pc != lastpc){
          // 1. check last cycle reg status:
          if(last_deal_device){ //skip write or read device ins.
            cp2ref_reg(dut_pc);
          }
          else{
            if(!difftest_check()){
              print_regs();
              break;
            }
          }
          // 2. nemu step and update nemu regs/mem:
          if(!deal_device){
            difftest_step();
          }
        }
        lastpc = dut_pc;
        last_deal_device = deal_device;
#endif
      }
    }
    top->eval();
#ifdef DUMPWAVE_ON
    dump_wave(contextp,tfp,top);
#endif
    if(system_exit){
      pthread_cancel(uart_input_thread.native_handle());
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
void dump_wave(VerilatedContext* contextp,VerilatedVcdC* tfp,Vtop* top)
{
  contextp->timeInc(1);
  tfp->dump(contextp->time());
}
#endif

void uart_input(uartlite &uart) {
  termios tmp;
  tcgetattr(STDIN_FILENO,&tmp);
  tmp.c_lflag &=(~ICANON & ~ECHO);
  tcsetattr(STDIN_FILENO,TCSANOW,&tmp);
  while (1) {
    char c = getchar();
    if (c == 10) c = 13; // convert lf to cr
    uart.putc(c);
  }
}

void connect_wire(axi4_ptr <64,64,4> &mmio_ptr, axi4_ptr <64,64,4> &mem_ptr, Vtop *top) {
  // mmio:
  mmio_ptr.awaddr  = &(top->o_axi_aw_addr);
  mmio_ptr.awburst = &(top->o_axi_aw_burst);
  mmio_ptr.awid    = &(top->o_axi_aw_id);
  mmio_ptr.awlen   = &(top->o_axi_aw_len);
  mmio_ptr.awready = &(top->i_axi_aw_ready);
  mmio_ptr.awsize  = &(top->o_axi_aw_size);
  mmio_ptr.awvalid = &(top->o_axi_aw_valid);
  // w
  mmio_ptr.wdata   = &(top->o_axi_w_data);
  mmio_ptr.wlast   = &(top->o_axi_w_last);
  mmio_ptr.wready  = &(top->i_axi_w_ready);
  mmio_ptr.wstrb   = &(top->o_axi_w_strb);
  mmio_ptr.wvalid  = &(top->o_axi_w_valid);
  // b
  mmio_ptr.bid     = &(top->i_axi_b_id);
  mmio_ptr.bready  = &(top->o_axi_b_ready);
  mmio_ptr.bresp   = &(top->i_axi_b_resp);
  mmio_ptr.bvalid  = &(top->i_axi_b_valid);
  // ar
  mmio_ptr.araddr  = &(top->o_axi_ar_addr);
  mmio_ptr.arburst = &(top->o_axi_ar_burst);
  mmio_ptr.arid    = &(top->o_axi_ar_id);
  mmio_ptr.arlen   = &(top->o_axi_ar_len);
  mmio_ptr.arready = &(top->i_axi_ar_ready);
  mmio_ptr.arsize  = &(top->o_axi_ar_size);
  mmio_ptr.arvalid = &(top->o_axi_ar_valid);
  // r
  mmio_ptr.rdata   = &(top->i_axi_r_data);
  mmio_ptr.rid     = &(top->i_axi_r_id);
  mmio_ptr.rlast   = &(top->i_axi_r_last);
  mmio_ptr.rready  = &(top->o_axi_r_ready);
  mmio_ptr.rresp   = &(top->i_axi_r_resp);
  mmio_ptr.rvalid  = &(top->i_axi_r_valid);

  // mem:
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
