#include <stdint.h>
#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static int evtdev = -1;
static int fbdev = -1;
static int screen_w = 0, screen_h = 0;

uint32_t NDL_GetTicks() {
  struct timeval now;
  gettimeofday(&now, NULL);
  return now.tv_usec;
}

int NDL_PollEvent(char *buf, int len) {
  int fd = open("/dev/events",0,0);
  if(fd == -1){
    return 0;
  }
  return read(fd,buf,len);
}

// 打开一张(*w) X (*h)的画布
// 如果*w和*h均为0, 则将系统全屏幕作为画布, 并将*w和*h分别设为系统屏幕的大小
void NDL_OpenCanvas(int *w, int *h) {

  int fd = open("/proc/dispinfo",0,0);
  if(fd == -1){
    printf("open /proc/dispinfo error");
    return ;
  }

  char buf[50];
  read(fd,buf,sizeof(buf));
  sscanf(buf,"WIDTH:%d\nHEIGHT:%d\n",&screen_w,&screen_h);

  if(*w == 0 && *h == 0){
    *w = screen_w;
    *h = screen_h;
  }

  //printf("WIDTH:%d\nHEIGHT:%d\n",screen_w,screen_h);
  assert(*w <= screen_w && *h <= screen_h);

  // if (getenv("NWM_APP")) {
  //   int fbctl = 4;
  //   fbdev = 5;
  //   screen_w = *w; screen_h = *h;
  //   char buf[64];
  //   int len = sprintf(buf, "%d %d", screen_w, screen_h);
  //   // let NWM resize the window and create the frame buffer
  //   write(fbctl, buf, len);
  //   while (1) {
  //     // 3 = evtdev
  //     int nread = read(3, buf, sizeof(buf) - 1);
  //     if (nread <= 0) continue;
  //     buf[nread] = '\0';
  //     if (strcmp(buf, "mmap ok") == 0) break;
  //   }
  //   close(fbctl);
  // }
}

// 向画布`(x, y)`坐标处绘制`w*h`的矩形图像, 并将该绘制区域同步到屏幕上
// 图像像素按行优先方式存储在`pixels`中, 每个像素用32位整数以`00RRGGBB`的方式描述颜色
void NDL_DrawRect(uint32_t *pixels, int x, int y, int w, int h) {
  int fd = open("/dev/fb",0,0);
  if(fd == -1){
    printf("open /dev/fb error");
    return ;
  }

// there 2 method to support gpu, check nanos_lite/src/device.c: fb_write() and nanos-lite/src/fs.c:init_fs() to match.
#if defined(__ISA_NATIVE__) // for native, slow but support native.
// method 1: only write w for one time, and use loop to finish all.
  for(int j=0; j<h; j++){
    lseek(fd,((y+j)*screen_w+x)*4,SEEK_SET); // 4 for 32bits, 4bytes.
    write(fd, pixels+w*j, 4*w);              // 4 for 32bits, 4bytes.
  }
#else // for nemu, fast but not support native.
// method 2: use high 32bit to store w, low 32bit to store h. 
  lseek(fd,x*y,SEEK_SET);
  write(fd, pixels, ((size_t)w<<32) | ((size_t)h & 0x00000000FFFFFFFF)); //w=high 32bit, h=low 32bit.
#endif

}

void NDL_OpenAudio(int freq, int channels, int samples) {
}

void NDL_CloseAudio() {
}

int NDL_PlayAudio(void *buf, int len) {
  return 0;
}

int NDL_QueryAudio() {
  return 0;
}

int NDL_Init(uint32_t flags) {
  if (getenv("NWM_APP")) {
    evtdev = 3;
  }
  return 0;
}

void NDL_Quit() {
}
