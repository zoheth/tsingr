class StudyRecord {
  final int questionId;
  int studyCount;
  DateTime? lastStudyTime;
  bool isFavorite;
  String answer; // 用户作答内容
  String notes; // 用户笔记
  DateTime? lastModified; // 最后修改时间（用于同步冲突解决）

  StudyRecord({
    required this.questionId,
    this.studyCount = 0,
    this.lastStudyTime,
    this.isFavorite = false,
    this.answer = '',
    this.notes = '',
    this.lastModified,
  });

  // 增加学习次数
  void incrementStudy() {
    studyCount++;
    lastStudyTime = DateTime.now();
    lastModified = DateTime.now();
  }

  // 更新作答
  void updateAnswer(String newAnswer) {
    answer = newAnswer;
    lastModified = DateTime.now();
  }

  // 更新笔记
  void updateNotes(String newNotes) {
    notes = newNotes;
    lastModified = DateTime.now();
  }

  // 转换为JSON以便存储
  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'studyCount': studyCount,
      'lastStudyTime': lastStudyTime?.toIso8601String(),
      'isFavorite': isFavorite,
      'answer': answer,
      'notes': notes,
      'lastModified': lastModified?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  // 从JSON恢复
  factory StudyRecord.fromJson(Map<String, dynamic> json) {
    return StudyRecord(
      questionId: json['questionId'],
      studyCount: json['studyCount'] ?? 0,
      lastStudyTime: json['lastStudyTime'] != null
          ? DateTime.parse(json['lastStudyTime'])
          : null,
      isFavorite: json['isFavorite'] ?? false,
      answer: json['answer'] ?? '',
      notes: json['notes'] ?? '',
      lastModified: json['lastModified'] != null
          ? DateTime.parse(json['lastModified'])
          : null,
    );
  }

  // 合并两个记录（用于同步冲突解决）
  StudyRecord merge(StudyRecord other) {
    // 使用最后修改时间较新的数据
    final useThis = lastModified?.isAfter(other.lastModified ?? DateTime(1970)) ?? false;

    return StudyRecord(
      questionId: questionId,
      studyCount: studyCount > other.studyCount ? studyCount : other.studyCount,
      lastStudyTime: _laterDateTime(lastStudyTime, other.lastStudyTime),
      isFavorite: useThis ? isFavorite : other.isFavorite,
      answer: useThis ? answer : other.answer,
      notes: useThis ? notes : other.notes,
      lastModified: _laterDateTime(lastModified, other.lastModified),
    );
  }

  static DateTime? _laterDateTime(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isAfter(b) ? a : b;
  }
}
