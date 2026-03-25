#include <riscv.h>
#include <common.h> //types.h
#include <defs.h>
#include <npc.h>

extern TOP_NAME dut;  		

#include <types.h>
u64 sim_clk_count   = 0;
u64 sim_instr_count = 0;
u64 sim_time        = 0;

u64  get_sim_clk_count()      {  return sim_clk_count;    }
void update_sim_clk_count()   {         sim_clk_count++;  } 
void update_instr_count()     {         sim_instr_count++;}

void check_ebreak(const commit_t *commit) {
    if (commit->instr == inst_ebreak) { 
        sim_exit("程序由于hit ebreak退出", 0);
    }
}
void get_commit_info(commit_t * commit){
    commit->pc         = dut.commit_pc;
    commit->next_pc    = dut.commit_next_pc;
    commit->instr      = dut.commit_instr;
    commit->mem_addr   = dut.commit_mem_addr;
    commit->mem_rdata  = dut.commit_mem_rdata;
    commit->mem_wdata  = dut.commit_mem_wdata;
}
void get_cpu_info(CPU_state * diff_cpu){
  diff_cpu->pc= cpu.pc;
  memcpy(diff_cpu->gpr, cpu.gpr, sizeof(diff_cpu->gpr));
  memcpy(diff_cpu->csr, cpu.csr, sizeof(diff_cpu->csr));
}
bool check_inst_trigger(){
  return sim_instr_count >= CONFIG_INSTR_TRACE_START;
}

void execute(uint64_t n){
  for (   ;n > 0; n --) {
    commit_t commit = {0};
    while(dut.commit != 1){      
      npc_single_cycle();
    }
    get_commit_info(&commit);
    check_ebreak(&commit);
    npc_single_cycle();                  
    update_cpu_state();    
    sim_instr_count++;
    IFDEF(CONFIG_TRACE,     if(check_inst_trigger()) instr_trace_dispatch(commit.pc, commit.instr, sim_instr_count));
    IFDEF(CONFIG_DIFFTEST,  difftest_step(&commit));      
  }
}

//timer
u64 timer_start = 0;
u64 timer_end   = 0;

void cpu_exec(uint64_t n) {
  timer_start = get_time();
  execute(n); 
}


