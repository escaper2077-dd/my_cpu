#include "cpu.h"
#include <common.h>
#include <debug.h>
#include <defs.h>



uint8_t pmem[CONFIG_MSIZE] PG_ALIGN = {}; 

void init_mem() {
#if defined(CONFIG_PMEM_MALLOC)
  pmem = malloc(CONFIG_MSIZE);
  assert(pmem);
#endif
  IFDEF(CONFIG_MEM_RANDOM, memset(pmem, 0, CONFIG_MSIZE));
  Log("物理内存区域为 [" FMT_PADDR ", " FMT_PADDR "]", PMEM_LEFT, PMEM_RIGHT);
}


uint8_t* guest_to_host(paddr_t paddr) { 
  return pmem + paddr - CONFIG_MBASE; 
}

static inline reg_t host_read(void *addr, int len) {
  switch (len) {
    case 1: return *(uint8_t  *)addr;
    case 2: return *(uint16_t *)addr;
    case 4: return *(uint32_t *)addr;
    case 8: return *(uint64_t *)addr;
    default: assert(0);
  }
}
static inline void host_write(void *addr, int len, reg_t data) {
  switch (len) {
    case 1: *(uint8_t  *)addr = data; return;
    case 2: *(uint16_t *)addr = data; return;
    case 4: *(uint32_t *)addr = data; return;
    case 8: *(uint64_t *)addr = data; return;
    default: assert(0);
  }
}
static inline bool in_pmem(paddr_t addr) {
  return addr >= CONFIG_MBASE && addr <= CONFIG_MBASE + CONFIG_MSIZE;
}


reg_t pmem_read(paddr_t addr, int len){
  return host_read(guest_to_host(addr), len);
}
void pmem_write(paddr_t addr, int len, reg_t data) {
  host_write(guest_to_host(addr), len, data);
}
static void out_of_bound(paddr_t addr) {

//  panic("in[npc] address = " FMT_PADDR " is out of bound of pmem [" FMT_PADDR ", " FMT_PADDR "] at pc = " FMT_WORD, addr, PMEM_LEFT, PMEM_RIGHT, cpu.pc);
}

reg_t paddr_read(paddr_t addr, int len){
  if(likely(in_pmem(addr))) return pmem_read(addr, len);
  IFDEF(CONFIG_DEVICE, return mmio_read(addr, len));
  out_of_bound(addr);
  return 0;
}

void paddr_write(paddr_t addr, int len, reg_t data) {
  if (likely(in_pmem(addr))) { pmem_write(addr, len, data); return; }
  IFDEF(CONFIG_DEVICE, mmio_write(addr, len, data); return);
  out_of_bound(addr);
}



// void dump_pmem_4kb() {
//   paddr_t start_addr = CONFIG_MBASE;
//   int total_size = 4096; // 4KB
//   int step = 4;          // 4字节
//   printf("--- Memory Dump: Start at " FMT_PADDR " (Total 4KB) ---\n", start_addr);
//   for (int i = 0; i < total_size; i += step) {
//     paddr_t curr_addr = start_addr + i;
    
//     // 每行打印 16 字节（即 4 个 32位字）
//     if (i % 16 == 0) {
//       printf("\n" FMT_PADDR ": ", curr_addr);
//     }
//     uint32_t data = (uint32_t)pmem_read(curr_addr, step);
//     printf("0x%08x  ", data);
//   }
//   printf("\n--- End of Dump ---\n");
// }

// void dump_pmem_to_log() {
//   if (!log_enable()) return;
//   const char *green_line = "===========================================================\n";  
//   paddr_t start_addr = CONFIG_MBASE;
//   int total_size = 4096; // 4KB
//   int step = 4;
//   fprintf(log_fp, "%s", green_line);
//   fprintf(log_fp, "--- [Memory Dump Start] Base: " FMT_PADDR ", Size: 4KB ---\n", start_addr);
//   for (int i = 0; i < total_size; i += step) {
//     paddr_t curr_addr = start_addr + i;
//     if (!in_pmem(curr_addr)) {
//         fprintf(log_fp, "\n[Dump Error]: Address " FMT_PADDR " out of pmem bound.\n", curr_addr);
//         break;
//     }

//     if (i % 16 == 0) {
//       fprintf(log_fp, "\n[" FMT_PADDR "]: ", curr_addr);
//     }

//     uint32_t data = (uint32_t)pmem_read(curr_addr, step);
//     fprintf(log_fp, "0x%08x ", data);

//     if ((i + step) % 64 == 0) {
//       fflush(log_fp);
//     }
//   }

//   fprintf(log_fp, "\n--- [Memory Dump End] ---\n");
//   fprintf(log_fp, "%s", green_line);
//   fflush(log_fp);
// }