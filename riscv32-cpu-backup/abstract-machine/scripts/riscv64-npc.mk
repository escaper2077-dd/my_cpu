include $(AM_HOME)/scripts/isa/riscv.mk
include $(AM_HOME)/scripts/platform/npc.mk

# 修改为 rv64IM 架构的编译器标志
COMMON_CFLAGS += -march=rv64im -mabi=lp64  # overwrite
LDFLAGS       += -melf64lriscv               # overwrite

# 根据 rv64 架构调整源文件
AM_SRCS += riscv/npc/libgcc/div.S \
           riscv/npc/libgcc/muldi3.S \
           riscv/npc/libgcc/multi3.c \
           riscv/npc/libgcc/ashldi3.c \
           riscv/npc/libgcc/unused.c