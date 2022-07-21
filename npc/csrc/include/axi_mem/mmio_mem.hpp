#ifndef MMIO_MEM_H
#define MMIO_MEM_H

#include "axi4.hpp"
#include "mmio_dev.hpp"

#include <fstream>
#include <iostream>

class mmio_mem : public mmio_dev  {
    public:
        mmio_mem(size_t size_bytes) {
            mem = new unsigned char[size_bytes];
            mem_size = size_bytes;
        }
        mmio_mem(size_t size_bytes, const unsigned char *init_binary, size_t init_binary_len): mmio_mem(size_bytes) {
            // Initalize memory 
            assert(init_binary_len <= size_bytes);
            memcpy(mem,init_binary,init_binary_len);
        }
        mmio_mem(size_t size_bytes, const char *init_file): mmio_mem(size_bytes) {
            std::ifstream file(init_file,std::ios::in | std::ios::binary | std::ios::ate);
            size_t file_size = file.tellg();
            file.seekg(std::ios_base::beg);
            if (file_size > mem_size) {
                std::cerr << "mmio_mem size is not big enough for init file." << std::endl;
                file_size = size_bytes;
            }
            file.read((char*)mem,file_size);
        }
        ~mmio_mem() {
            delete [] mem;
        }
        bool do_read(uint64_t start_addr, uint64_t size, uint8_t* buffer) {
            if (start_addr + size <= mem_size) {
                memcpy(buffer,&mem[start_addr],size);
                return true;
            }
            else return false;
        }
        bool do_write(uint64_t start_addr, uint64_t size, const uint8_t* buffer) {
            if (start_addr + size <= mem_size) {
                memcpy(&mem[start_addr],buffer,size);
                return true;
            }
            else return false;
        }
    private:
        unsigned char *mem;
        size_t mem_size;
};

#endif