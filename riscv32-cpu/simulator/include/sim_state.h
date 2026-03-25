#ifndef NPC_STATE_H_
#define NPC_STATE_H_
#include <types.h>

typedef struct {
  int state;
  u32 halt_pc;
  u32 halt_ret;
} SIMState;
uint64_t  get_time();
struct tm get_system_time();

#endif


