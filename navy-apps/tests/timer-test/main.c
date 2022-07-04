#include <stdio.h>
#include "NDL.h"

int main() {
  int old_delay=0,delay=0,i=0;
  while(1){
    uint32_t us = NDL_GetTicks();
    //printf("navy get sec:%d.%d\n",now.tv_usec/1000000,now.tv_usec/100000);
    old_delay = delay;
    delay = us/500000;
    if(delay!=old_delay){
      printf("%d time has gone 0.5s\n",i);
      i++;
    }
  }
  return 0;
}
