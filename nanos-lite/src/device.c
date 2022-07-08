#include <common.h>

#if defined(MULTIPROGRAM) && !defined(TIME_SHARING)
# define MULTIPROGRAM_YIELD() yield()
#else
# define MULTIPROGRAM_YIELD()
#endif

#define NAME(key) \
  [AM_KEY_##key] = #key,

static const char *keyname[256] __attribute__((used)) = {
  [AM_KEY_NONE] = "NONE",
  AM_KEYS(NAME)
};

size_t serial_write(const void *buf, size_t offset, size_t len) {
  int i = 0;
  for(i=0; i<len; i++){
    putch(*((uint8_t*)buf+i));
  }
  return i;
}

size_t events_read(void *buf, size_t offset, size_t len) {
  AM_INPUT_KEYBRD_T key = io_read(AM_INPUT_KEYBRD);
  if(key.keycode == 0){ // there is no key down or up.
    return 0;
  }
  else{
    switch(key.keydown){
      case 0:  snprintf((char *)buf,len,"ku %s\n",keyname[key.keycode]); break;
      case 1:  snprintf((char *)buf,len,"kd %s\n",keyname[key.keycode]); break;
    }
    return len;
  }
}

size_t dispinfo_read(void *buf, size_t offset, size_t len) {
  // eg: WIDTH : 640. HEIGHT:480
  AM_GPU_CONFIG_T dispinfo = io_read(AM_GPU_CONFIG);
  snprintf(buf,len,"WIDTH:%d\nHEIGHT:%d\n",dispinfo.width,dispinfo.height);
  return 0;
}

extern size_t open_offset;
size_t fb_write(const void *buf, size_t offset, size_t len) {

  AM_GPU_CONFIG_T dispinfo = io_read(AM_GPU_CONFIG);

  AM_GPU_FBDRAW_T ctl;
  ctl.pixels = (void *)buf;
  ctl.sync = true;

  // there 2 method to support gpu, check fs.c init_fs() and navy-apps/libs/libndl/NDL.c: NDL_DrawRect() to match.

  // method 1: only write w for one time, and use loop to finish all, slow but support native.
  // ctl.x = (offset/4) % dispinfo.width;
  // ctl.y = (offset/4) / dispinfo.width;
  // ctl.w = len/4;
  // ctl.h = 1;

  // method 2: use high 32bit to store w, low 32bit to store h. fast but not support native!
  ctl.x = offset % dispinfo.width;
  ctl.y = offset / dispinfo.width;
  ctl.w = len >> 32;                // high 32bit.
  ctl.h = len & 0x00000000FFFFFFFF; // low 32bit.

  io_write(AM_GPU_FBDRAW, ctl.x, ctl.y, ctl.pixels, ctl.w, ctl.h, ctl.sync);
  open_offset = offset + len;

  printf("GPU trace position (x,y)=(%d,%d), size (w,h)=(%d,%d), sync=%d\n", ctl.x, ctl.y, ctl.w, ctl.h, ctl.sync);
  return 0;
}

void init_device() {
  Log("Initializing devices...");
  ioe_init();
}
