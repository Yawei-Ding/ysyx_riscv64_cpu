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

char* getTokenInfo(Token *p){ //add by dingyawei. return the token info, used for printf!
  static char TokenInfo[32];
  switch (p->type)
  {
    case TK_NOTYPE: strcpy(TokenInfo," "); break;
    case TK_L_PAR:  strcpy(TokenInfo,"("); break;
    case TK_R_PAR:  strcpy(TokenInfo,")"); break;
    case TK_MUL:    strcpy(TokenInfo,"*"); break;
    case TK_DIV:    strcpy(TokenInfo,"/"); break;
    case TK_PLUS:   strcpy(TokenInfo,"+"); break;
    case TK_SUB:    strcpy(TokenInfo,"-"); break;
    case TK_NUM:    strcpy(TokenInfo,p->str); break;
  }
  return TokenInfo;
}


static bool make_token(char *e) {
  int position = 0;
  int i;
  regmatch_t pmatch;

  // clear last time tokens:
  nr_token = 0;
  for(int i=0;i<32;i++){
    tokens[i].type = 0;
    for(int j=0;j<32;j++){
      tokens[i].str[j] = '\0';
    }
  }

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

        switch (rules[i].token_type) {
          case TK_NOTYPE: 
            break; //do nothing!!
          case TK_NUM:  
            strncpy(tokens[nr_token].str,substr_start,substr_len); // no break!!!!
          default: 
            tokens[nr_token].type = rules[i].token_type;
            //printf("Make token function get info: token ID = %d, token = %s\n",nr_token,getTokenInfo(&tokens[nr_token]));
            nr_token++; //if input is TK_NOTYPE, nr_token will not increase !!
        }

        break;
      }
    }

    if (i == NR_REGEX) { //means that no rules match!!
      printf("no match at position %d\n%s\n%*.s^\n", position, e, position, "");
      return false;
    }
  }

  nr_token = nr_token -1 ; //remove the last nr_token++ 
  return true;
}

//-------------------------------------------------------------------- add by dingyawei,start.--------------------------------------------------------------------------------//

/*需要检查start和end是否匹配括号,这里给出一些例子：
a) (4+3*(2-1))    //匹配
b)  4+3*(2-1)     //不匹配, start和end没有被同一个括号包围
c) (4+3)*(2-1)    //不匹配, start和end不是同一个括号！
d) (4+3))*((2-1)  //不匹配, 左括号和右括号数量一致,但是个错误的式子！
e) (4+3))*(2-1)   //不匹配, 左括号和右括号数量都不一致！
check_parentheses函数核心思想：从右往左统计括号个数。
 1.遍历全部token, 任意时刻, 如果左括号数>右括号数,说明是上面的例子d),assert(0);
 2.遍历全部token, 统计左括号和右括号数量,如果不等,说明是上面的例子e),return false;
 3.遍历全部token,左括号数=右括号数,但尚未遍历完毕,说明是上面的例子c),左右括号不匹配,return false;
                左括号数=右括号数,且已遍历完毕,左右括号匹配,return true;
*/
bool check_parentheses(Token *start,Token *end){
  int count_l = 0;  //count for numbers of left  parentheses
  int count_r = 0;  //count for numbers of right parentheses

  if(start->type == TK_L_PAR && end->type == TK_R_PAR){

    //-------------------遍历排除例子d):---------------------//
    for(Token *q=end ; start<=q; q--){
      switch(q->type){
        case TK_L_PAR: count_l++; break;
        case TK_R_PAR: count_r++; break;
      }
      //printf("p:%p\tq:%p\tcount_l:%d\tcount_r:%d\tp->type:%s\n",p,q,count_l,count_r,getTokenInfo(p));
      if(count_l > count_r) {
        printf("Check your input ),bad expression!\n");
        assert(0);
      }
    }
    //-------------------排除例子e):---------------------//
    if(count_l != count_r){ //注意,这里不能用assert,例如寻找主符号的函数设置mask时调用了这个函数 (1+(2+3)+4),那么会出assert!
      //printf("Check your input, ( is not equal to )!\n");
      return false;
    }

    //-----------------遍历排除例子c),以及确定是否有效:-------------------//
    for(Token *q=end ; start<=q; q--){
      switch(q->type){
          case TK_L_PAR: count_l++; break;
          case TK_R_PAR: count_r++; break;
        }
        //printf("p:%p\tq:%p\tcount_l:%d\tcount_r:%d\tp->type:%s\n",p,q,count_l,count_r,getTokenInfo(p));
        if(count_l == count_r){
          if(start==q){ //是否已经遍历完毕
            //printf("check parentheses true\n");
            return true;
          }
          else{
            //printf("check parentheses false\n");
            return false;
          }
      }
    }
  }
  return false;
}

