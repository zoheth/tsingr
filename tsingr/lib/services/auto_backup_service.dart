import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'export_import_service.dart';
import '../models/study_record.dart';

/// 自动备份服务
/// 在应用文档目录自动创建备份，防止数据丢失
class AutoBackupService {
  static const int maxBackupDays = 7; // 保留最近7天的备份

  /// 自动备份到应用文档目录
  static Future<String?> autoBackup(Map<int, StudyRecord> records) async {
    if (records.isEmpty) {
      debugPrint('自动备份: 无数据需要备份');
      return null;
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/backups');

      // 创建备份目录
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      // 检查今天是否已备份
      final today = DateTime.now();
      final fileName = 'auto_backup_${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}.json';
      final filePath = '${backupDir.path}/$fileName';

      // 如果今天已经备份过，跳过
      if (await File(filePath).exists()) {
        debugPrint('自动备份: 今日已备份，跳过');
        return filePath;
      }

      // 清理旧备份
      await _cleanOldBackups(backupDir);

      // 创建今日备份
      final file = await ExportImportService.exportToFile(records, filePath);

      debugPrint('自动备份成功: ${file.path} (${records.length}条记录)');
      return file.path;
    } catch (e) {
      debugPrint('自动备份失败: $e');
      return null;
    }
  }

  /// 清理旧备份（保留最近N天）
  static Future<void> _cleanOldBackups(Directory backupDir) async {
    try {
      final now = DateTime.now();
      final entities = await backupDir.list().toList();

      for (var entity in entities) {
        if (entity is File && entity.path.endsWith('.json')) {
          final stat = await entity.stat();
          final age = now.difference(stat.modified).inDays;

          if (age > maxBackupDays) {
            await entity.delete();
            debugPrint('删除旧备份: ${entity.path} (${age}天前)');
          }
        }
      }
    } catch (e) {
      debugPrint('清理旧备份失败: $e');
    }
  }

  /// 获取所有备份文件列表
  static Future<List<BackupFile>> listBackups() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/backups');

      if (!await backupDir.exists()) {
        return [];
      }

      final entities = await backupDir.list().toList();
      final backups = <BackupFile>[];

      for (var entity in entities) {
        if (entity is File && entity.path.endsWith('.json')) {
          final stat = await entity.stat();
          final size = stat.size;

          // 尝试读取文件获取记录数
          int recordCount = 0;
          try {
            final content = await entity.readAsString();
            final records = ExportImportService.importFromJson(content);
            recordCount = records.length;
          } catch (e) {
            debugPrint('读取备份文件失败: ${entity.path}');
          }

          backups.add(BackupFile(
            path: entity.path,
            fileName: entity.uri.pathSegments.last,
            createdTime: stat.modified,
            size: size,
            recordCount: recordCount,
          ));
        }
      }

      // 按时间倒序排序
      backups.sort((a, b) => b.createdTime.compareTo(a.createdTime));

      return backups;
    } catch (e) {
      debugPrint('获取备份列表失败: $e');
      return [];
    }
  }

  /// 恢复指定的备份文件
  static Future<Map<int, StudyRecord>?> restoreBackup(String filePath) async {
    try {
      final file = File(filePath);

      if (!await file.exists()) {
        throw Exception('备份文件不存在');
      }

      final records = await ExportImportService.importFromFile(filePath);
      debugPrint('恢复备份成功: $filePath (${records.length}条记录)');
      return records;
    } catch (e) {
      debugPrint('恢复备份失败: $e');
      return null;
    }
  }

  /// 恢复最近的备份
  static Future<Map<int, StudyRecord>?> restoreLatestBackup() async {
    try {
      final backups = await listBackups();

      if (backups.isEmpty) {
        debugPrint('没有可用的备份文件');
        return null;
      }

      final latestBackup = backups.first;
      return await restoreBackup(latestBackup.path);
    } catch (e) {
      debugPrint('恢复最近备份失败: $e');
      return null;
    }
  }

  /// 删除指定备份
  static Future<bool> deleteBackup(String filePath) async {
    try {
      final file = File(filePath);

      if (await file.exists()) {
        await file.delete();
        debugPrint('删除备份: $filePath');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('删除备份失败: $e');
      return false;
    }
  }

  /// 删除所有备份
  static Future<void> deleteAllBackups() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/backups');

      if (await backupDir.exists()) {
        await backupDir.delete(recursive: true);
        debugPrint('已删除所有自动备份');
      }
    } catch (e) {
      debugPrint('删除所有备份失败: $e');
    }
  }

  /// 获取备份目录大小
  static Future<int> getBackupDirectorySize() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/backups');

      if (!await backupDir.exists()) {
        return 0;
      }

      int totalSize = 0;
      final entities = await backupDir.list().toList();

      for (var entity in entities) {
        if (entity is File) {
          final stat = await entity.stat();
          totalSize += stat.size;
        }
      }

      return totalSize;
    } catch (e) {
      debugPrint('获取备份目录大小失败: $e');
      return 0;
    }
  }

  /// 格式化文件大小
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}

/// 备份文件信息
class BackupFile {
  final String path;
  final String fileName;
  final DateTime createdTime;
  final int size;
  final int recordCount;

  BackupFile({
    required this.path,
    required this.fileName,
    required this.createdTime,
    required this.size,
    required this.recordCount,
  });

  String get formattedSize => AutoBackupService.formatFileSize(size);

  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(createdTime);

    if (diff.inDays == 0) {
      return '今天 ${createdTime.hour.toString().padLeft(2, '0')}:${createdTime.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return '昨天';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    } else {
      return '${createdTime.year}-${createdTime.month.toString().padLeft(2, '0')}-${createdTime.day.toString().padLeft(2, '0')}';
    }
  }
}
