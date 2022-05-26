#include "Vtop.h"
#include "Vtop__Dpi.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

typedef uint32_t paddr_t;
typedef uint64_t word_t;
#define PMEM_START 0x80000000
#define PMEM_END   0x87ffffff
#define PMEM_MSIZE (PMEM_END+1-PMEM_START)

//uint32_t memory[10] = {0xffc10113,0x100073,0x100073,0x100073,0x100073};
static uint8_t pmem[PMEM_MSIZE] = {};
uint8_t* guest_to_host(paddr_t paddr) { return pmem + paddr - PMEM_START; }
paddr_t host_to_guest(uint8_t *haddr) { return haddr - pmem + PMEM_START; }

static void pmem_write(paddr_t addr, int len, word_t data) {
  uint8_t * paddr = guest_to_host(addr);
  switch (len) {
    case 1: *(uint8_t  *)paddr = data; return;
    case 2: *(uint16_t *)paddr = data; return;
    case 4: *(uint32_t *)paddr = data; return;
    case 8: *(uint64_t *)paddr = data; return;
  }
}

static word_t pmem_read(paddr_t addr, int len) {
  uint8_t * paddr = (uint8_t*) guest_to_host(addr);
  switch (len) {
    case 1: return *(uint8_t  *)paddr;
    case 2: return *(uint16_t *)paddr;
    case 4: return *(uint32_t *)paddr;
    case 8: return *(uint64_t *)paddr;
  }
  assert(0);
}

static long load_img(char *img_file) {
  if (img_file == NULL) {
    printf("No image is given. Use the default build-in image.\n");
    return 4096; // built-in image size
  }

  FILE *fp = fopen(img_file, "rb");
  if(fp == NULL){
    printf("Can not open '%s'\n", img_file);
    assert(0); 
  }

  fseek(fp, 0, SEEK_END); // move cur to end.
  long size = ftell(fp);

  printf("The image is %s, size = %ld\n", img_file, size);

  fseek(fp, 0, SEEK_SET);
  int ret = fread(pmem, size, 1, fp);
  assert(ret == 1);

  //for(uint32_t i=0;i<size;i=i+4)
  //  printf("0x%08x, 0x%08lx\n",PMEM_START+i,pmem_read(PMEM_START+i,4));

  fclose(fp);
  return size;
}

void step_and_dump_wave(VerilatedContext* contextp,VerilatedVcdC* tfp,Vtop* top)
{
  top->eval();
  contextp->timeInc(1);
  tfp->dump(contextp->time());
}

svBit check_finsih(int inst){
  if(inst == 0x100073) //ebreak;
    return 1;
  else 
    return 0;
}

int main(int argc, char *argv[]) {
  ////////////////////// load ins to mem: //////////////////////
  load_img(argv[1]);
  ////////////////////// verilator init: //////////////////////
  VerilatedContext* contextp = new VerilatedContext;
  VerilatedVcdC* tfp = new VerilatedVcdC;
  Vtop* top = new Vtop;
  
  contextp->traceEverOn(true);
  top->trace(tfp, 0); // Trace 0 levels of hierarchy (or see below)
  tfp->open("dump.vcd");

  ////////////////////// verilator doing: //////////////////////
  top->clk = 0;
  top->rst_n = 1;
  step_and_dump_wave(contextp,tfp,top);
  while (!contextp->gotFinish())
  {
    top->clk = 1 ^ top->clk;
    if(top->pc >= PMEM_START && top->pc <= PMEM_END  ){
      top->inst = pmem_read(top->pc,4);
    }
    printf("pc = %lx, ins = %x\n", top->pc, top->inst);
    step_and_dump_wave(contextp,tfp,top);
  }
  ////////////////////// exit: //////////////////////
  step_and_dump_wave(contextp,tfp,top);
  tfp->close();
  delete tfp;
  delete top;
  delete contextp;

  return 0;
}
