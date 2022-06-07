#include "include/include.h"

uint64_t *dut_reg = NULL;
uint64_t dut_pc;

const char *regs[] = {
  "$0", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
  "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
  "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
  "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"
};

bool checkregs(regfile *ref, regfile *dut) {
  if(ref->pc != dut->pc){
    printf("difftest error: ");
    printf("next reg pc is diff: ref = 0x%lx, dut = 0x%lx\n",ref->pc,dut->pc);
    return false;
  }
  for (int i = 0; i < 32; i++) {
    if(ref->x[i] != dut->x[i]){
      printf("difftest error at nextpc = 0x%lx, ",dut->pc);
      printf("reg %s is diff: ref = 0x%lx, dut = 0x%lx\n",regs[i],ref->x[i],dut->x[i]);
      return false;
    }
  }
  return true;
}

void print_regs(){
  printf("dut pc = 0x%lx\n",dut_pc);
  for (int i = 0; i < 32; i++) {
    printf("dut reg %3s = 0x%lx\n",regs[i],dut_reg[i]);
  }
}

regfile pack_dut_regfile(uint64_t *dut_reg,uint64_t pc) {
  regfile dut;
  for (int i = 0; i < 32; i++) {
    dut.x[i] = dut_reg[i];
  }
  dut.pc = pc;
  return dut;
}
