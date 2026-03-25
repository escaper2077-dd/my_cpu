#include <defs.h>   //api
#include <common.h>

//static const char *img_file = "/home/akun/riscv64-cpu/simulator/bin/xv6-kernel.bin";
static char *img_file = NULL;
static char *log_file = NULL;
static char *diff_so_file = NULL;
static int   difftest_port = 1234;


static void welcome() {
  Log("Build time: %s, %s", __TIME__, __DATE__);
  printf("Welcome to %s-npc!\n", ANSI_FMT(str(__GUEST_ISA__), ANSI_FG_YELLOW ANSI_BG_RED));
  printf("For help, type \"help\"\n");
}


static long load_img() {
  if (img_file == NULL) {
    Log("测试框架运行的是内置程序");
    return 4096; // built-in image size
  }
  FILE *fp = fopen(img_file, "rb");
  Assert(fp, "Can not open '%s'", img_file);
  fseek(fp, 0, SEEK_END);
  long size = ftell(fp);
  Log("处理器运行的程序是 %s, size = %ld", img_file, size);

  fseek(fp, 0, SEEK_SET);
  int ret = fread(guest_to_host(RESET_VECTOR), size, 1, fp);
  assert(ret == 1);
  fclose(fp);
  return size;
}

void sdb_set_batch_mode(){}
#include <getopt.h> //
static int parse_args(int argc, char *argv[]) {
  const struct option table[] = {
    {"batch"    , no_argument      , NULL, 'b'},
    {"log"      , required_argument, NULL, 'l'},
    {"diff"     , required_argument, NULL, 'd'},
    {"port"     , required_argument, NULL, 'p'},
    {"help"     , no_argument      , NULL, 'h'},
    {0          , 0                , NULL,  0 },
  };
  int o;
  while ( (o = getopt_long(argc, argv, "-bhl:d:p:", table, NULL)) != -1) {
    switch (o) {
      case 'b': sdb_set_batch_mode();  break;
      case 'p': sscanf(optarg, "%d", &difftest_port); break;
      case 'l': log_file = optarg;     break;
      case 'd': diff_so_file = optarg; break;
      case 1:   img_file = optarg;     return 0;
      default:
        printf("Usage: %s [OPTION...] IMAGE [args]\n\n", argv[0]);
        printf("\t-b,--batch              run with batch mode\n");
        printf("\t-l,--log=FILE           output log to FILE\n");
        printf("\t-d,--diff=REF_SO        run DiffTest with reference REF_SO\n");
        printf("\t-p,--port=PORT          run DiffTest with port PORT\n");
        printf("\n");
        exit(0);
    }
  }
  return 0;
}

static const uint32_t img [] = {  
  0xfff00293,
  0x30529073,  
  0x00100073  // ebreak (used as nemu_trap)
//0xdeadbeef,  // some data
};

void load_builded_img(){
  memcpy(guest_to_host(RESET_VECTOR), img, sizeof(img));
}

void init_simulator(int argc, char **argv){
  parse_args(argc, argv);
  init_rand();
  init_log(log_file);
  init_mem();
  load_builded_img();
  long img_size = load_img();
  npc_init();
  init_difftest(diff_so_file,img_size, difftest_port);
  init_disasm("riscv32-pc-linux-gnu");
  welcome();
}

int main(int argc, char **argv){
  printf("\n %s\n", ANSI_FMT(str(__GUEST_ISA__), ANSI_FG_YELLOW ANSI_BG_RED));
  init_simulator(argc, argv);
  cpu_exec(UINT64_MAX);
  return 0;
}
