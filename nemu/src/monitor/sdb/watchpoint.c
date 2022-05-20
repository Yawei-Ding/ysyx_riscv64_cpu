#include "sdb.h"

typedef struct watchpoint {
  char *expr;              // expression pointer.
  word_t oldval;
  word_t newval;
  struct watchpoint *next; // next wp address.
} WP;

static WP *head = NULL;
static int wp_count = 0;

bool new_wp(char *args) {
  // 1. create a new node.
  WP *newwp = (WP *) malloc(sizeof(WP));
  if(newwp == NULL){
    return false;
  }

  bool success;
  newwp->expr = (char *) malloc(sizeof(char)*(strlen(args)+1));
  strcpy(newwp->expr,args);
  newwp->oldval = 0;
  newwp->newval = expr(newwp->expr,&success);
  newwp->next = NULL;

  if(success == false){
    free(newwp->expr);
    free(newwp);
  }
  else{
    // 2. add new node to link list.
    if(head == NULL){
      head = newwp;
    }
    else{
      WP * p;
      for (p = head; p->next != NULL; p = p->next);
      p->next = newwp;
    }
    
    // 3.update count for wp.
    wp_count = wp_count + 1;
    printf("new watch point %d: expr = %s,value = 0x%lx\n",wp_count,newwp->expr,newwp->newval);
  }

  return success;
}

bool free_wp(int delNO){

  // 1. delNO must in [1,wp_count]
  if(delNO > wp_count || delNO < 1){
    return false;
  }

  // 2.find delwp and remove it from link, then relink:
  WP *delwp;
  if(delNO == 1){   //delwp is head!
    delwp = head;
    head = head->next;
  }
  else{           //delwp is not head.
    WP *p = head; 
    for(int i=1 ;i <= delNO -2 ; i++){
      p = p->next;
    }
    // mind: p is the wp befor delwp.
    delwp = p->next;
    p->next = delwp->next;
  }

  // 3. delete and free delwp.
  wp_count = wp_count - 1;
  printf("remove watch point ID = %d,expr = %s,value = 0x%lx\n",delNO,delwp->expr,delwp->newval);
  free(delwp->expr);
  free(delwp);
  return true;
}

bool WP_check_update() {
  WP *p=head;
  bool nothing;
  bool update = false;
  for(int i=1; i<= wp_count; i++){
    p->oldval = p->newval;
    p->newval = expr(p->expr,&nothing);
    if(p->oldval != p->newval){
      update = true;
      printf("watch point %d has update:expr = %s, old value = 0x%lx, new value = 0x%lx, ",i,p->expr,p->oldval,p->newval);
    }
    p = p->next;
  }
  return update;
}

void wp_display(){
  WP *p=head;
  for(int i=1; i<= wp_count; i++,p = p->next){
    printf("watch point %d: expr = %s, old value = 0x%lx, new value = 0x%lx\n",i,p->expr,p->oldval,p->newval);
  }
}

// remove by dingyawei:
// #define NR_WP 32
// static WP wp_pool[NR_WP] = {};
// static WP *head = NULL, *free_ = NULL;

// void init_wp_pool() {
//   int i;
//   for (i = 0; i < NR_WP; i ++) {
//     wp_pool[i].NO = i;
//     wp_pool[i].next = (i == NR_WP - 1 ? NULL : &wp_pool[i + 1]);
//   }

//   head = NULL;
//   free_ = wp_pool;
// }
