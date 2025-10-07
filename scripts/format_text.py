import re
import os

def process_file(input_path, output_path):
    """
    读取一个文本文件，合并被错误拆分的行，并将修正后的内容写入新文件。

    通过预设的正则表达式模式（如 '1、', '一、', '（一）'）来识别新行。
    不符合这些模式的行将被合并到前一行。
    """
    # 用于识别新条目开头的正则表达式。
    # 匹配以下模式:
    # 1. 一个或多个数字后跟 '、' (例如 '1、', '25、')
    # 2. 括号内的中文数字 (例如 '（一）', '（十二）')
    # 3. 中文数字后跟 '、' (例如 '一、', '十、')
    # 模式必须位于行首（允许有空白字符）。
    new_item_pattern = re.compile(r'^\s*(\d+、|（[一二三四五六七八九十百]+）|[一二三四五六七八九十百]+、)')

    corrected_content = []

    try:
        print(f"正在读取输入文件: {input_path}")
        with open(input_path, 'r', encoding='utf-8') as f:
            for line in f:
                # 去除行首和行尾的空白字符
                cleaned_line = line.strip()

                # 跳过空行
                if not cleaned_line:
                    continue

                # 检查当前行是否是一个新条目的开始
                if new_item_pattern.match(cleaned_line):
                    # 如果是新条目，将其作为一个新元素添加到列表中
                    corrected_content.append(cleaned_line)
                else:
                    # 如果不是新条目，说明它是上一行的延续
                    if corrected_content:
                        # 将这部分内容追加到列表中的最后一个元素上
                        corrected_content[-1] += cleaned_line
                    else:
                        # 处理文件第一行就不符合模式的边缘情况
                        corrected_content.append(cleaned_line)

        # 确保输出目录存在
        output_dir = os.path.dirname(output_path)
        if output_dir:
            os.makedirs(output_dir, exist_ok=True)

        # 将修正后的内容写入输出文件
        print(f"正在写入输出文件: {output_path}")
        with open(output_path, 'w', encoding='utf-8') as f:
            for item in corrected_content:
                f.write(item + '\n')

        print("-" * 20)
        print(f"处理完成。文件已成功保存至: {output_path}")

    except FileNotFoundError:
        print(f"错误: 输入文件未找到: {input_path}")
        print("请确保 'data/src.txt' 文件存在于脚本运行的目录下。")
    except Exception as e:
        print(f"处理过程中发生未知错误: {e}")

# --- 脚本主执行区 ---
if __name__ == "__main__":
    # 根据您的要求设置输入和输出文件路径
    input_file = 'data/src.txt'
    output_file = 'data/cleaned_data.txt' # 使用更清晰的输出文件名

    # 运行处理函数
    process_file(input_file, output_file)