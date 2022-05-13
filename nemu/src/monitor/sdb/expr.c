#include <isa.h>

/* We use the POSIX regex functions to process regular expressions.
 * Type 'man regex' for more information about POSIX regex functions.
 */
#include <regex.h>

enum {
  TK_NOTYPE = 256,
  TK_L_PAR,
  TK_R_PAR,
  TK_MUL,
  TK_DIV,
  TK_PLUS,
  TK_SUB,
  TK_NUM,
  //TK_EQ,
};

static struct rule {
  const char *regex;
  int token_type;
} rules[] = {
  {" +", TK_NOTYPE},    // spaces,+代表匹配1次或多次
  {"\\(", TK_L_PAR},    // left parentheses
  {"\\)", TK_R_PAR},    // right parentheses
  {"\\*", TK_MUL},      // mul
  {"\\/", TK_DIV},      // div
  {"\\+", TK_PLUS},     // plus
  {"\\-", TK_SUB},      // sub
  {"[0-9]+", TK_NUM},   // num
//{"==", TK_EQ},        // equal
};

#define NR_REGEX ARRLEN(rules)

static regex_t re[NR_REGEX] = {};

/* Rules are used for many times.
 * Therefore we compile them only once before any usage.
 */
void init_regex() {
  int i;
  char error_msg[128];
  int ret;

  for (i = 0; i < NR_REGEX; i ++) {
    ret = regcomp(&re[i], rules[i].regex, REG_EXTENDED);
    if (ret != 0) {
      regerror(ret, &re[i], error_msg, 128);
      panic("regex compilation failed: %s\n%s", error_msg, rules[i].regex);
    }
  }
}

typedef struct token {
  int type;
  char str[32];
} Token;

static Token tokens[32] __attribute__((used)) = {};
static int nr_token __attribute__((used))  = 0;

static bool make_token(char *e) {
  int position = 0;
  int i;
  regmatch_t pmatch;

  nr_token = 0;

  while (e[position] != '\0') {
    /* Try all rules one by one. */
    for (i = 0; i < NR_REGEX; i ++) {
      if (regexec(&re[i], e + position, 1, &pmatch, 0) == 0 && pmatch.rm_so == 0){
        //每次都从指针(e + position)的起始位置开始，如果和match了rule里的某个token： 
        char *substr_start = e + position;
        int substr_len = pmatch.rm_eo;

        Log("match rules[%d] = \"%s\" at position %d with len %d: %.*s",
            i, rules[i].regex, position, substr_len, substr_len, substr_start);

        position += substr_len;

        //-------------------- add by dingyawei,start.--------------------------------//
        switch (rules[i].token_type) {
          case TK_NOTYPE: 
            break; //do nothing!!
          case TK_NUM:  
            strncpy(tokens[nr_token].str,substr_start,substr_len);//no break!!
            printf("token ID = %d, token = %s\n",nr_token,tokens[nr_token].str);
          default: 
            if(rules[i].token_type!=TK_NUM)
              printf("token ID = %d, token = %c\n",nr_token,*substr_start);
            tokens[nr_token].type = rules[i].token_type;
            nr_token++;
        }
        //-------------------- add by dingyawei,end.--------------------------------//

        break;
      }
    }

    if (i == NR_REGEX) { //means that no rules match!!
      printf("no match at position %d\n%s\n%*.s^\n", position, e, position, "");
      return false;
    }
  }

  return true;
}

//-------------------- add by dingyawei,start.--------------------------------//

/*----------------------------------------------------
check_parentheses 核心思想：从左往右统计括号个数。
 1.任意时刻，左括号数<右括号数，语法错误，程序终止！
 2.非p=q时刻，左括号数=右括号数，左右括号不匹配，返回false。
 3.p=q时刻，左括号数=右括号数，左右括号匹配，返回true。
 4. 程序中分了两个for循环，这是因为如果只有一个for循环，
        那么永远不会检测到count_l < count_r这种情况！
函数已经测试完毕，没有问题辣！
----------------------------------------------------*/
bool check_parentheses(Token *p,Token *q){
  int count_l = 0;  //count for numbers of left  parentheses
  int count_r = 0;  //count for numbers of right parentheses
  Token *start = p;

  if(p->type == TK_L_PAR && q->type == TK_R_PAR){
    for( ; p<=q; p++){
      //printf("p:%p\tq:%p\tcount_l:%d\tcount_r:%d\tp->type:%d\n",p,q,count_l,count_r,p->type);
      switch(p->type){
        case TK_L_PAR: count_l++; break;
        case TK_R_PAR: count_r++; break;
      }
      if(count_l < count_r) {
        printf("Check your input ),bad expression!\n");
        assert(0);// false !! bad expression!!
      }
    }
    
    for(p=start,count_l=0,count_r=0; p<=q; p++){
      switch(p->type){
        case TK_L_PAR: count_l++; break;
        case TK_R_PAR: count_r++; break;
      }
      if(count_l == count_r){
        if(p==q){
          return true;
        }
        else{
          return false;
        }
      }
    }
  }
    return false;
}

