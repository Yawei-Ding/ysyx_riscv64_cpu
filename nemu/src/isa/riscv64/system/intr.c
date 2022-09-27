#include <isa.h>
#include "../local-include/reg.h"

word_t isa_raise_intr(word_t NO, vaddr_t epc) {
  // Trigger an interrupt/exception with ``NO'', return the address of the interrupt/exception vector.
#ifdef CONFIG_ETRACE
  printf("etrace detect interrupt/exception: mepc==%lx, mcause==%lx, mtvec==%lx\n",epc,NO,csr(mtvec));
#endif
  word_t i_mstatus = csr(mstatus);
  csr(mstatus) = (SEXT(BITS(i_mstatus, 63, 13), 51) << 13) | (BITS(3, 1, 0) << 11) | (BITS(i_mstatus, 10, 8) << 8) | (BITS(i_mstatus, 3, 3) << 7)  \
                    | (BITS(i_mstatus, 6, 4) << 4) | (BITS(0, 1, 1) << 3) | (BITS(i_mstatus, 2, 0)) ;
  //printf("before/after ecall mstatus == %lx, %lx\n", i_mstatus, csr(mstatus));
  csr(mepc)   = epc;  // PC -> CSR[mepc];
  csr(mcause) = NO;   // NO -> CSR[mcause];
  return csr(mtvec);  // CSR[mtvec] -> handler_addr;
}

word_t isa_mret() {
  word_t i_mstatus = csr(mstatus);
  csr(mstatus) = (SEXT(BITS(i_mstatus, 63, 13), 51) << 13) | (BITS(0, 1, 0) << 11) | (BITS(i_mstatus, 10, 8) << 8) | (BITS(1, 0, 0) << 7)  \
                    | (BITS(i_mstatus, 6, 4) << 4) | (BITS(i_mstatus, 7, 7) << 3) | (BITS(i_mstatus, 2, 0)) ;
  //printf("before/after mret mstatus == %lx, %lx\n", i_mstatus, csr(mstatus));
  return csr(mepc); 
}

word_t isa_query_intr() {
  return INTR_EMPTY;
}
