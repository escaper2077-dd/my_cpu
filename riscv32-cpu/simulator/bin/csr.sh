#!/bin/bash

INPUT_FILE="./bin/npc-log.txt"
OUTPUT_FILE="./bin/csr-log.txt"

# 指令关键字定义
KEYWORDS="csrrw|csrrs|csrrc|csrrwi|csrrsi|csrrci|ecall|ebreak|uret|sret|mret|wfi|sfence.vma | amoswap.w.aq | fence"

# 1. 使用 grep 筛选
# 2. 使用 sed 提取反汇编内容
# 3. 使用 awk 进行编号格式化：[%d] %s
grep -E "$KEYWORDS" "$INPUT_FILE" | \
sed -n 's/.*反汇编=\[\(.*\)\]/\1/p' | \
awk '{printf "[%d] %s\n", NR, $0}' > "$OUTPUT_FILE"

echo "提取并编号完成，结果已保存至 $OUTPUT_FILE"

