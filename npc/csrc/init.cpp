#include "include/include.h"
#include <getopt.h>

char *img_file = NULL;
static char *diff_so_file = NULL;
static int parse_args(int argc, char *argv[]);

void npc_init(int argc, char *argv[],axi4_mem <32,64,4> *mem) {
  // Parse arguments.
  parse_args(argc, argv);

  // Load the image to memory.
  mem->load_binary(img_file,0x80000000);

#ifdef  DIFFTEST_ON
  // Initialize differential testing.
  difftest_init(diff_so_file, img_file);
#endif
}

static int parse_args(int argc, char *argv[]) {
  const struct option table[] = {
    {"img"      , required_argument, NULL, 'i'},
    {"diff"     , required_argument, NULL, 'd'},
    {0          , 0                , NULL,  0 },
  };
  int o;
  while ( (o = getopt_long(argc, argv, "-d:i:", table, NULL)) != -1) {
    switch (o) {
      case 'i': img_file     = optarg; break;
      case 'd': diff_so_file = optarg; break;
    }
  }
  return 0;
}
