#include "Vtop.h"
#include "Vtop__Dpi.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

extern uint8_t pmem[PMEM_MSIZE];

uint64_t pmem_read(uint64_t addr, int len);
void rtl_pmem_write(uint64_t waddr, uint64_t wdata, uint8_t wmask);
void rtl_pmem_read(uint64_t raddr,uint64_t *rdata);

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

svBit check_finsih(int ins){
  if(ins == 0x100073) //ebreak;
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
      top->ins = pmem_read(top->pc,4);
    }
    printf("pc = 0x%lx, ins = 0x%x\n", top->pc, top->ins);
    step_and_dump_wave(contextp,tfp,top);
    if(top->pc == 0x8000002c)
      break;
  }
  ////////////////////// exit: //////////////////////
  step_and_dump_wave(contextp,tfp,top);
  tfp->close();
  delete tfp;
  delete top;
  delete contextp;

  return 0;
}
