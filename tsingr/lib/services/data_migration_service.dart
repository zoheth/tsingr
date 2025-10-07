import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'storage_service.dart';

/// 数据迁移服务
/// 负责应用版本升级时的数据格式迁移和兼容性处理
class DataMigrationService {
  static const String _versionKey = 'app_data_version';
  static const String _currentVersion = '1.0.0';

  /// 检查并执行数据迁移
  static Future<MigrationResult> checkAndMigrate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final oldVersion = prefs.getString(_versionKey);

      if (oldVersion == null) {
        // 首次安装
        await prefs.setString(_versionKey, _currentVersion);
        debugPrint('数据迁移: 首次安装，版本 $_currentVersion');

        return MigrationResult(
          success: true,
          fromVersion: null,
          toVersion: _currentVersion,
          message: '首次安装',
          isFirstInstall: true,
        );
      }

      if (oldVersion == _currentVersion) {
        // 版本相同，无需迁移
        debugPrint('数据迁移: 版本相同 ($_currentVersion)，无需迁移');
        return MigrationResult(
          success: true,
          fromVersion: oldVersion,
          toVersion: _currentVersion,
          message: '版本相同，无需迁移',
        );
      }

      // 需要迁移
      debugPrint('数据迁移: 开始迁移 $oldVersion -> $_currentVersion');

      final migrationSteps = await _performMigration(oldVersion, _currentVersion);

      await prefs.setString(_versionKey, _currentVersion);

      return MigrationResult(
        success: true,
        fromVersion: oldVersion,
        toVersion: _currentVersion,
        message: '迁移成功',
        migrationSteps: migrationSteps,
      );
    } catch (e) {
      debugPrint('数据迁移失败: $e');
      return MigrationResult(
        success: false,
        fromVersion: null,
        toVersion: _currentVersion,
        message: '迁移失败: $e',
      );
    }
  }

  /// 执行数据迁移
  static Future<List<String>> _performMigration(String from, String to) async {
    final steps = <String>[];

    // 解析版本号
    final fromParts = from.split('.').map(int.parse).toList();
    final toParts = to.split('.').map(int.parse).toList();

    // 从 v1.0.0 到 v1.1.0 的迁移示例
    if (_isVersionUpgrade(fromParts, [1, 0, 0], toParts, [1, 1, 0])) {
      steps.add(await _migrateV1_0_to_V1_1());
    }

    // 未来版本迁移可以在这里添加
    // if (_isVersionUpgrade(fromParts, [1, 1, 0], toParts, [1, 2, 0])) {
    //   steps.add(await _migrateV1_1_to_V1_2());
    // }

    return steps;
  }

  /// 判断是否需要执行特定版本的迁移
  static bool _isVersionUpgrade(
    List<int> from,
    List<int> minFrom,
    List<int> to,
    List<int> minTo,
  ) {
    return _compareVersions(from, minFrom) >= 0 && _compareVersions(to, minTo) >= 0;
  }

  /// 比较版本号
  static int _compareVersions(List<int> v1, List<int> v2) {
    for (int i = 0; i < 3; i++) {
      if (v1[i] > v2[i]) return 1;
      if (v1[i] < v2[i]) return -1;
    }
    return 0;
  }

  /// v1.0.0 到 v1.1.0 的迁移
  static Future<String> _migrateV1_0_to_V1_1() async {
    debugPrint('执行迁移: v1.0.0 -> v1.1.0');

    try {
      final records = await StorageService.loadRecords();

      // 由于 StudyRecord.fromJson 使用了 ?? 默认值
      // 旧版本数据会自动兼容新字段
      // 这里可以做一些额外的数据处理或验证

      // 验证数据完整性
      int validRecords = 0;
      for (var record in records.values) {
        if (record.questionId > 0) {
          validRecords++;
        }
      }

      // 重新保存（确保新格式）
      await StorageService.saveRecords(records);

      final message = '迁移 v1.0.0 -> v1.1.0: 验证 $validRecords 条记录';
      debugPrint(message);
      return message;
    } catch (e) {
      final message = '迁移 v1.0.0 -> v1.1.0 失败: $e';
      debugPrint(message);
      return message;
    }
  }

  /// 获取当前数据版本
  static Future<String?> getCurrentDataVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_versionKey);
  }

  /// 重置数据版本（用于测试）
  static Future<void> resetDataVersion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_versionKey);
    debugPrint('数据版本已重置');
  }
}

/// 迁移结果
class MigrationResult {
  final bool success;
  final String? fromVersion;
  final String toVersion;
  final String message;
  final bool isFirstInstall;
  final List<String> migrationSteps;

  MigrationResult({
    required this.success,
    required this.fromVersion,
    required this.toVersion,
    required this.message,
    this.isFirstInstall = false,
    this.migrationSteps = const [],
  });

  @override
  String toString() {
    return 'MigrationResult(success: $success, from: $fromVersion, to: $toVersion, message: $message)';
  }
}
