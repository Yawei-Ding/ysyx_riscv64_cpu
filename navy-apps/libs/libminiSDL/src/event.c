#include <NDL.h>
#include <SDL.h>

#define keyname(k) #k,

#define ARRLEN(arr) (int)(sizeof(arr) / sizeof(arr[0]))

static const char *keyname[] = {
  "NONE",
  _KEYS(keyname)
};

int SDL_PushEvent(SDL_Event *ev) {
  return 0;
}

int SDL_PollEvent(SDL_Event *ev) {
  return 0;
}


int SDL_WaitEvent(SDL_Event *event) {

  char buf[100];

  while(NDL_PollEvent(buf,ARRLEN(buf)) == 0); // wait for KeyBoard Event.

  printf("SDL_WaitEvent get: %s\n",buf);
  if(strncmp (buf, "kd ", 3) == 0){
    event->key.type = SDL_KEYDOWN;
  }
  else if(strncmp (buf, "ku ", 3) == 0){
    event->key.type = SDL_KEYUP;
  }
  if(event->type == SDL_KEYDOWN || event->type == SDL_KEYUP){
    for(int i=0; i<ARRLEN(keyname); i++)
    if(strcmp (buf+3, keyname[i]) == 0){
      event->key.keysym.sym = i;
    }
  }

  return 1;
}

int SDL_PeepEvents(SDL_Event *ev, int numevents, int action, uint32_t mask) {
  return 0;
}

uint8_t* SDL_GetKeyState(int *numkeys) {
  return NULL;
}
