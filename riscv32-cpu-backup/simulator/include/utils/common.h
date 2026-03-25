#ifndef __COMMON_H__
#define __COMMON_H__

#include <autoconf.h>
#include <debug.h>
#include <macro.h>
#include <types.h>
#include <utils.h>


#include <sim_state.h>
#include <autoconf.h>

#define __GUEST_ISA__ riscv32

#define GPR_NUM 32
#define CSR_NUM 4096

#define FMT_WORD  "0x%08" PRIx32
#define FMT_PADDR "0x%08" PRIx32
//#define CONFIG_MBASE 0x80000000
//#define CONFIG_MSIZE 0x8000000
//#define CONFIG_PC_RESET_OFFSET 0x0
#define PMEM_LEFT  ((reg_t)CONFIG_MBASE)
#define PMEM_RIGHT ((reg_t)CONFIG_MBASE + CONFIG_MSIZE - 1)
#define RESET_VECTOR (PMEM_LEFT + CONFIG_PC_RESET_OFFSET)

enum { DIFFTEST_TO_DUT, DIFFTEST_TO_REF };
enum { SIM_RUNNING, SIM_STOP, SIM_END, SIM_ABORT, SIM_QUIT };

#endif
