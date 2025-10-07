import 'package:flutter/foundation.dart';
import '../models/question.dart';
import '../models/study_record.dart';
import '../services/data_service.dart';
import '../services/storage_service.dart';
import '../services/auto_backup_service.dart';
import '../services/data_migration_service.dart';

class StudyProvider extends ChangeNotifier {
  List<Question> _allQuestions = [];
  Map<int, StudyRecord> _studyRecords = {};
  bool _isLoading = true;
  String _filterTag = '';
  int _minPopularity = 0;
  String _searchKeyword = '';
  String _filterLevel1 = '';
  String _filterLevel2 = '';

  List<Question> get allQuestions => _allQuestions;
  Map<int, StudyRecord> get studyRecords => _studyRecords;
  bool get isLoading => _isLoading;
  String get filterTag => _filterTag;
  int get minPopularity => _minPopularity;
  String get filterLevel1 => _filterLevel1;
  String get filterLevel2 => _filterLevel2;

  // 获取筛选后的题目列表
  List<Question> get filteredQuestions {
    var questions = _allQuestions;

    // 按一级分类筛选
    if (_filterLevel1.isNotEmpty) {
      questions = questions.where((q) => q.level1Title == _filterLevel1).toList();
    }

    // 按二级分类筛选
    if (_filterLevel2.isNotEmpty) {
      questions = questions.where((q) => q.level2Title == _filterLevel2).toList();
    }

    // 按标签筛选
    if (_filterTag.isNotEmpty) {
      questions = DataService.getQuestionsByTag(questions, _filterTag);
    }

    // 按热度筛选
    if (_minPopularity > 0) {
      questions = DataService.getQuestionsByMinPopularity(questions, _minPopularity);
    }

    // 按搜索关键词筛选
    if (_searchKeyword.isNotEmpty) {
      questions = questions.where((q) =>
          q.content.contains(_searchKeyword) ||
          q.level1Title.contains(_searchKeyword) ||
          q.level2Title.contains(_searchKeyword)
      ).toList();
    }

    return questions;
  }

  // 获取所有标签
  Set<String> get allTags => DataService.getAllTags(_allQuestions);

  // 获取所有一级分类（按序号排序）
  List<String> get allLevel1Categories {
    final categories = _allQuestions.map((q) => q.level1Title).toSet().toList();
    categories.sort((a, b) {
      final orderA = Question.extractOrderNumber(a, true);
      final orderB = Question.extractOrderNumber(b, true);
      return orderA.compareTo(orderB);
    });
    return categories;
  }

  // 获取所有二级分类（根据当前选中的一级分类，按序号排序）
  List<String> get allLevel2Categories {
    List<String> categories;
    if (_filterLevel1.isEmpty) {
      categories = _allQuestions.map((q) => q.level2Title).toSet().toList();
    } else {
      categories = _allQuestions
          .where((q) => q.level1Title == _filterLevel1)
          .map((q) => q.level2Title)
          .toSet()
          .toList();
    }
    categories.sort((a, b) {
      final orderA = Question.extractOrderNumber(a, false);
      final orderB = Question.extractOrderNumber(b, false);
      return orderA.compareTo(orderB);
    });
    return categories;
  }

  // 统计数据
  int get totalQuestions => _allQuestions.length;
  int get studiedQuestions => _studyRecords.values.where((r) => r.studyCount > 0).length;
  int get totalStudyCount => _studyRecords.values.fold(0, (sum, r) => sum + r.studyCount);
  int get favoritesCount => _studyRecords.values.where((r) => r.isFavorite).length;

  // 初始化数据
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. 检查并执行数据迁移
      final migrationResult = await DataMigrationService.checkAndMigrate();
      if (!migrationResult.success) {
        debugPrint('数据迁移失败: ${migrationResult.message}');
      }

      // 2. 加载题目数据
      _allQuestions = await DataService.loadQuestions();

