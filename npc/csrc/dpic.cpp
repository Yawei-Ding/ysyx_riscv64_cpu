#include "include/include.h"
#include "verilated_dpi.h"

extern bool rst_n_sync;
extern "C" void check_rst(svBit rst_flag){
  if(rst_flag)
    rst_n_sync = true;
  else 
    rst_n_sync = false;
}

extern "C" svBit check_finsih(int ins){
  if(ins == 0x100073) //ebreak;
    return 1;
  else 
    return 0;
}

extern uint64_t *dut_reg;
extern uint64_t dut_pc;
extern "C" void set_reg_ptr(const svOpenArrayHandle r) {
  dut_reg = (uint64_t *)(((VerilatedDpiOpenVar*)r)->datap());
}

extern "C" void diff_read_pc(uint64_t rtl_pc){
  dut_pc = rtl_pc;
}