/*需要将一个式子,找到主符号,然后拆分成两个式子,通常情况下主符号是优先级最低的函数：
a) (86*234)/((16*94))*(39/4)  // 主符号为 94)) * (39/4 这个"*"号！
b) 3+2*3+(2*7+(33+244))       // 主符号为 *3+(2* 这个"+"号！
c) (3+2)*3+2*7+(33+244)       // 主符号为 *7+(33+ 这个"+"号！

find_main_op函数核心思想：从右往左寻找优先级最低的函数！
 1.遍历全部token,检查有多少括号
 2.遍历全部token, 给带括号及其内部的位置全部打上Mask!
 3.遍历全部无mask的token,从右往左寻找+-号
 4.遍历全部无mask的token,从右往左寻找x/号
*/
Token* find_main_op(Token *start,Token *end){

  int count_l = 0;  //count for numbers of left  parentheses
  int count_r = 0;  //count for numbers of right parentheses

  // 1. 遍历全部token,检查有多少括号
  for(Token *q=end ; start<=q; q--){
    switch(q->type){
      case TK_L_PAR: count_l++; break;
      case TK_R_PAR: count_r++; break;
    }
  }
  if(count_l != count_r){
    printf("Find main opreator error! Check your input, ( is not equal to )!\n");
    assert(0);
  }

  // 2. 从右到左遍历带括号的token,打上mask

  int len = end -start + 1;
  bool *mask = (bool *) malloc(len*sizeof(bool));

  for(int i=0; i<len; i++){
    mask[i] = false;
  }

  while(count_l != 0 || count_r !=0){
    count_l = 0;
    count_r = 0;
    for(int i = len-1 ; i>=0 ; i--){
      if(mask[i] == false && start[i].type == TK_R_PAR){ //找到了未mask的右括号
        for(int j = i -1 ; j>=0 ; j--)
          if(mask[j] == false && check_parentheses(start+j,start+i)){
            //printf("token j ID = %d, token i ID = %d \n",j,i);
            for(int k=j; k<=i ;k++){  //针对括号及其内部,全部打上mask
              mask[k] = true;
            } 
            break;
          }
      }
    }
    for(int i = len-1 ; i>=0 ; i--){
      if(mask[i] == false){
        switch(start[i].type){
          case TK_L_PAR: count_l++; break;
          case TK_R_PAR: count_r++; break;
        }
      }
    }
  }

  // 打印mask信息
  // for(Token *p=start;p<=end;p++){
  //   printf("find_main_op token = %s, mask = %d \n",getTokenInfo(p),mask[p-start]);
  // }

  // 3.利用mask遍历token,寻找+-号
  for(int i = len-1 ; i>=0 ; i--){
    if(mask[i] == false){
       if(start[i].type == TK_PLUS || start[i].type == TK_SUB){
        return start+i;
       }
    }
  }

  // 4.利用mask遍历token,寻找+-号
  for(int i = len-1 ; i>=0 ; i--){
    if(mask[i] == false){
       if(start[i].type == TK_MUL || start[i].type == TK_DIV){
        return start+i;
       }
    }
  }
  
  free(mask);
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
  }
  else {
    Token *op = find_main_op(p,q);
    if(op == NULL){
      return 0;
    }

    uint32_t val1 = eval(p, op - 1);
    uint32_t val2 = eval(op + 1, q);

    // 打印分隔开的两个式子信息：

    printf("expr1=");
    for(Token *i=p;i<=op-1;i++){
      printf("%s",getTokenInfo(i));
    }
    printf(",val1=%d,  ",val1);
    printf("  op=%s,  ",getTokenInfo(op));
    printf("expr2=");
    for(Token *i=op+1;i<=q;i++){
      printf("%s",getTokenInfo(i));
    }
    printf(",val2=%d\n",val2);


    switch (op->type) {
      case TK_PLUS: return val1 + val2;
      case TK_SUB:  return val1 - val2;
      case TK_MUL:  return val1 * val2;
      case TK_DIV:  return val1 / val2;
      default: assert(0);//error! end the program!
    }
  }

  return 0;
}

//-------------------------------------------------------------------- add by dingyawei,end.--------------------------------------------------------------------------------//

word_t expr(char *e, bool *success) {
  if (!make_token(e)) {
    *success = false;
    return 0;
  }
  //Token *op = find_main_op(tokens,tokens+nr_token);
  //check_parentheses(tokens,tokens+nr_token);
  //printf("find_main_op token ID = %ld, token = %s \n",op-tokens,getTokenInfo(op));
  *success = true;
  return eval(tokens,tokens+nr_token);
  return 0;
}
