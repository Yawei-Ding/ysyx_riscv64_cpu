#include <isa.h>
#include "../local-include/reg.h"

word_t isa_raise_intr(word_t NO, vaddr_t epc) {
  // Trigger an interrupt/exception with ``NO'', return the address of the interrupt/exception vector.
#ifdef CONFIG_ETRACE
  printf("etrace detect interrupt/exception: mepc==%lx, mcause==%lx, mtvec==%lx\n",epc,NO,csr(mtvec));
#endif
  csr(mepc)   = epc;  // PC -> CSR[mepc];
  csr(mcause) = NO;   // NO -> CSR[mcause];
  return csr(mtvec);  // CSR[mtvec] -> handler_addr;
}

word_t isa_query_intr() {
  return INTR_EMPTY;
}
