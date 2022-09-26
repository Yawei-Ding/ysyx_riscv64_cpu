#include "include/include.h"
#include "verilated_dpi.h"

extern bool rst_n_sync;
extern bool system_exit;
extern bool good_trap;
extern "C" void check_rst(svBit rst_flag){
  if(rst_flag)
    rst_n_sync = true;
  else 
    rst_n_sync = false;
}

extern "C" void check_finsih(int ins,int a0zero){
  if(ins == 0x100073){
    system_exit = true;
    good_trap = a0zero;
  }
  else
    system_exit = false;

}

extern uint64_t *dut_reg;
extern uint64_t dut_pc;
extern bool diff_skip;
extern bool diff_commit;

extern "C" void set_reg_ptr(const svOpenArrayHandle r) {
  dut_reg = (uint64_t *)(((VerilatedDpiOpenVar*)r)->datap());
}

extern "C" void get_diff_pc(uint64_t rtl_pc){
  dut_pc = rtl_pc;
}

extern "C" void get_diff_skip(svBit skip){
  diff_skip = skip;
}

extern "C" void get_diff_commit(svBit commit){
  diff_commit = commit;
}
