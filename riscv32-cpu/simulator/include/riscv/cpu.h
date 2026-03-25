#ifndef __CPU_CPU_H__
#define __CPU_CPU_H__

#include <common.h>
#include <debug.h>
#include <types.h>

typedef struct {
  reg_t gpr[GPR_NUM];
  reg_t pc;
  reg_t csr[CSR_NUM];
} CPU_state;




typedef struct {
    uint32_t id;
    const char *name;
} csr_map_t;
extern const csr_map_t csr_map[];
extern const int NR_TARGET_CSR;


#endif
