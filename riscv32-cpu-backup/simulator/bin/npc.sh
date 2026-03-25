#!/bin/bash

# 定义文件名
INPUT_FILE="npc-log.txt"
OUTPUT_FILE="cleaned-npc-log.txt"

# 1. 检查文件是否存在
if [ ! -f "$INPUT_FILE" ]; then
    echo "错误: 找不到文件 $INPUT_FILE"
    echo "请确保该脚本与 npc-log.txt 放在同一个目录下。"
    exit 1
fi

echo "开始处理 $INPUT_FILE ..."

# 2. 使用 awk 进行去重
# 这里的逻辑是：建立一个哈希表 a，记录每一行出现的次数。
# 只有当该行是第一次出现时 (!a[$0]++)，awk 才会打印该行。
# 这能有效去除你提到的 UART 轮询死循环中重复出现的指令行。
awk '!a[$0]++' "$INPUT_FILE" > "$OUTPUT_FILE"

# 3. 输出统计结果
if [ $? -eq 0 ]; then
    ORIGINAL_COUNT=$(wc -l < "$INPUT_FILE")
    CLEANED_COUNT=$(wc -l < "$OUTPUT_FILE")
    echo "--------------------------------------"
    echo "处理完成！"
    echo "原始行数: $ORIGINAL_COUNT"
    echo "去重后行数: $CLEANED_COUNT"
    echo "已成功过滤掉 $((ORIGINAL_COUNT - CLEANED_COUNT)) 条重复指令。"
    echo "结果文件: $OUTPUT_FILE"
    echo "--------------------------------------"
else
    echo "处理过程中出现错误。"
    exit 1
fi