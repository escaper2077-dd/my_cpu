
#include <dlfcn.h>
#include <common.h>
#include <defs.h>
#include <riscv.h>



void (*ref_difftest_memcpy)(paddr_t addr, void *buf, size_t n, bool direction) = NULL;
void (*ref_difftest_regcpy)(void *dut, bool direction) = NULL;
void (*ref_difftest_exec)(uint64_t n) = NULL;
void (*ref_difftest_raise_intr)(uint64_t NO) = NULL;
void isa_reg_display(CPU_state *state, const char *msg);

#ifdef CONFIG_DIFFTEST

void init_difftest(char *ref_so_file, long img_size, int port) {
  assert(ref_so_file != NULL);
  void *handle;
  handle = dlopen(ref_so_file, RTLD_LAZY);
  assert(handle);
  ref_difftest_memcpy =  (void (*)(paddr_t, void *, size_t, bool))dlsym(handle, "difftest_memcpy");
  assert(ref_difftest_memcpy);
  ref_difftest_regcpy = (void (*)(void *, bool))dlsym(handle, "difftest_regcpy");
  assert(ref_difftest_regcpy);
  ref_difftest_exec =  (void (*)(uint64_t))dlsym(handle, "difftest_exec");
  assert(ref_difftest_exec);
  ref_difftest_raise_intr = (void (*)(uint64_t))dlsym(handle, "difftest_raise_intr");
  assert(ref_difftest_raise_intr);
  void (*ref_difftest_init)(int) = (void (*)(int))dlsym(handle, "difftest_init");
  assert(ref_difftest_init);
  ref_difftest_init(port); //do nothing
  ref_difftest_memcpy(RESET_VECTOR, guest_to_host(RESET_VECTOR), img_size, DIFFTEST_TO_REF); 
  ref_difftest_regcpy(&cpu, DIFFTEST_TO_REF);  
  Log("Difftest已打开");
}



// static void display_diff_error(CPU_state *ref, reg_t pc, reg_t next_pc, const char *msg) {
//     printf("\n%-9s\n", ANSI_FMT("DIFFTEST ERROR", ANSI_FG_YELLOW ANSI_BG_RED));         
//     instr_itrace_display();

//     printf("[NPC] 执行完 pc=[0x%08lx] 处的指令后出错。错误原因: %s%s%s\n", pc, ANSI_FG_RED, msg, ANSI_NONE);
//     bool pc_mismatch = (ref->pc != next_pc);
//     const char* pc_color = pc_mismatch ? ANSI_FG_RED : "";


//     printf("[NPC] PC 状态: %s%c [参考 REF.pc]=0x%08x | [你的 DUT.pc]=0x%08lx%s\n", pc_color, pc_mismatch ? '*' : ' ', ref->pc, next_pc, ANSI_NONE);

//     printf("\n----------- 寄存器状态对比 (REF vs DUT) -----------\n");
//     for (int i = 0; i < 32; i++) {
//         bool mismatch = (ref->gpr[i] != cpu.gpr[i]);
//         const char* color = mismatch ? ANSI_FG_RED : "";
//         printf("%s%c [REF.%-3s]=0x%08x | [DUT.%-3s]=0x%08x%s\n", color, mismatch ? '*' : ' ', reg_name(i), ref->gpr[i], reg_name(i), cpu.gpr[i], ANSI_NONE);
//     }
//     sim_exit("[NPC] Difftest 终止，请检查上述差异。");
// }

static void display_diff_error(CPU_state *ref, reg_t pc, reg_t next_pc, const char *msg) {
    printf("\n%-9s\n", ANSI_FMT("DIFFTEST ERROR", ANSI_FG_YELLOW ANSI_BG_RED));         
    instr_itrace_display();
    printf("[NPC] 执行完 pc=[0x%08x] 处的指令后出错。错误原因: %s%s%s\n", (uint32_t)pc, ANSI_FG_RED, msg, ANSI_NONE);
    
    bool pc_mismatch = (ref->pc != next_pc);
    const char* pc_color = pc_mismatch ? ANSI_FG_RED : "";
    printf("[NPC] PC 状态: %s%c [参考 REF.pc]=0x%08x | [你的 DUT.pc]=0x%08x%s\n",  pc_color, pc_mismatch ? '*' : ' ', (uint32_t)ref->pc, (uint32_t)next_pc, ANSI_NONE);

    printf("\n----------- 寄存器状态对比 (REF vs DUT) -----------\n");
    for (int i = 0; i < 32; i++) {
        bool mismatch = (ref->gpr[i] != cpu.gpr[i]);
        const char* color = mismatch ? ANSI_FG_RED : "";
        printf("%s%c [REF.%-3s]=0x%08x | [DUT.%-3s]=0x%08x%s\n", 
            color, mismatch ? '*' : ' ', reg_name(i), (uint32_t)ref->gpr[i], reg_name(i), (uint32_t)cpu.gpr[i], ANSI_NONE);
    }
    sim_exit("[ERROR] 程序由于Difftest 终止退出，请检查上述差异。");
}


