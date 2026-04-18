#include <riscv.h>
#include <common.h>
#include <defs.h>
#include <svdpi.h>
#include <npc.h>

extern u64 timer_start;
extern u64 timer_end;
extern TOP_NAME dut;

// DPI-C 导入性能计数器函数
extern "C" long long get_cycle_count();
extern "C" long long get_instr_count();
extern "C" long long get_stall_count();

void sim_exit(const char *msg, int exit_code){
    npc_single_cycle();
    Log("%s", msg);

    // 设置 DPI-C scope 并读取性能计数器
    svSetScope(svGetScopeFromName("TOP.top_cpu"));
    long long cycle_cnt = get_cycle_count();
    long long instr_cnt = get_instr_count();
    long long stall_cnt = get_stall_count();
    
    // 计算性能指标
    double ipc = (cycle_cnt > 0) ? ((double)instr_cnt / (double)cycle_cnt) : 0.0;
    double stall_rate = (cycle_cnt > 0) ? ((double)stall_cnt / (double)cycle_cnt * 100.0) : 0.0;
    
    // 显示性能统计
    Log("==================== 性能统计 ====================");
    Log("[Perf] 总周期数:     %lld cycles", cycle_cnt);
    Log("[Perf] 总指令数:     %lld instructions", instr_cnt);
    Log("[Perf] 暂停周期数:   %lld cycles", stall_cnt);
    Log("[Perf] IPC:          %.3f (Instructions Per Cycle)", ipc);
    Log("[Perf] 暂停率:       %.2f%%", stall_rate);
    Log("================================================");

    npc_close_simulation();

    timer_end   = get_time();
    u64 timer_use = timer_end - timer_start;
    u64 total_sec = timer_use / 1000000;
    u64 minutes = total_sec / 60;
    u64 seconds = total_sec % 60;
    Log("[Time] 程序运行耗时: %lu min %lu s (%lu us)",  minutes, seconds, timer_use);
    exit(exit_code);
}


