import re
import csv
import os

# --- Global keyword list for both tag extraction and cleaning ---
keywords_to_extract = [
    '简答', '论述', '名解', '观点讨论', '学硕', '专硕', '综合', '材料分析',
    '观点', '讨论', '名词解释'
]

def parse_appearance_block(block_text):
    """
    [V4版] 从一个括号块中灵活地解析年份、学校、专业代码和标签。
    - 新增: 返回一个包含'tags'键的字典。
    """
    content = block_text.strip('（）()').strip()
    
    # 1. 提取标签 (Tags)
    tags_found = [kw for kw in keywords_to_extract if kw in content]
    tags_str = ', '.join(tags_found)

    # 2. 提取年份
    year_match = re.search(r'\b(1[8-9]|2\d)\b', content)
    year = year_match.group(1) if year_match else None
    if year:
        content = re.sub(r'\b' + re.escape(year) + r'\b', '', content, 1).strip()

    # 3. 提取专业代码
    major_match = re.search(r'\b(\d{3,})\b', content)
    major = major_match.group(1) if major_match else None
    if major:
        content = re.sub(r'\b' + re.escape(major) + r'\b', '', content, 1).strip()
        
    # 4. 从内容中移除所有标签关键词以分离出学校名称
    cleaned_content = content
    for keyword in keywords_to_extract:
        cleaned_content = cleaned_content.replace(keyword, '')
        
    school = cleaned_content.strip().strip('-()').strip()

    # 只有当学校名称看起来有效时，我们才认为解析成功
    if school:
        return {'year': year, 'school': school, 'major': major, 'tags': tags_str, 'valid': True}
    else:
        # 即使无法识别学校，也返回找到的标签和原始块内容作为备注
        return {'year': None, 'school': None, 'major': None, 'tags': tags_str, 'valid': False}


def process_text_v4(input_filepath, questions_csv_path, appearances_csv_path, unprocessed_log_path):
    """
    [V4版] 读取文本文件，解析带有层级标题的考题信息。
    - 新增: 在appearances.csv中增加'标签'和'备注'列。
    - 优化: 即使无法解析出学校/年份，也会将括号内容存入'备注'，并将识别出的关键词存入'标签'。
    """
    if not os.path.exists(input_filepath):
        print(f"错误：输入文件 '{input_filepath}' 不存在。")
        return

    l1_header_pattern = re.compile(r'^([一二三四五六七八九十百]+、\s*.+)')
    l2_header_pattern = re.compile(r'^（[一二三四五六七八九十百]+）\s*.+')
    block_finder_pattern = re.compile(r'([（\(].*?[）\)])')

    questions_data = []
    appearances_data = []
    unprocessed_lines = []
    question_to_id = {}
    question_id_counter = 1

    current_l1_title = ""
    current_l2_title = ""

    with open(input_filepath, 'r', encoding='utf-8') as f:
        for line in f:
            original_line = line.strip()
            cleaned_line = re.sub(r'\s+\d+$', '', original_line).strip()

            if not cleaned_line:
                continue

            l1_match = l1_header_pattern.match(cleaned_line)
            if l1_match:
                current_l1_title = l1_match.group(1).strip(); current_l2_title = ""; continue
            
            l2_match = l2_header_pattern.match(cleaned_line)
            if l2_match:
                current_l2_title = cleaned_line; continue

            blocks = block_finder_pattern.findall(cleaned_line)

            if blocks:
                # --- V4 核心逻辑（修复版）---
                # 找到第一个括号块的位置，之前的内容是题目
                first_block = blocks[0]
                first_block_index = cleaned_line.find(first_block)

                # 题干是第一个括号块之前的所有内容
                title_part = cleaned_line[:first_block_index]
                question_title = re.sub(r'^\d+[、．.]\s*', '', title_part).strip()

                if not question_title or len(question_title) < 2:
                    unprocessed_lines.append(f"[无效题目行]: {original_line}")
                    continue

                # 分配或获取 question_id
                if question_title not in question_to_id:
                    current_question_id = question_id_counter
                    question_to_id[question_title] = current_question_id
                    questions_data.append([current_question_id, current_l1_title, current_l2_title, question_title])
                    question_id_counter += 1
                else:
                    current_question_id = question_to_id[question_title]

                # 解析**所有**括号块，每个都是一条出现记录
                for block in blocks:
                    appearance_info = parse_appearance_block(block)

                    year_full = f"20{appearance_info['year']}" if appearance_info['year'] else ''
                    school_cleaned = appearance_info['school'] if appearance_info['school'] else ''
                    major_code = appearance_info['major'] if appearance_info['major'] else ''
                    tags = appearance_info['tags']

                    # 如果解析无效，将原始块内容放入备注
                    notes = ''
                    if not appearance_info['valid']:
                        notes = block.strip('（）()').strip()

                    appearances_data.append([current_question_id, year_full, school_cleaned, major_code, tags, notes])

            else:
                unprocessed_lines.append(f"[格式不匹配]: {original_line}")

    # --- 文件写入 ---
    with open(questions_csv_path, 'w', newline='', encoding='utf-8-sig') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(['question_id', '一级标题', '二级标题', '题目'])
        writer.writerows(questions_data)
    print(f"处理完成！题目数据已保存到 '{questions_csv_path}'。共 {len(questions_data)} 个独立题目。")

    # 更新表头以包含新列
    with open(appearances_csv_path, 'w', newline='', encoding='utf-8-sig') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(['question_id', '年份', '学校', '专业代码', '标签', '备注'])
        writer.writerows(appearances_data)
    print(f"处理完成！出现记录已保存到 '{appearances_csv_path}'。共 {len(appearances_data)} 条记录。")

    if unprocessed_lines:
        with open(unprocessed_log_path, 'w', encoding='utf-8') as logfile:
            for line in unprocessed_lines:
                logfile.write(line + '\n')
        print(f"注意：有 {len(unprocessed_lines)} 行无法处理，已记录在 '{unprocessed_log_path}'。")
    else:
        print("所有行都已成功处理！")

# --- 如何使用 ---
if __name__ == '__main__':
    input_file = 'data/cleaned_data.txt'
    questions_file = 'data/questions.csv'
    # 使用新的输出文件名以避免混淆
    appearances_file = 'data/appearances.csv' 
    unprocessed_file = 'data/unprocessed_lines.txt'

    if not os.path.exists('data'):
        os.makedirs('data')
    
    process_text_v4(input_file, questions_file, appearances_file, unprocessed_file)