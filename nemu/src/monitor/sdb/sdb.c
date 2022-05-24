#include <isa.h>
#include <cpu/cpu.h>
#include <readline/readline.h>
#include <readline/history.h>
#include "sdb.h"


static int is_batch_mode = false;

void init_regex();
bool new_wp(char *args);
bool free_wp(int delNO);
void wp_display();

word_t paddr_read(paddr_t addr, int len);

static int cmd_help(char *args);
static int cmd_c(char *args);
static int cmd_q(char *args);
static int cmd_si(char *args);
static int cmd_info(char *args);
static int cmd_x(char *args);
static int cmd_p(char *args);
static int cmd_w(char *args);
static int cmd_d(char *args);


static struct {
  const char *name;
  const char *description;
  int (*handler) (char *);
} cmd_table [] = {
  { "help", "Display informations about all supported commands", cmd_help },
  { "c", "Continue the execution of the program", cmd_c },
  { "q", "Exit NEMU", cmd_q },
  { "si", "Step one instruction", cmd_si},
  { "info", "Print register or watchpoint status", cmd_info},
  { "x", "Print memory value ", cmd_x},
  { "p", "Calculate the value of a regular expression", cmd_p},
  { "w", "Create a new watch point with the expression", cmd_w},
  { "d", "Delete a watch point from link list.", cmd_d},
  /* TODO: Add more commands */
};

#define NR_CMD ARRLEN(cmd_table)

/* We use the `readline' library to provide more flexibility to read from stdin. */
static char* rl_gets() {
  static char *line_read = NULL;

  if (line_read) {
    free(line_read);
    line_read = NULL;
  }

  line_read = readline("(nemu) ");

  if (line_read && *line_read) {
    add_history(line_read);
  }

  return line_read;
}

static int cmd_help(char *args) {
  /* extract the first argument */
  char *arg = strtok(NULL, " ");
  int i;

  if (arg == NULL) {
    /* no argument given */
    for (i = 0; i < NR_CMD; i ++) {
      printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
    }
  }
  else {
    for (i = 0; i < NR_CMD; i ++) {
      if (strcmp(arg, cmd_table[i].name) == 0) {
        printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
        return 0;
      }
    }
    printf("Unknown command '%s'\n", arg);
  }
  return 0;
}

static int cmd_c(char *args) {
  cpu_exec(-1);
  return 0;
}

//-------------------- add by dingyawei,start.--------------------------------//

static int cmd_q(char *args) {
  nemu_state.state = NEMU_QUIT;
  return -1;
}

static int cmd_si(char *args) {
  /* extract the first argument */
  char *arg = strtok(NULL, " ");
  char *ptr = NULL;
  uint64_t num = 0;

  if (arg == NULL) {
    //no argument given, step one!
    cpu_exec(1);
  }
  else {
    //Step n times,n is determined by *arg !
    num = strtoul(arg,&ptr,10); 
    if((num == 0) || ((arg+strlen(arg)) != ptr)){
      printf("Check! Execlute times cannot be 0,or other non-numeric letters!\n");
    }
    else{
      cpu_exec(num);
    }
  }
  return 0;
}

static int cmd_info(char *args) {
  if(strcmp(args,"r") == 0){
    isa_reg_display();
  }
  else if (strcmp(args,"w") == 0){
    wp_display(0);
  }
  else{
    printf("check your input cmd,this is not support!!\n");
  }
  return 0;
}

static int cmd_x(char *args) {
  char *argN = strtok(NULL, " ");
  char *argEXPR = strtok(NULL, " ");
  char *ptrN = NULL;
  char *ptrEXPR = NULL;

  /* extract the first argument:N. */
  word_t N = strtoul(argN,&ptrN,10); 
  /* extract the second argument:EXPR,means the start addr of memory. */
  word_t EXPR = strtoul(argEXPR,&ptrEXPR,16); 

  if(((argN+strlen(argN)) != ptrN) || ((argEXPR+strlen(argEXPR)) != ptrEXPR)){
    printf("Check your input cmd,args can not be non-numeric letters!\n");
  }
  
  for(int i=0;i<N;i++){
    word_t paddr = EXPR+i*8;
    printf("0x%lx:\t0x%016lx\n",paddr,paddr_read(paddr,8));
  }
  return 0;
}

static int cmd_p(char *args) {
  bool success;
  word_t EXPR;
  EXPR = expr(args, &success);
  if(success){
    printf("input expression == %ld\n",EXPR);
  }
  else{
    printf("Error!Check your inpur expression!!\n");
  }
  return 0;
}

static int cmd_w(char *args) {
  if(!new_wp(args)){
    printf("fail to add watch point.check your watch point expression.");
  }
  return 0;
}

static int cmd_d(char *args) {
  if(!free_wp(strtoul(args,NULL,10))){
    printf("del wp failure\n");
  }
  return 0;
}

//-------------------- add by dingyawei,end.--------------------------------//

void sdb_set_batch_mode() {
  is_batch_mode = true;
}

void sdb_mainloop() {
  if (is_batch_mode) {
    cmd_c(NULL);
    return;
  }

  for (char *str; (str = rl_gets()) != NULL; ) {
    char *str_end = str + strlen(str);

    /* extract the first token as the command */
    char *cmd = strtok(str, " ");
    if (cmd == NULL) { continue; }

    /* treat the remaining string as the arguments,
     * which may need further parsing
     */
    char *args = cmd + strlen(cmd) + 1;
    if (args >= str_end) {
      args = NULL;
    }

#ifdef CONFIG_DEVICE
    extern void sdl_clear_event_queue();
    sdl_clear_event_queue();
#endif

    int i;
    for (i = 0; i < NR_CMD; i ++) {
      if (strcmp(cmd, cmd_table[i].name) == 0) {
        if (cmd_table[i].handler(args) < 0) { return; }
        break;
      }
    }

    if (i == NR_CMD) { printf("Unknown command '%s'\n", cmd); }
  }
}

void init_sdb() {
  /* Compile the regular expressions. */
  init_regex();
}
