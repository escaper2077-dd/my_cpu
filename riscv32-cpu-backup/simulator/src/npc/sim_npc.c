#include <common.h> //types.h
#include <riscv.h>
#include <defs.h>
#include <sys/types.h>
#include <verilated.h>
#include "verilated_fst_c.h"
#include <npc.h>

#define STR_HELPER(x) #x
#define STR(x) STR_HELPER(x)
#define MAX_GUEST_INST 30000

TOP_NAME dut;  			    //CPU
static VerilatedFstC *m_trace = NULL;  //仿真波形

void npc_open_simulation(){
  Verilated::traceEverOn(true);
  m_trace= new VerilatedFstC;
  dut.trace(m_trace, 5);
  m_trace->open("gtkwave/waveform.fst");
  Log("打开波形追踪(FST格式)");
}
void npc_close_simulation(){
  IFDEF(CONFIG_NPC_OPEN_SIM, 	m_trace->close());
  IFDEF(CONFIG_NPC_OPEN_SIM, Log("波形追踪已完成,可以通过make sim命令查看"));
}



void npc_single_cycle() {
  dut.clk = 0;  dut.eval();       
  IFDEF(CONFIG_NPC_OPEN_SIM,  if(check_inst_trigger()) m_trace->dump(sim_time++)); 
  dut.clk = 1;  dut.eval();       
  IFDEF(CONFIG_NPC_OPEN_SIM,  if(check_inst_trigger()) m_trace->dump(sim_time++)); 
  update_sim_clk_count();
}

void npc_reset(int n) {
  dut.rst = 1;  
  while(n -- > 0) npc_single_cycle();
  dut.rst = 0;
}

void npc_init() {
  IFDEF(CONFIG_NPC_OPEN_SIM, npc_open_simulation());  
  npc_reset(1);  
  update_cpu_state(); 
  if(dut.cur_pc != 0x80000000){
    npc_close_simulation();
    printf("处理器的值目前为pc=0x%08x, 处理器初始化/复位之后, PC值应该为0x80000000\n", cpu.pc);
    printf("处理器初始化/复位的PC值不正确, 程序退出\n");
    exit(1);
  }
  Log("处理器初始化完毕");
}
