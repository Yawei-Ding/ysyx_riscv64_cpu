#include <isa.h>
#include "local-include/reg.h"

const char *regs[] = {
  "$0", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
  "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
  "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
  "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"
};

//-------------------- add by dingyawei,start.--------------------------------//
void isa_reg_display() {
  printf("regid   name:   hexvalue:       decvalue:\n");
  for(int idx = 0; idx < 32; idx++){
    printf("%d\t%s\t0x%lx\t\t%ld\n",check_reg_idx(idx),\
                  regs[idx],cpu.gpr[idx],cpu.gpr[idx]);
  }
  printf("Non\tpc\t0x%lx\t\t%ld\n",cpu.pc,cpu.pc);
}
//-------------------- add by dingyawei,end.--------------------------------//

bool isa_reg_str2val(const char *s, word_t *reg) {
  if(strcmp(s,"pc") == 0){
    *reg = cpu.pc;
    return true;
  }
  for(int idx = 0; idx < 32; idx++){
    if(strcmp(s,regs[idx]) == 0){
      *reg = cpu.gpr[idx];
      return true;
    }
  }
  return false;
}