static void checkcsrs(CPU_state *ref, reg_t pc, reg_t next_pc) {
    for (int i = 0; i < NR_TARGET_CSR; i++) {
        int id = csr_map[i].id;
        const char *name = csr_map[i].name;
        if( id == cycle || id== timer || instret) {
            continue;
        }
        if (ref->csr[id] != cpu.csr[id]) {
            char buf[128];
            snprintf(buf, sizeof(buf), "CSR [%s] (0x%03x) 数值不一致! \t[REF]=0x%08x, [DUT]=0x%08x", name, id, ref->csr[id], cpu.csr[id]);
            display_diff_error(ref, pc, next_pc, buf);
        }
    }
}

static void checkregs(CPU_state *ref, reg_t pc, reg_t next_pc) {
    if (next_pc != ref->pc) {
        display_diff_error(ref, pc, next_pc, "PC 出现不一致");
    }
    for (int i = 0; i < 32; i++) {
        if (ref->gpr[i] != cpu.gpr[i]) {
            char buf[64];
            snprintf(buf, sizeof(buf), "寄存器 [%s] 数值不一致", reg_name(i));
            display_diff_error(ref, pc, next_pc, buf);
        }
    }

}






void load_store_info_dispaly(commit_t *commit, const char *msg){
}

static inline bool is_mmio_address(uint64_t addr) {
    return (addr < 0x80000000) && (addr >= 0x10000000);
}



static inline void log_mmio(const commit_t *c, bool is_load) {
    #ifdef CONFIG_DIFFTEST_MMIO_DEBUG
        const u32 func3 = GET_FUNC3(c->instr);
        const i32 len   = (1 << (func3 & 0x3));
        if (is_load)
            log_write("[MMIO Load ] [ PC: 0x%08x | Addr: 0x%08x | Len: %d\n", c->pc, c->mem_addr, len);
        else
            log_write("[MMIO Store] [ PC: 0x%08x | Addr: 0x%08x | WData: 0x%08x | Len: %d\n", c->pc, c->mem_addr, c->mem_wdata, len);
    #endif
}

bool is_special_instr(const commit_t *commit) {
    const u32 opcode = GET_OPCODE(commit->instr);    
    const u32 func3 = GET_FUNC3(commit->instr);            
    const u32 csr_id = GET_CSR_ID(commit->instr);
    //csrrs
    // if(commit->instr == 0x342022f3){
    //     return true;
    // }

    if (opcode == op_system && func3 != 0) { 
        return csr_id == timer;
    }
    bool is_load  = (opcode == op_load);
    bool is_store = (opcode == op_store);
    if (is_load || is_store) {
        if (is_mmio_address(commit->mem_addr)) {
            log_mmio(commit, is_load);
            return true;
        }
    }
    return false;
}


void check_load_store_instr(){
}

void difftest_step(const commit_t * commit) {
    CPU_state ref_r;
    ref_difftest_exec(1);    

    if(is_special_instr(commit)){
        cpu.pc= commit->next_pc;
        ref_difftest_regcpy(&cpu, DIFFTEST_TO_REF);
    }
    ref_difftest_regcpy(&ref_r, DIFFTEST_TO_DUT);

    check_load_store_instr();
    if(check_inst_trigger()){
        checkregs(&ref_r, commit->pc, commit->next_pc);
        checkcsrs(&ref_r, commit->pc, commit->next_pc);
    }
}

#else
void init_difftest(char *ref_so_file, long img_size, int port) { }
#endif


