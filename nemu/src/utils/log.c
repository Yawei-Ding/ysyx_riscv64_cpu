#include <common.h>

extern uint64_t g_nr_guest_inst;
FILE *log_fp = NULL;

void init_log(const char *log_file) {
  log_fp = stdout;
  if (log_file != NULL) {
    FILE *fp = fopen(log_file, "w");
    Assert(fp, "Can not open '%s'", log_file);
    log_fp = fp;
  }
  Log("Log is written to %s", log_file ? log_file : "stdout");
#ifdef CONFIG_ITRACE_COND
  void init_iringbuf(); // declaration
  init_iringbuf(); //add by dingyawei , init iringbuf;
#endif
}

bool log_enable() {
  return MUXDEF(CONFIG_TRACE, (g_nr_guest_inst >= CONFIG_TRACE_START) &&
         (g_nr_guest_inst <= CONFIG_TRACE_END), false);
}

//以下代码全部用来管理iringbuf:
typedef struct {
  bool used;
  char* logbuf;
}RB;

#define MAX_BUF 10
static RB iringbuf[MAX_BUF];
static int bufindex= 0;// used for next add, [0,9]

void init_iringbuf(){
  for(int i=0;i<MAX_BUF;i++){
    iringbuf[i].used = false;
    iringbuf[i].logbuf = NULL;
  }
}

void add_iringbuf(char *newlog){
  if(iringbuf[bufindex].used == false){ //还没用，标记为使用。
    iringbuf[bufindex].used = true;
  }
  else{ //已经用了，把先前的free掉。
    free(iringbuf[bufindex].logbuf);
  }
  iringbuf[bufindex].logbuf = (char *) malloc(sizeof(char)*(strlen(newlog)+1));
  strcpy(iringbuf[bufindex].logbuf,newlog);
  bufindex++;
  if(bufindex >= MAX_BUF){
    bufindex = bufindex-MAX_BUF;
  }
}

void print_iringbuf(){
  //第一个for循环打印 [index , MAX_BUF]
  for(int i=bufindex; i<MAX_BUF; i++){
    if(iringbuf[i].used == true){ 
      printf("%s\n", iringbuf[i].logbuf);
      free(iringbuf[i].logbuf);
    }
  }
  //第二个for循环打印 [0 , index-1]
  for(int i=0; i<bufindex; i++){
    if(iringbuf[i].used == true){ 
      printf("%s\n", iringbuf[i].logbuf);
      free(iringbuf[i].logbuf);
    }
  }
}