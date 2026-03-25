#ifndef  DEFS_H_
#define  DEFS_H_
#include <riscv/riscv.h>
#include <common.h>




//sdb.c
void 		sdb_set_batch_mode();

//cpu.c
void 		cpu_exec(uint64_t n);
const char* reg_name(int idx);
int 	    check_reg_idx(int idx);
int 	    check_csr_idx(int idx);
void        isa_csr_display(CPU_state *, const char *);
void        isa_reg_display(CPU_state *, const char *);
#define pc_self  (cpu.pc)
#define gpr(idx) (cpu.gpr[check_reg_idx(idx)])
#define csr(idx) (cpu.csr[check_csr_idx(idx)])
void 		get_cpu_state_from_npc();
void 		init_regex();



//init_monitor.c
void 		init_monitor(int , char **);
void 		init_log     (const char *log_file);
void 		init_difftest(char *ref_so_file, long img_size, int port);
void 		init_disasm(const char *triple);
void 		init_trace ();

void disassemble(char *str, int size, uint64_t pc, uint8_t *code, int nbyte);

void		init_rand();
void        difftest_step(const commit_t*);
bool        isa_difftest_checkregs(CPU_state *ref_r, reg_t pc);


uint64_t    get_time();
void        npc_open_simulation();
void        npc_close_simulation();
void        update_cpu_state();
void        npc_single_cycle();
void        npc_reset(int n);
void        npc_init();
void        npc_exec_once();
void        npc_get_clk_count();

void 	    init_mem();
uint8_t*    guest_to_host(reg_t paddr);
reg_t	    pmem_read (reg_t addr, int len);
void	    pmem_write(reg_t addr, int len, reg_t data);

//
void        instr_trace_dispatch(reg_t pc, u32 instr, u64 instr_count);  //good
void        instr_itrace_display();                                      //good
void        sim_exit(const char *msg, int exit_code = 1 );
bool        check_inst_trigger();
bool        log_enable();
void        dump_pmem_4kb();
void        dump_pmem_to_log();


//全局变量

extern u64 sim_instr_count;
extern u64 sim_time;
extern u64 clk_count;

extern CPU_state cpu;
extern reg_t *reg_ptr;
extern reg_t *csr_ptr;
extern uint8_t pmem[CONFIG_MSIZE];
extern SIMState   sim_state;
extern FILE *log_fp;
void        update_sim_clk_count();
void        update_instr_count();
bool        instr_exec_one_million();

#endif
