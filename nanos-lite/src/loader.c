#include <proc.h>
#include <elf.h>
#include <stdio.h>

#ifdef __LP64__
# define Elf_Ehdr Elf64_Ehdr
# define Elf_Phdr Elf64_Phdr
#else
# define Elf_Ehdr Elf32_Ehdr
# define Elf_Phdr Elf32_Phdr
#endif

#if defined(__ISA_AM_NATIVE__)
# define EXPECT_TYPE EM_X86_64
#elif defined(__ISA_X86__)
# define EXPECT_TYPE EM_386   // not sure, please check by yourself.
#elif defined(__ISA_MIPS32__)
# define EXPECT_TYPE EM_MIPS  // not sure, please check by yourself.
#elif defined(__ISA_RISCV32__) || defined(__ISA_RISCV64__)
# define EXPECT_TYPE EM_RISCV
#else
# error Unsupported ISA
#endif

size_t ramdisk_read(void *buf, size_t offset, size_t len);
static uintptr_t loader(PCB *pcb, const char *filename) {

  // 1. read elf head:
  Elf_Ehdr *elf_head = (Elf_Ehdr*)malloc(sizeof(Elf_Ehdr)); 
  ramdisk_read(elf_head,0,sizeof(Elf_Ehdr));
  assert(*(uint32_t *)elf_head->e_ident == 0x464c457f);  // check reading file is elf.
  assert(elf_head->e_machine == EXPECT_TYPE);            // check architecture.

  // 2. read program headers, remeber pro_head is a struct pointer!!
  Elf_Phdr *pro_head = (Elf_Phdr*)malloc(sizeof(Elf_Phdr)*elf_head->e_phnum); 
  ramdisk_read(pro_head,sizeof(Elf_Ehdr),sizeof(Elf_Phdr)*elf_head->e_phnum);

  for(Elf_Phdr *p=pro_head; p<pro_head+elf_head->e_phnum; p++){

    // load text/rodata/data segment into mem:
    ramdisk_read((void*)(p->p_vaddr), p->p_offset, p->p_filesz);
    
    // init bss segment(set to zero):
    memset((void *)(p->p_vaddr+p->p_filesz), 0, p->p_memsz - p->p_filesz);
  }

  return elf_head->e_entry;
}

void naive_uload(PCB *pcb, const char *filename) {
  uintptr_t entry = loader(pcb, filename);
  Log("Jump to entry = %p", entry);
  ((void(*)())entry) ();
}

