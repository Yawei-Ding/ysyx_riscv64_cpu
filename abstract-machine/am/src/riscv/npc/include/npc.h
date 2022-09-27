#ifndef NPC_H__
#define NPC_H__

#include <klib-macros.h>
#include <riscv/riscv.h>

#define DEVICE_BASE 0x10000000
#define MMIO_BASE   0x10000000

#define SERIAL_PORT     (DEVICE_BASE + 0x0000000)
#define KBD_ADDR        (DEVICE_BASE + 0x0001000)
#define RTC_ADDR        (DEVICE_BASE + 0x0002000)
#define VGACTL_ADDR     (DEVICE_BASE + 0x0003000)
#define AUDIO_ADDR      (DEVICE_BASE + 0x0004000)
#define DISK_ADDR       (DEVICE_BASE + 0x0005000)
#define FB_ADDR         (MMIO_BASE   + 0x1000000)
#define AUDIO_SBUF_ADDR (MMIO_BASE   + 0x1200000)

extern char _pmem_start;
#define PMEM_SIZE (128 * 1024 * 1024)
#define PMEM_END  ((uintptr_t)&_pmem_start + PMEM_SIZE)
#define NEMU_PADDR_SPACE \
  RANGE(&_pmem_start, PMEM_END), \
  RANGE(FB_ADDR, FB_ADDR + 0x200000), \
  RANGE(MMIO_BASE, MMIO_BASE + 0x1000) /* serial, rtc, screen, keyboard */

typedef uintptr_t PTE;

#define PGSIZE    4096

#endif

