#ifndef __TYPES__H__
#define __TYPES__H__
#include <stdint.h>
#include <inttypes.h>
#include <stdbool.h>
#include <string.h>
#include <stdlib.h>
#include <sys/types.h>

typedef uint64_t     u64;
typedef uint32_t     u32;
typedef uint16_t     u16;
typedef uint8_t      u8;
typedef  int64_t     i64;
typedef  int32_t     i32;
typedef  int16_t     i16;
typedef   int8_t     i8;

#ifdef CONFIG_RISCV64
    typedef uint64_t  reg_t;
    typedef  int64_t sreg_t;
#endif
#ifdef CONFIG_RISCV32
    typedef uint32_t  reg_t;
    typedef  int32_t sreg_t;
    typedef uint32_t  paddr_t;
    typedef uint32_t  vaddr_t;
#endif


#endif