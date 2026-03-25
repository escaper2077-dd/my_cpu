#include <common.h>
#include <defs.h>

#include <npc.h>


// 固定快照文件名
#define SNAPSHOT_FILE "snapshot/arch_snapshot.bin"


bool take_arch_snapshot(const CPU_state *state, const uint8_t *mem) {
    FILE *fp = fopen(SNAPSHOT_FILE, "wb");
    if (!fp) {
        perror("Snapshot Save Error");
        return false;
    }
    if (fwrite(state, sizeof(CPU_state), 1, fp) != 1) {
        fprintf(stderr, "Error: Failed to write CPU state to snapshot.\n");
        fclose(fp);
        return false;
    }

    if (fwrite(mem, 1, CONFIG_MSIZE, fp) != CONFIG_MSIZE) {
        fprintf(stderr, "Error: Failed to write pmem to snapshot.\n");
        fclose(fp);
        return false;
    }

    fclose(fp);
    printf("[Snapshot] System state locked and saved to '%s'\n", SNAPSHOT_FILE);
    return true;
}

bool restore_arch_snapshot(CPU_state *state, uint8_t *mem) {
    FILE *fp = fopen(SNAPSHOT_FILE, "rb");
    if (!fp) {
        // 如果文件不存在，通常在启动时需要提醒
        fprintf(stderr, "[Snapshot] No snapshot file '%s' found to load.\n", SNAPSHOT_FILE);
        return false;
    }

    // 1. 读取 CPU 结构体
    if (fread(state, sizeof(CPU_state), 1, fp) != 1) {
        fprintf(stderr, "Error: Snapshot file is corrupted (CPU state).\n");
        fclose(fp);
        return false;
    }

    // 2. 读取 128MB 内存
    if (fread(mem, 1, CONFIG_MSIZE, fp) != CONFIG_MSIZE) {
        fprintf(stderr, "Error: Snapshot file is corrupted (pmem).\n");
        fclose(fp);
        return false;
    }

    fclose(fp);
    printf("[Snapshot] System state successfully restored from '%s'\n", SNAPSHOT_FILE);
    return true;
}