#ifndef _INCLUDE_H_
#define _INCLUDE_H_

#include "Vtop.h"
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

#include "axi_slave/axi4.hpp"
#include "axi_slave/axi4_slave.hpp"
#include "axi_slave/axi4_mem.hpp"

#define ARRLEN(arr) (int)(sizeof(arr) / sizeof(arr[0]))

//#define DIFFTEST_ON  1
//#define DUMPWAVE_ON  1

#define INST_START    0x80000000 // use for difftest reg copy.
#define PMEM_START    0x80000000 // use for difftest mem copy.
#define PMEM_END      0x87ffffff
#define PMEM_MSIZE    (PMEM_END+1-PMEM_START)

#define SERIAL_PORT   0x10000000 // 0x1000_0000 ~ 0x1000_0fff

typedef struct {
  uint64_t x[32];
  uint64_t pc;
  uint64_t csr[4];
} regfile;

void npc_init(int argc, char *argv[],axi4_mem <32,64,4> *mem);
void print_regs();
bool checkregs(regfile *ref, regfile *dut);

#ifdef DIFFTEST_ON
void difftest_init(char *ref_so_file, long img_size);
bool difftest_check();
void difftest_step();
void diff_cpdutreg2ref();
#endif

#endif