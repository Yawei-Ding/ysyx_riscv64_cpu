#include <common.h>

void init_monitor(int, char *[]);
void am_init_monitor();
void engine_start();
int is_exit_status_bad();
void init_sdb();    //used for test 正则表达式计算
//word_t expr(char *e, bool *success); //used for test 正则表达式计算

int main(int argc, char *argv[]) {
  /* Initialize the monitor. */
#ifdef CONFIG_TARGET_AM
  am_init_monitor();
#else
  init_monitor(argc, argv);
#endif

  //-------------------- test for 正则表达式计算 start------------------
  // char buffer[65536];
  // FILE *fp = fopen("/home/dingyawei/ysyx-workbench/nemu/tools/gen-expr/input.txt", "r");
  // assert(fp != NULL);
  // init_sdb();
  // while(fgets(buffer,65536,fp)!=NULL){
  //   bool success = true;
  //   word_t codeanswer;
  //   char *fileanswer = strtok(buffer, " "); // 第一个空格的位置区分文件中的输出值
  //   char *expression = strtok(NULL, "\n");        // 表达式的起始地址
  //   codeanswer = expr(expression, &success);
  //   if(success)
  //     printf("expr = %s, fileanswer = %s, codeanswer = %ld\n",expression,fileanswer,codeanswer);
  //   else
  //     printf("test error!");
  // }
  // fclose(fp); 
  //-------------------- test for 正则表达式计算 end--------------------
  
  /* Start engine. */
  engine_start();

  return is_exit_status_bad();
}
