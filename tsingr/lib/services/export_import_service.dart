import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/study_record.dart';
import 'storage_service.dart';

/// 数据导入导出服务
class ExportImportService {
  /// 导出数据到JSON字符串
  static String exportToJson(Map<int, StudyRecord> records) {
    final exportData = {
      'version': '1.0.0',
      'exportTime': DateTime.now().toIso8601String(),
      'recordCount': records.length,
      'records': records.map(
        (key, value) => MapEntry(key.toString(), value.toJson()),
      ),
    };

    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  /// 从JSON字符串导入数据
  static Map<int, StudyRecord> importFromJson(String jsonString) {
    try {
      final Map<String, dynamic> importData = jsonDecode(jsonString);

      // 验证数据格式
      if (!importData.containsKey('records')) {
        throw Exception('无效的数据格式：缺少 records 字段');
      }

      final Map<String, dynamic> recordsMap = importData['records'];

      return recordsMap.map(
        (key, value) => MapEntry(
          int.parse(key),
          StudyRecord.fromJson(value),
        ),
      );
    } catch (e) {
      throw Exception('导入失败：$e');
    }
  }

  /// 导出数据到文件
  static Future<File> exportToFile(
    Map<int, StudyRecord> records,
    String filePath,
  ) async {
    try {
      final jsonString = exportToJson(records);
      final file = File(filePath);

      // 确保目录存在
      await file.parent.create(recursive: true);

      // 写入文件
      await file.writeAsString(jsonString);

      debugPrint('数据已导出到: $filePath');
      return file;
    } catch (e) {
      throw Exception('导出文件失败：$e');
    }
  }

  /// 从文件导入数据
  static Future<Map<int, StudyRecord>> importFromFile(String filePath) async {
    try {
      final file = File(filePath);

      if (!await file.exists()) {
        throw Exception('文件不存在：$filePath');
      }

      final jsonString = await file.readAsString();
      return importFromJson(jsonString);
    } catch (e) {
      throw Exception('导入文件失败：$e');
    }
  }

  /// 合并两个记录集（用于导入时合并数据）
  static Map<int, StudyRecord> mergeRecords(
    Map<int, StudyRecord> existing,
    Map<int, StudyRecord> imported, {
    MergeStrategy strategy = MergeStrategy.smart,
  }) {
    final merged = Map<int, StudyRecord>.from(existing);

    for (var entry in imported.entries) {
      final questionId = entry.key;
      final importedRecord = entry.value;

      if (!merged.containsKey(questionId)) {
        // 新记录，直接添加
        merged[questionId] = importedRecord;
      } else {
        // 已存在，根据策略合并
        final existingRecord = merged[questionId]!;

        switch (strategy) {
          case MergeStrategy.keepLocal:
            // 保持本地数据不变
            break;

          case MergeStrategy.overwriteWithImported:
            // 用导入数据覆盖
            merged[questionId] = importedRecord;
            break;

          case MergeStrategy.smart:
            // 智能合并（使用StudyRecord的merge方法）
            merged[questionId] = existingRecord.merge(importedRecord);
            break;
        }
      }
    }

    return merged;
  }

  /// 执行完整的导入流程（包括合并和保存）
  static Future<ImportResult> performImport(
    String jsonString, {
    MergeStrategy strategy = MergeStrategy.smart,
  }) async {
    try {
      // 解析导入数据
      final importedRecords = importFromJson(jsonString);

      // 加载现有数据
      final existingRecords = await StorageService.loadRecords();

      // 合并数据
      final mergedRecords = mergeRecords(
        existingRecords,
        importedRecords,
        strategy: strategy,
      );

      // 保存合并后的数据
      await StorageService.saveRecords(mergedRecords);

      // 统计信息
      final stats = ImportStats(
        totalImported: importedRecords.length,
        newRecords: importedRecords.length - existingRecords.length,
        updatedRecords: existingRecords.length,
        finalTotal: mergedRecords.length,
      );

      return ImportResult(
        success: true,
        message: '导入成功',
        stats: stats,
      );
    } catch (e) {
      return ImportResult(
        success: false,
        message: '导入失败：$e',
        stats: null,
      );
    }
  }

  /// 生成导出文件名（带时间戳）
  static String generateExportFileName() {
    final now = DateTime.now();
    final timestamp = '${now.year}${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}';
    return 'tsingr_backup_$timestamp.json';
  }
}

/// 合并策略
enum MergeStrategy {
  /// 保持本地数据
  keepLocal,

  /// 用导入数据覆盖
  overwriteWithImported,

  /// 智能合并（保留学习次数最多的，使用最新修改时间）
  smart,
}

/// 导入结果
class ImportResult {
  final bool success;
  final String message;
  final ImportStats? stats;

  ImportResult({
    required this.success,
    required this.message,
    this.stats,
  });
}

/// 导入统计信息
class ImportStats {
  final int totalImported; // 导入文件中的记录数
  final int newRecords; // 新增的记录数
  final int updatedRecords; // 更新的记录数
  final int finalTotal; // 合并后的总记录数

  ImportStats({
    required this.totalImported,
    required this.newRecords,
    required this.updatedRecords,
    required this.finalTotal,
  });
}
