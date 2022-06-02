#include <am.h>
#include <nemu.h>

#define W    400  // only support 400*300*32
#define H    300  // only support 400*300*32
#define SYNC_ADDR (VGACTL_ADDR + 4)

void __am_gpu_init() {
  int i;
  int w = W;
  int h = H;
  uint32_t *fb = (uint32_t *)(uintptr_t)FB_ADDR;
  for (i = 0; i < w * h; i ++){
    fb[i] = i;
  }
  outl(SYNC_ADDR, 1);
}

void __am_gpu_config(AM_GPU_CONFIG_T *cfg) {
  *cfg = (AM_GPU_CONFIG_T) {
    .present = true, .has_accel = false,
    .width = W, .height = H,
    .vmemsz = W*H*sizeof(uint32_t)
  };
}

void __am_gpu_fbdraw(AM_GPU_FBDRAW_T *ctl) {

  uint32_t *fb = (uint32_t *)(uintptr_t)FB_ADDR;
  uint32_t *pixels = (uint32_t*)(ctl->pixels);
  int x = ctl->x, y = ctl->y;
  int w = ctl->w, h = ctl->h;
  for(int j = 0; j< h; j++){
    for(int i = 0; i< w; i++){
      fb[(y+j)*W+(x+i)] = *(pixels+j*w+i);
    }
  }

  if (ctl->sync) {
    outl(SYNC_ADDR, 1);
  }
}

void __am_gpu_status(AM_GPU_STATUS_T *status) {
  status->ready = true;
}
