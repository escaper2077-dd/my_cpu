#include <common.h>
#include <defs.h>

#define ITRACE_POOL_SIZE 30
#define INST_STR_MAX 128
typedef struct {
    reg_t pc;
    u32 instr; 
} TraceEntry;

static TraceEntry itrace_pool[ITRACE_POOL_SIZE];
static int itrace_ptr = 0;                          // 下一个写入位置
static bool pool_full = false;                      // 标记是否已写满过一轮

void instr_trace(reg_t pc, u32 instr, u64 instr_count) {
    char inst_str[INST_STR_MAX];
    disassemble(inst_str, INST_STR_MAX, pc, (u8 *)&instr, 8);
    printf("[%ld] pc=[0x%08x] instr=[0x%08x], disassemble=[%s]\n", instr_count, pc, instr, inst_str);
//    log_write("[%ld] pc=[0x%08x] instr=[0x%08x], disassemble=[%s]\n", instr_count, pc, instr, inst_str);
}

void instr_itrace(reg_t pc, u32 instr) {
    itrace_pool[itrace_ptr].pc = pc;
    itrace_pool[itrace_ptr].instr = instr;
    itrace_ptr = (itrace_ptr + 1) % ITRACE_POOL_SIZE;
    if (itrace_ptr == 0) pool_full = true;
}



void instr_itrace_display() {    
    int total = pool_full ? ITRACE_POOL_SIZE : itrace_ptr;
    printf("\n%s ● " ANSI_BOLD "最近 %d 条指令 " ANSI_FG_RESET "(总计已执行: %" PRIu64 " 条, 不含 nop)\n",  ANSI_FG_CYAN, total, sim_instr_count);    
    int i = pool_full ? itrace_ptr : 0;
    //执行count循环
    for (int count = 0; count < total; count++) {
        char inst_str[INST_STR_MAX];
        TraceEntry *e = &itrace_pool[i];

        disassemble(inst_str, INST_STR_MAX, e->pc, (uint8_t *)&e->instr, 4);
        int last_idx = (itrace_ptr + ITRACE_POOL_SIZE - 1) % ITRACE_POOL_SIZE;
        char current_flag = (i == last_idx) ? '>' : ' ';
        printf("%c [0x%08x]: 0x%08x  %s\n", current_flag, e->pc, e->instr, inst_str);

        i = (i + 1) % ITRACE_POOL_SIZE;
    }
    if (total == 0) {
        printf(" (No instructions executed yet.)\n");
    }    
    printf("--- [ End of Trace ] ---\n");
}





// --- 模式解析 (支持 ?, 0, 1) ---
static inline void parse_pattern(const char *p, u32 *key, u32 *mask) {
    *key = 0; *mask = 0;
    while (*p) {
        if (*p == ' ' || *p == '_') { p++; continue; }
        *key <<= 1; *mask <<= 1;
        if (*p == '1') { *key |= 1; *mask |= 1; }
        else if (*p == '0') { *mask |= 1; }
        p++;
    }
}

// --- 统一的 Trace 处理 ---
static inline void __do_execute_special_trace(reg_t pc, u32 instr, u64 instr_count) {
    char inst_str[INST_STR_MAX];
   disassemble(inst_str, INST_STR_MAX, pc, (uint8_t *)&instr, 4);
   log_write("[%ld] pc=[0x%08x] instr=[0x%08x], disassemble=[%s]\n", instr_count, pc, instr, inst_str);
}


#define INSTPAT(pattern, label) do { \
    static u32 __key = 0, __mask = 0; \
    static int __inited = 0; \
    if (!__inited) { parse_pattern(pattern, &__key, &__mask); __inited = 1; } \
    if ((instr & __mask) == __key) { \
        __do_execute_special_trace(pc, instr, instr_count); \
        return; \
    } \
} while (0)

