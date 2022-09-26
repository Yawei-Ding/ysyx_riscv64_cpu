#include "include/include.h"
#include "verilated_dpi.h"

extern bool rst_n_sync;
extern bool system_exit;
extern bool good_trap;
extern bool diff_skip;
extern bool diff_commit;

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

extern "C" void get_diff_skip(svBit skip){
  diff_skip = skip;
}

extern "C" void get_diff_commit(svBit commit){
  diff_commit = commit;
}

extern regfile dut_reg;
extern "C" void get_dut_regs(uint64_t dut_pc, uint64_t dut_x0, uint64_t dut_x1, uint64_t dut_x2, uint64_t dut_x3, uint64_t dut_x4, uint64_t dut_x5,
uint64_t dut_x6, uint64_t dut_x7, uint64_t dut_x8, uint64_t dut_x9, uint64_t dut_x10, uint64_t dut_x11, uint64_t dut_x12,uint64_t dut_x13, uint64_t dut_x14, 
uint64_t dut_x15, uint64_t dut_x16, uint64_t dut_x17, uint64_t dut_x18, uint64_t dut_x19, uint64_t dut_x20, uint64_t dut_x21, uint64_t dut_x22, uint64_t dut_x23,
uint64_t dut_x24, uint64_t dut_x25, uint64_t dut_x26, uint64_t dut_x27, uint64_t dut_x28, uint64_t dut_x29, uint64_t dut_x30, uint64_t dut_x31, 
uint64_t dut_mstatus, uint64_t dut_mtvec, uint64_t dut_mepc, uint64_t dut_mcause){
  dut_reg.pc     = dut_pc ;
  dut_reg.x[0]   = dut_x0 ;
  dut_reg.x[1]   = dut_x1 ;
  dut_reg.x[2]   = dut_x2 ;
  dut_reg.x[3]   = dut_x3 ;
  dut_reg.x[4]   = dut_x4 ;
  dut_reg.x[5]   = dut_x5 ;
  dut_reg.x[6]   = dut_x6 ;
  dut_reg.x[7]   = dut_x7 ;
  dut_reg.x[8]   = dut_x8 ;
  dut_reg.x[9]   = dut_x9 ;
  dut_reg.x[10]  = dut_x10;
  dut_reg.x[11]  = dut_x11;
  dut_reg.x[12]  = dut_x12;
  dut_reg.x[13]  = dut_x13;
  dut_reg.x[14]  = dut_x14;
  dut_reg.x[15]  = dut_x15;
  dut_reg.x[16]  = dut_x16;
  dut_reg.x[17]  = dut_x17;
  dut_reg.x[18]  = dut_x18;
  dut_reg.x[19]  = dut_x19;
  dut_reg.x[20]  = dut_x20;
  dut_reg.x[21]  = dut_x21;
  dut_reg.x[22]  = dut_x22;
  dut_reg.x[23]  = dut_x23;
  dut_reg.x[24]  = dut_x24;
  dut_reg.x[25]  = dut_x25;
  dut_reg.x[26]  = dut_x26;
  dut_reg.x[27]  = dut_x27;
  dut_reg.x[28]  = dut_x28;
  dut_reg.x[29]  = dut_x29;
  dut_reg.x[30]  = dut_x30;
  dut_reg.x[31]  = dut_x31;
  dut_reg.csr[0] = dut_mstatus;
  dut_reg.csr[1] = dut_mtvec;
  dut_reg.csr[2] = dut_mepc;
  dut_reg.csr[3] = dut_mcause;
}
