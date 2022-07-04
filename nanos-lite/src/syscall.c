#include <common.h>
#include <fs.h>

#define strace 1 // close strace by comment this line.

void sys_exit(Context *c);
void sys_yield(Context *c);
void sys_open(Context *c);
void sys_read(Context *c);
void sys_write(Context *c);
void sys_close(Context *c);
void sys_lseek(Context *c);
void sys_brk(Context *c);
char* get_syscall_name(uintptr_t type);


void do_syscall(Context *c) {
  uintptr_t type = c->GPR1;

#ifdef strace
  uintptr_t a[3]={c->GPR2,c->GPR3,c->GPR4};
#endif 

  switch (type) {
    case SYS_exit         : sys_exit(c);  break;
    case SYS_yield        : sys_yield(c); break;
    case SYS_open         : sys_open(c);  break;
    case SYS_read         : sys_read(c);  break;
    case SYS_write        : sys_write(c); break;
    case SYS_kill         :               break;
    case SYS_getpid       :               break;
    case SYS_close        : sys_close(c); break;
    case SYS_lseek        : sys_lseek(c); break;
    case SYS_brk          : sys_brk(c);   break;
    case SYS_fstat        :               break;
    case SYS_time         :               break;
    case SYS_signal       :               break;
    case SYS_execve       :               break;
    case SYS_fork         :               break;
    case SYS_link         :               break;
    case SYS_unlink       :               break;
    case SYS_wait         :               break;
    case SYS_times        :               break;
    case SYS_gettimeofday :               break;
    default: panic("Unhandled syscall ID = %d", type);
  }

#ifdef strace
  char* getFinfoName(int i);
  if(type == SYS_open|| type == SYS_read || type == SYS_write || type == SYS_close || type == SYS_lseek){
    if(type == SYS_open) printf("strace detect file %s is doing %s :",a[0], get_syscall_name(type));
    else printf("strace detect file %s is doing %s :",getFinfoName(a[0]), get_syscall_name(type));
  }
  else{
    printf("strace detect syscall: %s, ",get_syscall_name(type));
  }
  printf("input regs a0=0x%lx, a1=0x%lx, a2=0x%lx, return value a0=0x%lx.\n",a[0],a[1],a[2],c->GPRx);
#endif

}

void sys_exit(Context *c){
  c->GPRx = 0;
  halt(c->GPRx);
}

void sys_yield(Context *c){
  yield();    // yield by am.
  c->GPRx = 0;
}

void sys_open(Context *c){
  c->GPRx = fs_open((const char *)c->GPR2,c->GPR3,c->GPR4);
}

void sys_read(Context *c){
  c->GPRx = fs_read(c->GPR2,(void *)c->GPR3,c->GPR4);
}

void sys_write(Context *c){
  c->GPRx = fs_write(c->GPR2,(void *)c->GPR3,c->GPR4);
}

void sys_close(Context *c){
  c->GPRx = fs_close(c->GPR2);
}

void sys_lseek(Context *c){
  c->GPRx = fs_lseek(c->GPR2,c->GPR3,c->GPR4);
}

void sys_brk(Context *c){
  c->GPRx = 0;
}

char* get_syscall_name(uintptr_t type){
  static char SyscallInfo[20];
  switch (type) {
    case SYS_exit         : strcpy(SyscallInfo,"sys_exit");         break;
    case SYS_yield        : strcpy(SyscallInfo,"sys_yield");        break;
    case SYS_open         : strcpy(SyscallInfo,"sys_open");         break;
    case SYS_read         : strcpy(SyscallInfo,"sys_read");         break;
    case SYS_write        : strcpy(SyscallInfo,"sys_write");        break;
    case SYS_kill         : strcpy(SyscallInfo,"sys_kill");         break;
    case SYS_getpid       : strcpy(SyscallInfo,"sys_getpid");       break;
    case SYS_close        : strcpy(SyscallInfo,"sys_close");        break;
    case SYS_lseek        : strcpy(SyscallInfo,"sys_lseek");        break;
    case SYS_brk          : strcpy(SyscallInfo,"sys_brk");          break;
    case SYS_fstat        : strcpy(SyscallInfo,"sys_fstat");        break;
    case SYS_time         : strcpy(SyscallInfo,"sys_time");         break;
    case SYS_signal       : strcpy(SyscallInfo,"sys_signal");       break;
    case SYS_execve       : strcpy(SyscallInfo,"sys_execve");       break;
    case SYS_fork         : strcpy(SyscallInfo,"sys_fork");         break;
    case SYS_link         : strcpy(SyscallInfo,"sys_link");         break;
    case SYS_unlink       : strcpy(SyscallInfo,"sys_unlink");       break;
    case SYS_wait         : strcpy(SyscallInfo,"sys_wait");         break;
    case SYS_times        : strcpy(SyscallInfo,"sys_times");        break;
    case SYS_gettimeofday : strcpy(SyscallInfo,"sys_gettimeofday"); break;
    default: panic("Unhandled syscall ID = %d", type);
  }
  return SyscallInfo;
}
