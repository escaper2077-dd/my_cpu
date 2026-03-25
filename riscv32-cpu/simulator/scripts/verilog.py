import re
import sys
import os

def connect_signals_inplace(file_path):
    if not os.path.exists(file_path):
        print(f"错误: 找不到文件 {file_path}")
        return

    try:
        # 1. 一次性读取所有内容，方便对比
        with open(file_path, 'r', encoding='utf-8') as f:
            old_content = f.read()

        lines = old_content.splitlines(keepends=True)
        new_lines = []
        
        # 优化后的模式
        pattern = r'(\.\w+_i_\w+\s*\()\s*(\w+)_i_(\w+)(\s*\))'
        count = 0
        
        for line in lines:
            # 只有匹配到的行才进行替换逻辑
            if re.search(pattern, line):
                # 提取前缀和后缀进行校验（可选，这里保留你的逻辑）
                match = re.search(pattern, line)
                prefix = match.group(2)
                suffix = match.group(3)
                
                # 执行替换
                new_line = re.sub(pattern, rf'\1 {prefix}_o_{suffix} \4', line)
                new_lines.append(new_line)
                count += 1
            else:
                new_lines.append(line)

        # 2. 将处理后的行合并为完整字符串
        new_content = "".join(new_lines)

        # 3. 【关键改进】：理性判断是否需要写入
        if old_content == new_content:
            print(f"检测到内容未改变，跳过写入，保持文件时间戳不变。")
        else:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(new_content)
            print(f"处理完成！文件已覆盖: {file_path}")
            print(f"共自动连接信号线: {count} 处")

    except Exception as e:
        print(f"处理过程中发生错误: {e}")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        connect_signals_inplace(sys.argv[1])
    else:
        print("用法: python link.py <your_verilog_file>.v")