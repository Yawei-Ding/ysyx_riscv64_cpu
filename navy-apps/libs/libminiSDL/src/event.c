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
    if(ev->type == SDL_KEYDOWN || ev->type == SDL_KEYUP){
      //printf("SDL_PollEvent get: %s\n",buf);
#if !defined(__ISA_NATIVE__)  // direct read keycode.
      uint8_t keycode = 0;
      sscanf(buf+3,"%2d %s",&keycode,buf+6);  // buf+3 -> buf+3 means %s do not change.
      if(keycode != 0){
        keystate[keycode] = (ev->type == SDL_KEYDOWN) ? 1:0;
        ev->key.keysym.sym = keycode;
        return 1;
      }
#else // use for native, use keyname to match keycode.
      buf[strlen(buf)-1] = '\0'; // remove '\n'
      for(int i=0; i<ARRLEN(keyname); i++){
        if(strcmp (buf+3, keyname[i]) == 0){
          ev->key.keysym.sym = i;
          keystate[i] = (ev->type == SDL_KEYDOWN) ? 1:0; 
          return 1;
        }
      }
#endif
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
