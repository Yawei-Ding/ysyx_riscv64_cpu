#include "include/include.h"
#include <dlfcn.h>

typedef struct {
  uint64_t x[32];
  uint64_t pc;
} regfile;

bool checkregs(regfile *ref, regfile *dut);
regfile pack_dut_regfile(uint64_t *dut_reg,uint64_t pc);

enum { DIFFTEST_TO_DUT, DIFFTEST_TO_REF };
void (*ref_difftest_memcpy)(uint64_t addr, void *buf, size_t n, bool direction) = NULL;
void (*ref_difftest_regcpy)(void *dut, bool direction) = NULL;
void (*ref_difftest_exec)(uint64_t n) = NULL;
void (*ref_difftest_raise_intr)(uint64_t NO) = NULL;

uint64_t *dut_reg = NULL;

void difftest_init(char *ref_so_file, long img_size) {
  assert(ref_so_file != NULL);

  void *handle;
  handle = dlopen(ref_so_file, RTLD_LAZY);
  assert(handle);

  ref_difftest_memcpy = (void (*)(uint64_t addr, void *buf, size_t n, bool direction))dlsym(handle , "difftest_memcpy");
  assert(ref_difftest_memcpy);

  ref_difftest_regcpy = (void (*)(void *dut, bool direction))dlsym(handle, "difftest_regcpy");
  assert(ref_difftest_regcpy);

  ref_difftest_exec = (void (*)(uint64_t n))dlsym(handle, "difftest_exec");
  assert(ref_difftest_exec);

  ref_difftest_raise_intr = (void (*)(uint64_t NO))dlsym(handle, "difftest_raise_intr");
  assert(ref_difftest_raise_intr);

  void (*ref_difftest_init)() = (void (*)())dlsym(handle, "difftest_init");
  assert(ref_difftest_init);

  ref_difftest_init();
  ref_difftest_memcpy(PMEM_START,guest_to_host(PMEM_START), img_size, DIFFTEST_TO_REF);

  regfile dut = pack_dut_regfile(dut_reg, INST_START);
  ref_difftest_regcpy(&dut, DIFFTEST_TO_REF);
}

bool difftest_check(uint64_t pc) {
  regfile ref,dut;
  ref_difftest_regcpy(&ref, DIFFTEST_TO_DUT);
  dut = pack_dut_regfile(dut_reg,pc);
  return checkregs(&ref, &dut);
}

void difftest_step() {
  ref_difftest_exec(1);
}
 
bool checkregs(regfile *ref, regfile *dut) {
  if(ref->pc != dut->pc){
    printf("reg pc is diff: ref = %lx, dut = %lx\n",ref->pc,dut->pc);
    return false;
  }
  for (int i = 0; i < 32; i++) {
    if(ref->x[i] != dut->x[i]){
      printf("pc = 0x%lx, reg x[%d] is diff: ref = %lx, dut = %lx\n",dut->pc,i,ref->x[i],dut->x[i]);
      return false;
    }
  }
  return true;
}

regfile pack_dut_regfile(uint64_t *dut_reg,uint64_t pc) {
  regfile dut;
  for (int i = 0; i < 32; i++) {
    dut.x[i] = dut_reg[i];
  }
  dut.pc = pc;
  return dut;
}
