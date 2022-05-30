#include "include/include.h"
#include <dlfcn.h>

enum { DIFFTEST_TO_DUT, DIFFTEST_TO_REF };

void (*ref_difftest_memcpy)(uint64_t addr, void *buf, size_t n, bool direction) = NULL;
void (*ref_difftest_regcpy)(void *dut, bool direction) = NULL;
void (*ref_difftest_exec)(uint64_t n) = NULL;
void (*ref_difftest_raise_intr)(uint64_t NO) = NULL;

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
  //ref_difftest_memcpy(,, img_size, DIFFTEST_TO_REF);
  //ref_difftest_regcpy(&cpu, DIFFTEST_TO_REF);
}

typedef struct {
  uint64_t x[32];
  uint64_t pc;
} regfile;

bool checkregs(regfile *ref, regfile *dut) {
  for (int i = 0; i < 32; i++) {
    if(ref->x[i] != dut->x[i]){
      printf("reg x[%d] is diff: ref = %lx, dut = %lx",i,ref->x[i],dut->x[i]);
      return false;
    }
  }
  if(ref->pc != dut->pc){
    printf("reg pc is diff: ref = %lx, dut = %lx",ref->pc,dut->pc);
    return false;
  }
  return true;
}

void difftest_step(uint64_t pc) {
  regfile ref,dut;
  ref_difftest_exec(1);
  ref_difftest_regcpy(&ref, DIFFTEST_TO_DUT);
  //在这里添加一个 verilator的函数，读入dut的reg信息。
  checkregs(&ref, &dut);
}
