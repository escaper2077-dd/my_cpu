#ifndef __COMMIT__H__
#define __COMMIT__H__

#include <types.h>

typedef struct commit_t{
  reg_t pc;
  reg_t next_pc;
  u32 instr;

  reg_t mem_addr;
  reg_t mem_rdata;
  reg_t mem_wdata;
}commit_t;

#endif