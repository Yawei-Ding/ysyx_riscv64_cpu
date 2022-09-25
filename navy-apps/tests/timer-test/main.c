#include <stdio.h>
#include "NDL.h"

int main() {
  int i=0;
  while(NDL_GetTicks()/500){
    printf("%d time has gone 0.5s\n",i);
    i++;
  }
  return 0;
}
