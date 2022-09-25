#ifndef _MYFLOAT_H
#define _MYFLOAT_H

#ifdef __NAVY__
#define USE_FIXEDPT

#include "fixedptc.h"
typedef fixedpt             FLOAT, *LPFLOAT;

#define FLOATconst(f) fixedpt_rconst(f)

static inline int FLOATtoInt(FLOAT a) {
  return fixedpt_toint(a);
}

static inline FLOAT FLOATfromInt(int a) {
  return fixedpt_fromint(a);
}

static inline FLOAT FLOATmuli(FLOAT a, int b) {
  return fixedpt_muli(a, b);
}

static inline FLOAT FLOATdivi(FLOAT a, int b) {
  return fixedpt_divi(a, b);
}

static inline FLOAT FLOATpow(FLOAT a, FLOAT b) {
  return fixedpt_pow(a, b);
}

#else
#include <math.h>
typedef float               FLOAT, *LPFLOAT;

#define FLOATconst(f) f

static inline int FLOATtoInt(FLOAT a) {
  return a;
}

static inline FLOAT FLOATfromInt(int a) {
  return a;
}

static inline FLOAT FLOATmuli(FLOAT a, int b) {
  return a * b;
}

static inline FLOAT FLOATdivi(FLOAT a, int b) {
  return a / b;
}

static inline FLOAT FLOATpow(FLOAT a, FLOAT b) {
  return pow(a, b);
}
#endif

#endif
