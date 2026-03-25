#ifndef __DECODE_H__
#define __DECODE_H__
#include <types.h>

#define GET_OPCODE(i)   ((i) & 0x7f)            // [6:0]
#define GET_RD(i)       (((i) >> 7) & 0x1f)     // [11:7] 目标寄存器
#define GET_RS1(i)      (((i) >> 15) & 0x1f)    // [19:15] 源寄存器 1
#define GET_RS2(i)      (((i) >> 20) & 0x1f)    // [24:20] 源寄存器 2

#define GET_CSR_ID(i) (((i) >> 20) & 0xfff)  // 指令[31:20] - CSR地址（12位）

#define GET_FUNC3(i)   (((i) >> 12) & 0x7)     // [14:12]
#define GET_FUNC7(i)   (((i) >> 25) & 0x7f)    // [31:25]

#define op_lui         0b0110111
#define op_auipc       0b0010111
#define op_jalr        0b1100111
#define op_jal         0b1101111
#define op_alu_reg     0b0110011
#define op_alu_reg_w   0b0111011
#define op_alu_imm     0b0010011
#define op_alu_imm_w   0b0011011
#define op_load        0b0000011
#define op_store       0b0100011
#define op_branch      0b1100011
#define op_system      0b1110011
#define op_fence       0b0001111
#define op_amo         0b0101111


#define func3000 0b000
#define func3001 0b001
#define func3010 0b010

#define inst_ecall      0x00000073
#define inst_ebreak     0x00100073
#define inst_uret       0x00200073
#define inst_sret       0x10200073
#define inst_mret       0x30200073
#define inst_wfi        0x10500073
#define inst_fence_i    0x0000100f

//special instr


typedef struct {
    u32 opcode;     //GET_OPCODE
    u32 csr_id;     //GET_CSR_ID
    u32 func3;      //GET_FUNCT3
    u32 func7;      //GET_FUNCT7
    u32 rd    ;     //GET_RD
}decode_t;


#endif