#ifndef _INCLUDE_H_
#define _INCLUDE_H_

#include "Vtop.h"
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

#include "axi_mem/axi4.hpp"
#include "axi_mem/axi4_mem.hpp"
#include "axi_mem/axi4_xbar.hpp"
#include "axi_mem/mmio_mem.hpp"
#include "axi_mem/uartlite.hpp"

#define DIFFTEST_ON  1

typedef struct {
  uint64_t x[32];
  uint64_t pc;
} regfile;

void npc_init(int argc, char *argv[],axi4_mem <64,64,4> *mem);
void print_regs();
bool checkregs(regfile *ref, regfile *dut);
regfile pack_dut_regfile(uint64_t *dut_reg,uint64_t pc);

#ifdef DIFFTEST_ON
#define INST_START 0x80000000 // use for difftest reg copy.
#define PMEM_START 0x80000000 // use for difftest mem copy.
// #define PMEM_END   0x87ffffff
// #define PMEM_MSIZE (PMEM_END+1-PMEM_START)
void difftest_init(char *ref_so_file, char *img_file);
bool difftest_check();
void difftest_step();
#endif

#endif