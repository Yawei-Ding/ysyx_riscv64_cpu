#include <NDL.h>
#include <SDL.h>
#include "assert.h"
#define keyname(k) #k,

#define ARRLEN(arr) (int)(sizeof(arr) / sizeof(arr[0]))

static const char *keyname[] = {
  "NONE",
  _KEYS(keyname)
};

uint8_t keystate[ARRLEN(keyname)];

int SDL_PushEvent(SDL_Event *ev) {
  printf("program should not reach SDL_PushEvent.");
  assert(0);
  return 0;
}

int SDL_PollEvent(SDL_Event *ev) {
  char buf[100];

  if(NDL_PollEvent(buf,ARRLEN(buf)-1) != 0){
    if(strncmp (buf, "kd ", 3) == 0){
      ev->key.type = SDL_KEYDOWN;
    }
    else if(strncmp (buf, "ku ", 3) == 0){
      ev->key.type = SDL_KEYUP;
    }
    buf[strlen(buf)-1] = '\0'; // remove '\n'
    if(ev->type == SDL_KEYDOWN || ev->type == SDL_KEYUP){
      for(int i=0; i<ARRLEN(keyname); i++){
        if(strcmp (buf+3, keyname[i]) == 0){
          ev->key.keysym.sym = i;
          keystate[i] = ev->type == SDL_KEYDOWN ? 1:0; 
          //printf("SDL_PollEvent get: %s\n",buf);
          return 1;
        }
        else{
          keystate[i] = 0;
        }
      }
    }
  }

  return 0;
}

int SDL_WaitEvent(SDL_Event *event) {
  while(SDL_PollEvent(event) == 0); // wait for KeyBoard Event
  return 1;
}

int SDL_PeepEvents(SDL_Event *ev, int numevents, int action, uint32_t mask) {
  printf("program should not reach SDL_PeepEvents.");
  assert(0);
  return 0;
}

uint8_t* SDL_GetKeyState(int *numkeys) {

  if(numkeys != NULL){
    *numkeys = ARRLEN(keyname);
  }

  return keystate;
}
