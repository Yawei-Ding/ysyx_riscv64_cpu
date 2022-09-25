#ifndef __RISCV64_REG_H__
#define __RISCV64_REG_H__

#include <common.h>

static inline int check_reg_idx(int idx) {
  IFDEF(CONFIG_RT_CHECK, assert(idx >= 0 && idx < 32));
  return idx;
}

#define gpr(idx) (cpu.gpr[check_reg_idx(idx)])

static inline const char* reg_name(int idx) { //remove int width, modified by dingyawei.
  extern const char* regs[];
  return regs[check_reg_idx(idx)];
}

#define mstatus 0x300
#define mtvec   0x305
#define mepc    0x341
#define mcause  0x342

static inline int check_csr_idx(int idx) {
  // input width of idx is 12bit, so it is in [0,0xFFF].
  IFDEF(CONFIG_RT_CHECK, assert(idx == 0x300 || idx == 0x305 || idx == 0x341 || idx == 0x342));
  switch (idx)
  {
    case mstatus: idx = 0; break;  // mstatus: 0x300 -> 0
    case mtvec  : idx = 1; break;  // mtvec  : 0x305 -> 1
    case mepc   : idx = 2; break;  // mepc   : 0x341 -> 2
    case mcause : idx = 3; break;  // mcause : 0x342 -> 3
  }
  return idx;
}

#define csr(idx) (cpu.csr[check_csr_idx(idx)])

#endif
