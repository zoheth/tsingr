import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import '../models/question.dart';

class DataService {
  static List<Question>? _cachedQuestions;

  // 加载所有题目数据
  static Future<List<Question>> loadQuestions() async {
    if (_cachedQuestions != null) {
      return _cachedQuestions!;
    }

    // 加载questions.csv
    final questionsData = await rootBundle.loadString('assets/questions.csv');
    final questionsCsv = const CsvToListConverter().convert(questionsData);

    // 加载appearances.csv
    final appearancesData = await rootBundle.loadString('assets/appearances.csv');
    final appearancesCsv = const CsvToListConverter().convert(appearancesData);

    // 解析questions（跳过表头）
    final questionsMap = <int, Question>{};
    for (var i = 1; i < questionsCsv.length; i++) {
      final question = Question.fromCsv(questionsCsv[i]);
      questionsMap[question.id] = question;
    }

    // 解析appearances并关联到questions（跳过表头）
    for (var i = 1; i < appearancesCsv.length; i++) {
      final appearance = Appearance.fromCsv(appearancesCsv[i]);
      questionsMap[appearance.questionId]?.appearances.add(appearance);
    }

    _cachedQuestions = questionsMap.values.toList();

    // 按热度（出现次数）排序
    _cachedQuestions!.sort((a, b) => b.popularity.compareTo(a.popularity));

    return _cachedQuestions!;
  }

  // 按分类获取题目
  static List<Question> getQuestionsByCategory(
    List<Question> allQuestions,
    String level1Title,
  ) {
    return allQuestions
        .where((q) => q.level1Title == level1Title)
        .toList();
  }

  // 获取所有一级分类
  static Set<String> getAllLevel1Titles(List<Question> questions) {
    return questions.map((q) => q.level1Title).toSet();
  }

  // 获取所有标签
  static Set<String> getAllTags(List<Question> questions) {
    final tags = <String>{};
    for (var q in questions) {
      tags.addAll(q.allTags);
    }
    return tags;
  }

  // 按标签筛选题目
  static List<Question> getQuestionsByTag(
    List<Question> allQuestions,
    String tag,
  ) {
    return allQuestions.where((q) => q.allTags.contains(tag)).toList();
  }

  // 按热度筛选题目（至少被n个学校考过）
  static List<Question> getQuestionsByMinPopularity(
    List<Question> allQuestions,
    int minPopularity,
  ) {
    return allQuestions
        .where((q) => q.popularity >= minPopularity)
        .toList();
  }
}
