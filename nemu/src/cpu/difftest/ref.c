#include <isa.h>
#include <cpu/cpu.h>
#include <difftest-def.h>
#include <memory/paddr.h>

void difftest_memcpy(paddr_t addr, void *buf, size_t n, bool direction) {
  if (direction == DIFFTEST_TO_REF) {
    for (size_t i = 0; i < n; i++) {
      paddr_write(addr+i,1,*((uint8_t*)buf+i));
    }
  } else {
    assert(0);
  }
}

void diff_set_regs(CPU_state* dut){
  for (int i = 0; i < 32; i++) {
    cpu.gpr[i]= dut->gpr[i];
  }
  cpu.pc = dut->pc;
}

void diff_get_regs(CPU_state* dut){
  for (int i = 0; i < 32; i++) {
    dut->gpr[i] = cpu.gpr[i];
  }
  dut->pc = cpu.pc;
}

void difftest_regcpy(void *dut, bool direction) {
  if (direction == DIFFTEST_TO_REF) {
    diff_set_regs(dut);
  } else {
    diff_get_regs(dut);
  }
}

void difftest_exec(uint64_t n) {
  cpu_exec(n);
}

void difftest_raise_intr(word_t NO) {
  assert(0);
}

void difftest_init() {
  /* Perform ISA dependent initialization. */
  init_isa();
}