Token* find_plus_sub_operator(Token *start,Token *end)
{
  Token *p,*q;
  for(p=start,q=end; p<=q; q--){ //寻找最右侧的+-号
    if(q->type == TK_PLUS || q->type == TK_SUB){
      printf("主符号是%d,位置在:%ld\n",q->type,q-start);
      return q;
    }
    else if(q->type == TK_R_PAR){//右括号，直接找到对应的左括号
      for(Token *t=p;t<=q;t++){
        if(check_parentheses(t,q)){
          printf("左括号的位置:%ld,右括号的位置:%ld\n",t-start,q-start);
          if(t!=p){   //如果括号的位置不是最左边，那么直接移动q到左括号的左边，跳过括号！
            q = t;
          }
          else{    //如果括号的位置是最左边,考虑如下例子：(3+2)*3+2*7,那么直接跳过整个括号，重新查找*3+2*7
            return find_plus_sub_operator(q+1,end);
          }
          break;
        }    
      }
    }  
  }
  return NULL;
}


Token* find_mul_div_operator(Token *start,Token *end)
{
  Token *p,*q;
  for(p=start,q=end; p<=q; q--){ //没有+-号,寻找最右侧的*/号
    if(q->type == TK_MUL || q->type == TK_DIV){
      printf("主符号是%d,位置在:%ld\n",q->type,q-p);
      return q; 
    }
    else if(q->type == TK_R_PAR){//右括号，直接找到对应的左括号，移动到左括号的左边！
      for(Token *t=p;t<=q;t++){
        if(check_parentheses(t,q)){
          printf("左括号的位置:%ld,右括号的位置:%ld\n",t-start,q-start);
          if(t!=p){   //如果括号的位置不是最左边，那么直接移动q到左括号的左边，跳过括号！
            q = t;
          }
          else{    //理论上永远不会出现这种情况。
            printf("find_mul_div_operator error:%ld\n",q-p);
            return NULL;
          }
          break;
        }    
      }
    }  
  }
  printf("find_mul_div_operator error:%ld\n",q-p);
  return NULL;
}

//核心思想：从右往左，找优先级最低的函数！！
Token* find_main_operator(Token *start,Token *end){

  Token* main_operator = find_plus_sub_operator(start,end);
  if(main_operator!=NULL)
    return main_operator;
  main_operator = find_mul_div_operator(start,end);
  if(main_operator!=NULL)
    return main_operator;

  return NULL;
}


uint32_t eval(Token *p,Token *q){
  if (p > q) {
    assert(0); //error! end the program!
  }
  else if (p == q) {
    assert(p->type == TK_NUM); //This single token should be a number!
    return ((uint32_t)strtoul(p->str,NULL,10));
  }
  else if (check_parentheses(p, q) == true) {
    return eval(p + 1, q - 1);
    return 0;
  }
  else {
    Token *op = find_main_operator(p,q);

    uint32_t val1 = eval(p, op - 1);
    uint32_t val2 = eval(op + 1, q);

    printf("val1=%d,val2=%d,op->type=%d\n",val1,val2,op->type);

    switch (op->type) {
      case TK_PLUS: return val1 + val2;
      case TK_SUB:  return val1 - val2;
      case TK_MUL:  return val1 * val2;
      case TK_DIV:  return val1 / val2;
      default: assert(0);//error! end the program!
    }

  }
}

//-------------------- add by dingyawei,end.--------------------------------//

word_t expr(char *e, bool *success) {
  if (!make_token(e)) {
    *success = false;
    return 0;
  }

  *success = true;
  return eval(tokens,tokens+nr_token-1);
}
