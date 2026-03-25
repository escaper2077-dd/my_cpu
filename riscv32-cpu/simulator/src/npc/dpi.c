#include <common.h>
#include <defs.h>
#include "verilated_dpi.h" 

// --- 定义 xv6/QEMU 物理内存布局 ---
#define UART_BASE      0x10000000
#define UART_SIZE      0x100
#define VIRTIO0_BASE   0x10001000  // xv6 磁盘驱动
#define PLIC_BASE      0x0c000000  // 中断控制器
#define DRAM_BASE      0x80000000  // 物理内存起始地址 (CONFIG_MBASE)


extern "C" uint32_t dpi_instr_mem_read(uint32_t addr){
	if(addr >= CONFIG_MBASE && addr < CONFIG_MBASE + CONFIG_MSIZE){
		addr = addr & ~0x3u;
		return pmem_read(addr, 4);
	}

	else{
		printf("访问的地址是%x，超过物理内存界限\n", addr);
		return 0x0;
  }
}

#define CONFIG_RTC_MMIO 0xa0000048
extern "C" uint32_t dpi_mem_read(uint32_t addr, int len, u64 pc) {
    // if(addr == 0x0000000010000005){
    //   return (uint32_t)0x20U;
    // }
    if(addr >=  CONFIG_RTC_MMIO && addr < CONFIG_RTC_MMIO + 4){
      int time = get_time();
      return time;
    }
    else if (addr >= CONFIG_MBASE && addr < (uint32_t)CONFIG_MBASE + CONFIG_MSIZE) {
        return pmem_read(addr, len);
    } 
    if (addr != 0) {
      IFDEF(CONFIG_DPI_MMIO_DEBUG, fprintf(stderr, "[DPI mem_read error] Invalid address: 0x%016lx, len: %d, pc: 0x%016lx\n", addr, len, pc));
    }
    return 0;
}

  #define CONFIG_SERIAL_MMIO 0xa00003f8

extern "C" void dpi_mem_write(uint32_t addr, uint32_t data, int len, u64 pc) {
    if(addr == CONFIG_SERIAL_MMIO){
      char ch = data;
      printf("%c", ch);
      fflush(stdout);
	  }
    // if (addr == 0x10000000) {
    //     char c = (char)(data & 0xFF);
    //     putchar(c); 
    //     fflush(stdout); 
    // }
    else if (addr >= CONFIG_MBASE && addr < (uint32_t)CONFIG_MBASE + CONFIG_MSIZE) {
      pmem_write(addr, len, data);  
    } else {

      IFDEF(CONFIG_DPI_MMIO_DEBUG, fprintf(stderr, "[DPI mem_write error] Invalid address: 0x%08lx, data: 0x%08lx, len: %d, pc: 0x%08lx\n", addr, data, len, pc));
    }
}

extern "C" void dpi_read_regfile(const svOpenArrayHandle r) {
  reg_ptr = (reg_t *)(((VerilatedDpiOpenVar*)r)->datap());
}

extern "C" void dpi_read_csrfile(const svOpenArrayHandle r) {
  csr_ptr = (reg_t *)(((VerilatedDpiOpenVar*)r)->datap());
}




