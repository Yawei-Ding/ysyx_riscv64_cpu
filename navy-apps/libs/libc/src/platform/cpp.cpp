#include <stdlib.h>
#include <assert.h>

long __dso_handle = 0;

extern "C" {

void __cxa_pure_virtual() {
  assert(0);
}

};

void *operator new (size_t size) {
  return malloc(size);
}

void *operator new[](size_t size) {
  return malloc(size);
}

void operator delete(void *p) {
  free(p);
}

void operator delete[](void *p) {
  free(p);
}

// See https://en.cppreference.com/w/cpp/memory/new/operator_delete for more details

void operator delete(void *p, size_t sz) {
  free(p);
}

void operator delete[](void *p, size_t sz) {
  free(p);
}
