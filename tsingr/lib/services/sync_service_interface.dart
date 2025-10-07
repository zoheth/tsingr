import '../models/study_record.dart';

/// 抽象同步服务接口
/// 支持本地存储、Firebase、WebDAV等多种实现
abstract class SyncServiceInterface {
  /// 同步所有数据到云端
  Future<void> syncToCloud(Map<int, StudyRecord> records);

  /// 从云端拉取数据
  Future<Map<int, StudyRecord>> syncFromCloud();

  /// 合并本地和云端数据
  Future<Map<int, StudyRecord>> mergeData(
    Map<int, StudyRecord> localRecords,
    Map<int, StudyRecord> cloudRecords,
  );

  /// 检查是否已认证/已登录
  Future<bool> isAuthenticated();

  /// 获取当前用户标识（用于区分不同用户的数据）
  Future<String?> getUserId();
}

/// 同步结果
class SyncResult {
  final bool success;
  final String message;
  final Map<int, StudyRecord>? mergedRecords;
  final SyncStats? stats;

  SyncResult({
    required this.success,
    required this.message,
    this.mergedRecords,
    this.stats,
  });
}

/// 同步统计信息
class SyncStats {
  final int uploaded;
  final int downloaded;
  final int merged;
  final int conflicts;

  SyncStats({
    required this.uploaded,
    required this.downloaded,
    required this.merged,
    required this.conflicts,
  });
}
