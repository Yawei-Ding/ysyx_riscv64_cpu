#ifndef __COMMON_H__
#define __COMMON_H__

#include <stdint.h>
#include <stdbool.h>
#include <string.h>

#include <macro.h>

#ifdef CONFIG_TARGET_AM
#include <klib.h>
#else
#include <assert.h>
#include <stdlib.h>
#endif

#if CONFIG_MBASE + CONFIG_MSIZE > 0x100000000ul
#define PMEM64 1
#endif

typedef __uint128_t word_t;
typedef __uint128_t sword_t;


#define FMT_WORD MUXDEF(CONFIG_ISA64, "0x%016lx", "0x%08x")

typedef uint64_t vaddr_t;
typedef uint64_t paddr_t;

#define FMT_PADDR MUXDEF(PMEM64, "0x%016lx", "0x%08x")
typedef uint16_t ioaddr_t;

#include <debug.h>

#define __GUEST_ISA__ riscv64
#define CONFIG_ISA64 1
#define CONFIG_ISA_riscv64 1
#define CONFIG_ISA "riscv64"
#define CONFIG_CC_GCC 1
#define CONFIG_MODE_SYSTEM 1
#define CONFIG_TARGET_NATIVE_ELF 1
#define CONFIG_RT_CHECK 1
#define CONFIG_TRACE 1
#define CONFIG_TRACE_START 0
#define CONFIG_TRACE_END 10000
#define CONFIG_TRACE_EXECCOUNT 1
#define CONFIG_ITRACE 1
#define CONFIG_ITRACE_COND "true"
#define CONFIG_PC_RESET_OFFSET 0x0
#define CONFIG_MSIZE 0x8000000
#define CONFIG_PMEM_GARRAY 1
#define CONFIG_MEM_RANDOM 1
#define CONFIG_MBASE 0x80000000

#define CONFIG_RTOS 1
#define CONFIG_SOC_SIMULATOR 1

#define CONFIG_DEVICE 1
#define CONFIG_HAS_TIMER 1
#define CONFIG_TIMER_GETTIMEOFDAY 1
#define CONFIG_HAS_SERIAL 1
#define CONFIG_HAS_KEYBOARD 1
#define CONFIG_HAS_VGA 1
//#define CONFIG_HAS_DISK 1
#define CONFIG_HAS_AUDIO 1

#define DEVICE_BASE 0x10000000
#define MMIO_BASE   0x10000000

#define CONFIG_RTC_MMIO (DEVICE_BASE + 0x0002000)
#define CONFIG_SERIAL_MMIO (DEVICE_BASE + 0x0000000)
#define CONFIG_I8042_DATA_MMIO (DEVICE_BASE + 0x0001000)
#define CONFIG_FB_ADDR (MMIO_BASE   + 0x1000000)
#define CONFIG_VGA_CTL_MMIO (DEVICE_BASE + 0x0003000)
#define CONFIG_VGA_SHOW_SCREEN 1
#define CONFIG_VGA_SIZE_400x300 1
#define CONFIG_SDCARD_CTL_MMIO 0xa3000000
#define CONFIG_SDCARD_IMG_PATH "The path of sdcard image"
#define CONFIG_AUDIO_CTL_MMIO (DEVICE_BASE + 0x0004000)
#define CONFIG_SB_ADDR (MMIO_BASE   + 0x1200000)
#define CONFIG_SB_SIZE 0x10000

#endif