      // 3. 尝试加载学习记录
      try {
        _studyRecords = await StorageService.loadRecords();
      } catch (e) {
        debugPrint('加载学习记录失败，尝试从备份恢复: $e');

        // 4. 如果加载失败，尝试从自动备份恢复
        final backupRecords = await AutoBackupService.restoreLatestBackup();
        if (backupRecords != null) {
          _studyRecords = backupRecords;
          await StorageService.saveRecords(_studyRecords);
          debugPrint('已从自动备份恢复 ${_studyRecords.length} 条记录');
        } else {
          _studyRecords = {};
          debugPrint('无可用备份，初始化为空记录');
        }
      }

      // 5. 执行自动备份（每次启动时）
      if (_studyRecords.isNotEmpty) {
        await AutoBackupService.autoBackup(_studyRecords);
      }
    } catch (e) {
      debugPrint('初始化失败: $e');
      _studyRecords = {};
    }

    _isLoading = false;
    notifyListeners();
  }

  // 获取某题的学习记录
  StudyRecord getRecord(int questionId) {
    return _studyRecords[questionId] ??
        StudyRecord(questionId: questionId);
  }

  // 标记题目为已学习
  Future<void> markAsStudied(int questionId) async {
    final record = getRecord(questionId);
    record.incrementStudy();
    _studyRecords[questionId] = record;
    await StorageService.saveRecord(record);
    notifyListeners();
  }

  // 切换收藏状态
  Future<void> toggleFavorite(int questionId) async {
    final record = getRecord(questionId);
    record.isFavorite = !record.isFavorite;
    record.lastModified = DateTime.now();
    _studyRecords[questionId] = record;
    await StorageService.saveRecord(record);
    notifyListeners();
  }

  // 更新作答内容
  Future<void> updateAnswer(int questionId, String answer) async {
    final record = getRecord(questionId);
    record.updateAnswer(answer);
    _studyRecords[questionId] = record;
    await StorageService.saveRecord(record);
    notifyListeners();
  }

  // 更新笔记内容
  Future<void> updateNotes(int questionId, String notes) async {
    final record = getRecord(questionId);
    record.updateNotes(notes);
    _studyRecords[questionId] = record;
    await StorageService.saveRecord(record);
    notifyListeners();
  }

  // 设置标签筛选
  void setFilterTag(String tag) {
    _filterTag = tag;
    notifyListeners();
  }

  // 设置热度筛选
  void setMinPopularity(int popularity) {
    _minPopularity = popularity;
    notifyListeners();
  }

  // 设置搜索关键词
  void setSearchKeyword(String keyword) {
    _searchKeyword = keyword;
    notifyListeners();
  }

  // 设置一级分类筛选
  void setFilterLevel1(String category) {
    _filterLevel1 = category;
    // 如果切换了一级分类，清除二级分类筛选
    if (_filterLevel2.isNotEmpty) {
      final level2List = allLevel2Categories;
      if (!level2List.contains(_filterLevel2)) {
        _filterLevel2 = '';
      }
    }
    notifyListeners();
  }

  // 设置二级分类筛选
  void setFilterLevel2(String category) {
    _filterLevel2 = category;
    notifyListeners();
  }

  // 清除所有筛选
  void clearFilters() {
    _filterTag = '';
    _minPopularity = 0;
    _searchKeyword = '';
    _filterLevel1 = '';
    _filterLevel2 = '';
    notifyListeners();
  }

  // 获取收藏的题目
  List<Question> get favoriteQuestions {
    return _allQuestions.where((q) {
      final record = _studyRecords[q.id];
      return record != null && record.isFavorite;
    }).toList();
  }

  // 获取已学习的题目
  List<Question> get studiedQuestionsList {
    return _allQuestions.where((q) {
      final record = _studyRecords[q.id];
      return record != null && record.studyCount > 0;
    }).toList();
  }

  // 清除所有学习记录
  Future<void> clearAllRecords() async {
    await StorageService.clearAllRecords();
    _studyRecords.clear();
    notifyListeners();
  }
}
