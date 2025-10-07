class StudyRecord {
  final int questionId;
  int studyCount;
  DateTime? lastStudyTime;
  bool isFavorite;

  StudyRecord({
    required this.questionId,
    this.studyCount = 0,
    this.lastStudyTime,
    this.isFavorite = false,
  });

  // 增加学习次数
  void incrementStudy() {
    studyCount++;
    lastStudyTime = DateTime.now();
  }

  // 转换为JSON以便存储
  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'studyCount': studyCount,
      'lastStudyTime': lastStudyTime?.toIso8601String(),
      'isFavorite': isFavorite,
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
    );
  }
}
