#include <riscv.h>
#include <common.h>
#include <defs.h>

extern u64 timer_start;
extern u64 timer_end;

void sim_exit(const char *msg, int exit_code){
    npc_single_cycle();
    Log("%s", msg);

    npc_close_simulation();

    timer_end   = get_time();
    u64 timer_use = timer_end - timer_start;
    u64 total_sec = timer_use / 1000000;
    u64 minutes = total_sec / 60;
    u64 seconds = total_sec % 60;
    Log("[Time] 程序运行耗时: %lu min %lu s (%lu us)",  minutes, seconds, timer_use);
    exit(exit_code);
}


