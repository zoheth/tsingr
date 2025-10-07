class Question {
  final int id;
  final String level1Title;
  final String level2Title;
  final String content;
  final List<Appearance> appearances;

  Question({
    required this.id,
    required this.level1Title,
    required this.level2Title,
    required this.content,
    required this.appearances,
  });

  factory Question.fromCsv(List<dynamic> row) {
    return Question(
      id: int.parse(row[0].toString()),
      level1Title: row[1].toString(),
      level2Title: row[2].toString(),
      content: row[3].toString(),
      appearances: [],
    );
  }

  // 计算热度（出现次数）
  int get popularity => appearances.length;

  // 获取所有标签（去重）
  Set<String> get allTags {
    final tags = <String>{};
    for (var app in appearances) {
      tags.addAll(app.tags);
    }
    return tags;
  }

  // 获取所有年份（去重并排序）
  List<String> get allYears {
    final years = appearances
        .map((e) => e.year)
        .where((y) => y.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return years;
  }

  // 格式化一级标题：将"一、效果分析"转换为"1.效果分析"
  String get formattedLevel1Title {
    return formatTitle(level1Title, true);
  }

  // 格式化二级标题：将"（一）传播效果总论"转换为"[1]传播效果总论"
  String get formattedLevel2Title {
    return formatTitle(level2Title, false);
  }

  // 标题格式化工具函数（公共静态方法）
  static String formatTitle(String title, bool isLevel1) {
    if (title.isEmpty) return title;

    if (isLevel1) {
      // 一级标题：匹配"一、效果分析"格式
      final regex = RegExp(r'^([一二三四五六七八九十]+)、(.+)$');
      final match = regex.firstMatch(title);
      if (match != null) {
        final chineseNum = match.group(1)!;
        final content = match.group(2)!;
        final arabicNum = _chineseToArabic(chineseNum);
        return '$arabicNum. $content';
      }
    } else {
      // 二级标题：匹配"（一）传播效果总论"格式
      final regex = RegExp(r'^（([一二三四五六七八九十]+)）(.+)$');
      final match = regex.firstMatch(title);
      if (match != null) {
        final chineseNum = match.group(1)!;
        final content = match.group(2)!;
        final arabicNum = _chineseToArabic(chineseNum);
        return '$arabicNum) $content';
      }
    }

    return title;
  }

  // 中文数字转阿拉伯数字（支持复杂情况）
  static int chineseToArabicNumber(String chinese) {
    final Map<String, int> numMap = {
      '零': 0, '一': 1, '二': 2, '三': 3, '四': 4,
      '五': 5, '六': 6, '七': 7, '八': 8, '九': 9,
      '十': 10,
    };

    // 直接映射简单情况
    if (numMap.containsKey(chinese)) {
      return numMap[chinese]!;
    }

    // 处理"十一"到"十九"
    if (chinese.startsWith('十') && chinese.length == 2) {
      final unit = chinese.substring(1);
      if (numMap.containsKey(unit)) {
        return 10 + numMap[unit]!;
      }
    }

    // 处理"二十"、"三十"等整十数
    if (chinese.endsWith('十') && chinese.length == 2) {
      final tens = chinese.substring(0, 1);
      if (numMap.containsKey(tens)) {
        return numMap[tens]! * 10;
      }
    }

    // 处理"二十一"、"二十二"等
    if (chinese.length == 3 && chinese.contains('十')) {
      final parts = chinese.split('十');
      if (parts.length == 2 && numMap.containsKey(parts[0]) && numMap.containsKey(parts[1])) {
        return numMap[parts[0]]! * 10 + numMap[parts[1]]!;
      }
    }

    // 无法转换则返回-1
    return -1;
  }

  // 内部使用的字符串版本
  static String _chineseToArabic(String chinese) {
    final num = chineseToArabicNumber(chinese);
    return num >= 0 ? num.toString() : chinese;
  }

  // 从标题中提取序号（用于排序）
  static int extractOrderNumber(String title, bool isLevel1) {
    if (title.isEmpty) return 999999;

    if (isLevel1) {
      final regex = RegExp(r'^([一二三四五六七八九十]+)、');
      final match = regex.firstMatch(title);
      if (match != null) {
        return chineseToArabicNumber(match.group(1)!);
      }
    } else {
      final regex = RegExp(r'^（([一二三四五六七八九十]+)）');
      final match = regex.firstMatch(title);
      if (match != null) {
        return chineseToArabicNumber(match.group(1)!);
      }
    }

    return 999999; // 无序号的排在最后
  }
}

class Appearance {
  final int questionId;
  final String year;
  final String school;
  final String majorCode;
  final List<String> tags;
  final String notes;

  Appearance({
    required this.questionId,
    required this.year,
    required this.school,
    required this.majorCode,
    required this.tags,
    required this.notes,
  });

  factory Appearance.fromCsv(List<dynamic> row) {
    final tagsStr = row[4].toString();
    final tags = tagsStr.isEmpty
        ? <String>[]
        : tagsStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    return Appearance(
      questionId: int.parse(row[0].toString()),
      year: row[1].toString(),
      school: row[2].toString(),
      majorCode: row[3].toString(),
      tags: tags,
      notes: row[5].toString(),
    );
  }
}
