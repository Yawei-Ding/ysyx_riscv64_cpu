#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <assert.h>
#include <string.h>

// this should be enough
static char buf[65536] = {};
static char code_buf[65536 + 128] = {}; // a little larger than `buf`
static char *code_format =
"#include <stdio.h>\n"
"int main() { "
"  unsigned result = %s; "
"  printf(\"%%u\", result); "
"  return 0; "
"}";

static void gen_num(){
  uint32_t num = rand() % 256;
  if(num == 0) //避免发生除0
    gen_num(); 
  char numstr[10];
  sprintf(numstr, "%u", num);
  strcat(buf,numstr);
}
static void gen_rand_op(){
  uint32_t num = rand() % 10;
  switch (num) {
    case 0: 
    case 1: 
    case 2: 
    case 3: strcat(buf,"+"); break;
    case 4: 
    case 5:
    case 6:
    case 7:
    case 8: strcat(buf,"*"); break;
    case 9: strcat(buf,"/"); break;
  }
}

static void gen_rand_expr(int lastnum) {
  int num = rand() % 3;
  switch (num) {
    case 0: gen_rand_expr(num); gen_rand_op(); gen_rand_expr(num); break;
    case 1: strcat(buf,"("); gen_rand_expr(num); strcat(buf,")"); break;
    case 2: 
      if(lastnum != 2){//上次产生的不是数字，需要先产生一个数字
        gen_num();
      }
      gen_rand_op();
      gen_num();
      break;
  }
}

int main(int argc, char *argv[]) {
  int seed = time(0);
  srand(seed);
  int loop = 1;
  if (argc > 1) {
    sscanf(argv[1], "%d", &loop);
  }
  int i;
  for (i = 0; i < loop; i ++) {
    buf[0]='\0';
    gen_rand_expr(0);

    sprintf(code_buf, code_format, buf);

    FILE *fp = fopen("/tmp/.code.c", "w");
    assert(fp != NULL);
    fputs(code_buf, fp);
    fclose(fp);

    int ret = system("gcc /tmp/.code.c -o /tmp/.expr");
    if (ret != 0) continue;

    fp = popen("/tmp/.expr", "r");
    assert(fp != NULL);

    int result;
    if(fscanf(fp, "%d", &result))
      printf("%u %s\n", result, buf);
    else
      printf("error!");
    pclose(fp);
    
  }
  return 0;
}