// --- 业务逻辑 ---
void instr_special_trace(reg_t pc, u32 instr, u64 instr_count) {

    // INSTPAT("0000000 00000 00000 000 00000 11100 11", ecall);
    // INSTPAT("0000000 00001 00000 000 00000 11100 11", ebreak);
    // INSTPAT("0000000 00010 00000 000 00000 11100 11", uret);
    // INSTPAT("0001000 00010 00000 000 00000 11100 11", sret);
    // INSTPAT("0011000 00010 00000 000 00000 11100 11", mret);
    INSTPAT("0001000 00101 00000 000 00000 11100 11", wfi);
    INSTPAT("0001001 ????? ????? 000 00000 11100 11", sfence_vma);

    INSTPAT("??????? ????? ????? 001 ????? 11100 11", csrrw);
    INSTPAT("??????? ????? ????? 010 ????? 11100 11", csrrs);

    INSTPAT("000110000000 ????? 001 ????? 1110011", csrrw_satp);
    INSTPAT("000110000000 ????? 010 ????? 1110011", csrrs_satp);

    // INSTPAT("??????? ????? ????? 011 ????? 11100 11", csrrc);
    // INSTPAT("??????? ????? ????? 101 ????? 11100 11", csrrwi);
    // INSTPAT("??????? ????? ????? 110 ????? 11100 11", csrrsi);
    // INSTPAT("??????? ????? ????? 111 ????? 11100 11", csrrci);

    // INSTPAT("??????? ????? ????? 000 ????? 00011 11", fence);
    // INSTPAT("??????? ????? ????? 001 ????? 00011 11", fence_i);

    // INSTPAT("00010?? ????? ????? 010 ????? 01011 11", lr_w);
    // INSTPAT("00011?? ????? ????? 010 ????? 01011 11", sc_w);
    // INSTPAT("00001?? ????? ????? 010 ????? 01011 11", amoswap_w);
    // INSTPAT("00000?? ????? ????? 010 ????? 01011 11", amoadd_w);
    // INSTPAT("00100?? ????? ????? 010 ????? 01011 11", amoxor_w);
    // INSTPAT("01100?? ????? ????? 010 ????? 01011 11", amoand_w);
    // INSTPAT("01000?? ????? ????? 010 ????? 01011 11", amoor_w);
    // INSTPAT("10000?? ????? ????? 010 ????? 01011 11", amomin_w);
    // INSTPAT("10100?? ????? ????? 010 ????? 01011 11", amomax_w);
    // INSTPAT("11000?? ????? ????? 010 ????? 01011 11", amominu_w);
    // INSTPAT("11100?? ????? ????? 010 ????? 01011 11", amomaxu_w);

    // INSTPAT("00010?? ????? ????? 011 ????? 01011 11", lr_d);
    // INSTPAT("00011?? ????? ????? 011 ????? 01011 11", sc_d);
    // INSTPAT("00001?? ????? ????? 011 ????? 01011 11", amoswap_d);
    // INSTPAT("00000?? ????? ????? 011 ????? 01011 11", amoadd_d);
    // INSTPAT("00100?? ????? ????? 011 ????? 01011 11", amoxor_d);
    // INSTPAT("01100?? ????? ????? 011 ????? 01011 11", amoand_d);
    // INSTPAT("01000?? ????? ????? 011 ????? 01011 11", amoor_d);
    // INSTPAT("10000?? ????? ????? 011 ????? 01011 11", amomin_d);
    // INSTPAT("10100?? ????? ????? 011 ????? 01011 11", amomax_d);
    // INSTPAT("11000?? ????? ????? 011 ????? 01011 11", amominu_d);
    // INSTPAT("11100?? ????? ????? 011 ????? 01011 11", amomaxu_d);
}
//----------------------------------------instr_special_trace---end--------------------------------------------------

void instr_trace_dispatch(reg_t pc, u32 instr, u64 instr_count){
    IFDEF(CONFIG_TRACE_LOG,         instr_trace(pc, instr, instr_count));
    IFDEF(CONFIG_TRACE_SPECIAL,     instr_special_trace(pc, instr, instr_count));
    IFDEF(CONFIG_ITRACE,            instr_itrace(pc , instr));
}