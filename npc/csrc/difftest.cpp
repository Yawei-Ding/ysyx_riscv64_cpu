#include "include/include.h"
#include <dlfcn.h>

#ifdef  DIFFTEST_ON

extern uint64_t *dut_reg;
extern uint64_t dut_pc;

enum { DIFFTEST_TO_DUT, DIFFTEST_TO_REF };
void (*ref_difftest_memcpy)(uint64_t addr, void *buf, size_t n, bool direction) = NULL;
void (*ref_difftest_regcpy)(void *dut, bool direction) = NULL;
void (*ref_difftest_exec)(uint64_t n) = NULL;
void (*ref_difftest_raise_intr)(uint64_t NO) = NULL;
void cp2ref_memory(char *img_file);

void difftest_init(char *ref_so_file, char *img_file) {
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
  cp2ref_memory(img_file);

  regfile dut = pack_dut_regfile(dut_reg, INST_START);
  ref_difftest_regcpy(&dut, DIFFTEST_TO_REF);
}

bool difftest_check() {
  regfile ref,dut;
  ref_difftest_regcpy(&ref, DIFFTEST_TO_DUT);
  dut = pack_dut_regfile(dut_reg,dut_pc);
  return checkregs(&ref, &dut);
}

void difftest_step() {
  ref_difftest_exec(1);
}

void cp2ref_memory(char *img_file) {

  // 1. get size of img file: /////////////////////////////////////////
  if (img_file == NULL) {
    printf("No image is given. Use the default build-in image.\n");
    return ;
  }
  FILE *fp = fopen(img_file, "rb");
  if(fp == NULL){
    printf("Can not open '%s'\n", img_file);
    assert(0); 
  }
  fseek(fp, 0, SEEK_END); // move cur to end.
  long img_size = ftell(fp);

  // 2. read data to mem, and move to difftest :///////////////////////
  uint8_t* ptr = (uint8_t*)malloc(img_size);
  fseek(fp, 0, SEEK_SET);
  int ret = fread(ptr, img_size, 1, fp);
  assert(ret == 1);
  ref_difftest_memcpy(PMEM_START,ptr, img_size, DIFFTEST_TO_REF);

  // 3. close file, and clear mem://///////////////////////////////////
  fclose(fp);
  free(ptr);
}

#endif