#include <common.h>

FILE *log_fp = NULL;

void init_log(const char *log_file) {
  log_fp = stdout;
  if (log_file != NULL) {
    FILE *fp = fopen(log_file, "w");
    Assert(fp, "Can not open '%s'", log_file);
    log_fp = fp;
  }
  Log("程序运行日志将被写入到 %s", log_file ? log_file : "stdout");
}
bool log_enable() {
  return log_fp != NULL;
}