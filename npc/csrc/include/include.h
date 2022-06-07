#ifndef _INCLUDE_H_
#define _INCLUDE_H_

#include "Vtop.h"
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

#define INST_START 0x80000000
#define PMEM_START 0x80000000
#define PMEM_END   0x87ffffff
#define PMEM_MSIZE (PMEM_END+1-PMEM_START)

#define DIFFTEST_ON  1

typedef struct {
  uint64_t x[32];
  uint64_t pc;
} regfile;

uint8_t* guest_to_host(uint64_t paddr);
uint64_t host_to_guest(uint8_t *haddr);
uint64_t pmem_read(uint64_t addr, int len);
void pmem_write(uint64_t addr, uint64_t data, int len);
void npc_init(int argc, char *argv[]);
void print_regs();
bool checkregs(regfile *ref, regfile *dut);
regfile pack_dut_regfile(uint64_t *dut_reg,uint64_t pc);

#ifdef DIFFTEST_ON
void difftest_init(char *ref_so_file, long img_size);
bool difftest_check();
void difftest_step();
#endif

#endif