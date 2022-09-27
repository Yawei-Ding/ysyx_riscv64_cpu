#include "include.h"
#include <memory/host.h>
#include <memory/paddr.h>
#include <device/mmio.h>

extern regfile dut_reg;

uint8_t pmem[CONFIG_MSIZE] PG_ALIGN = {};

uint8_t* guest_to_host(paddr_t paddr) { return pmem + paddr - CONFIG_MBASE; }
paddr_t host_to_guest(uint8_t *haddr) { return haddr - pmem + CONFIG_MBASE; }

static word_t pmem_read(paddr_t addr, int len) {
  word_t ret = host_read(guest_to_host(addr), len);
  return ret;
}

static void pmem_write(paddr_t addr, int len, word_t data) {
  host_write(guest_to_host(addr), len, data);
}

static void out_of_bound(paddr_t addr) {
  panic("address = " FMT_PADDR " is out of bound of pmem [" FMT_PADDR ", " FMT_PADDR "] at pc = " FMT_WORD,
      addr, (paddr_t)CONFIG_MBASE, (paddr_t)CONFIG_MBASE + CONFIG_MSIZE - 1, dut_reg.pc);
}

word_t real_paddr_read(paddr_t addr, int len) {
  if (likely(in_pmem(addr))) return pmem_read(addr, len);
  IFDEF(CONFIG_DEVICE, return mmio_read(addr, len));
  out_of_bound(addr);
  return 0;
}

word_t paddr_read(paddr_t addr, int len) {
  word_t data = real_paddr_read(addr,len);
#ifdef CONFIG_MTRACE
  printf("tracing read  memory, addr = "FMT_PADDR", data = "FMT_WORD"\n",addr,data);
#endif
  return data;
}

void paddr_write(paddr_t addr, int len, word_t data) {
#ifdef CONFIG_MTRACE
  printf("tracing write memory, addr = "FMT_PADDR", data = "FMT_WORD"\n",addr,data);
#endif
  if (likely(in_pmem(addr))) { pmem_write(addr, len, data); return; }
  IFDEF(CONFIG_DEVICE, mmio_write(addr, len, data); return);
  out_of_bound(addr);
}
