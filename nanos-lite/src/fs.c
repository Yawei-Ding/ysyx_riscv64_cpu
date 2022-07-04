#include <fs.h>

size_t ramdisk_read(void *buf, size_t offset, size_t len);
size_t ramdisk_write(const void *buf, size_t offset, size_t len);
size_t serial_write(const void *buf, size_t offset, size_t len);

typedef size_t (*ReadFn) (void *buf, size_t offset, size_t len);
typedef size_t (*WriteFn) (const void *buf, size_t offset, size_t len);

typedef struct {
  char *name;
  size_t size;
  size_t disk_offset;
  ReadFn read;
  WriteFn write;
} Finfo;

enum {FD_STDIN, FD_STDOUT, FD_STDERR, FD_FB};

size_t invalid_read(void *buf, size_t offset, size_t len) {
  panic("should not reach here");
  return 0;
}

size_t invalid_write(const void *buf, size_t offset, size_t len) {
  panic("should not reach here");
  return 0;
}

/* This is the information about all files in disk. */
static Finfo file_table[] __attribute__((used)) = {
  [FD_STDIN]  = {"stdin", 0, 0, invalid_read, invalid_write},
  [FD_STDOUT] = {"stdout", 0, 0, invalid_read, serial_write},
  [FD_STDERR] = {"stderr", 0, 0, invalid_read, serial_write},
#include "files.h"
};

void init_fs() {
  // TODO: initialize the size of /dev/fb
}

char* getFinfoName(int i){
  return file_table[i].name;
}

#define TABLE_LEN (int)(sizeof(file_table) / sizeof(Finfo))

size_t open_offset = 0;

int fs_open(const char *pathname, int flags, int mode){
  for(int i=0; i<TABLE_LEN; i++){
    if(strcmp(file_table[i].name,pathname)==0){
      open_offset = 0;
      return i;
    }
  }
  assert(0); // program should not reach this line!
  return -1;
}

size_t fs_read(int fd, void *buf, size_t len){
  size_t f_size = file_table[fd].size;
  if(open_offset >= f_size){
    return -1;
  }
  if(open_offset + len > f_size){
    len = f_size - open_offset;
  }
  ramdisk_read(buf, file_table[fd].disk_offset + open_offset, len);
  open_offset = open_offset + len;
  return len;
}

size_t fs_write(int fd, const void *buf, size_t len){
  if(file_table[fd].write != NULL){
    (file_table[fd].write)(buf,0,len);
    return len;
  }
  else{
    size_t f_size = file_table[fd].size;
    if(open_offset >= f_size){
      return -1;
    }
    if(open_offset + len > f_size){
      len = f_size - open_offset;
    }
    ramdisk_write(buf, file_table[fd].disk_offset + open_offset, len);
    open_offset = open_offset + len;
    return len;
  }
}

size_t fs_lseek(int fd, size_t offset, int whence){
  size_t f_size = file_table[fd].size;
  switch (whence)
  {
    case SEEK_SET: if(offset <= f_size) {open_offset = offset; return open_offset;} else{ return -1;} break;
    case SEEK_CUR: if(open_offset + offset <= f_size) {open_offset = open_offset + offset; return open_offset;} else{ return -1;} break; 
    case SEEK_END: if((signed)offset <= 0)  { open_offset = f_size + offset; return open_offset;} else { return -1; } break;
    default: panic("check your input whence for lseek"); break;
  }
}

int fs_close(int fd){
  open_offset = 0;
  return 0;
}