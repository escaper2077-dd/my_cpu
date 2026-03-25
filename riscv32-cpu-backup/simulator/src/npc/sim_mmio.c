// // --- 地址类型判定函数 (抽象层) ---
// #include <defs.h>


// static inline bool is_mmio(uintptr_t addr) {
//     return addr < DRAM_BASE; // xv6 中，DRAM 之下皆为外设
// }
// static inline bool is_uart(uintptr_t addr) {
//     return (addr >= UART_BASE && addr < UART_BASE + 0x100);
// }
// void handle_uart_write(uint64_t data) {
//     putchar((char)data & 0xFF);
//     fflush(stdout);
// }
// extern "C" void dpi_mem_write(uint64_t addr, uint64_t data, int len, u64 pc) {
//     if (!is_mmio(addr)) {
//         pmem_write(addr, len, data);
//         return;
//     }
//     if (is_uart(addr)) {
//         handle_uart_write(data);
//     } 
// }

// extern "C" uint64_t dpi_mem_read(uint64_t addr, int len, u64 pc) {
//     if (!is_mmio(addr)) {
//         return pmem_read(addr, len);
//     }
//     if (is_uart(addr)) {
//         return (addr == UART_BASE + 5) ? 0x20 : 0;
//     }
//     return 0;
// }