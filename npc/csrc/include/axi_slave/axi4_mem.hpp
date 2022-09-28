#ifndef AXI4_MEM
#define AXI4_MEM

#include "axi4_slave.hpp"
#include "memory/paddr.h"
#include <fstream>
#include <iostream>


template <unsigned int A_WIDTH = 64, unsigned int D_WIDTH = 64, unsigned int ID_WIDTH = 4>
class axi4_mem : public axi4_slave<A_WIDTH,D_WIDTH,ID_WIDTH>  {
    public:
        axi4_mem() {
        }
        ~axi4_mem() {
        }

    protected:
        axi_resp do_read(uint64_t start_addr, uint64_t size, uint8_t* buffer) {
            word_t data = paddr_read(start_addr, (int)size);
            memcpy(buffer,&data,size);
            return RESP_OKEY;
        }
        axi_resp do_write(uint64_t start_addr, uint64_t size, const uint8_t* buffer) {
            // printf("do_write at addr: %lx, size:%d\n",start_addr, size);
            word_t data;
            memcpy(&data,buffer,size);
            paddr_write(start_addr, (int)size, data);
            return RESP_OKEY;
        }
};

#endif