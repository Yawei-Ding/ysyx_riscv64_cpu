#ifndef _INCLUDE_H_
#define _INCLUDE_H_

#include "Vtop.h"
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

#define PMEM_START 0x80000000
#define PMEM_END   0x87ffffff
#define PMEM_MSIZE (PMEM_END+1-PMEM_START)

uint64_t pmem_read(uint64_t addr, int len);
void pmem_write(uint64_t addr, uint64_t data, int len);
void difftest_init(char *ref_so_file, long img_size);
void npc_init(int argc, char *argv[]);

#endif