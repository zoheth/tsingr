import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../providers/study_provider.dart';
import '../services/export_import_service.dart';
import '../services/auto_backup_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isExporting = false;
  bool _isImporting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        children: [
          // 数据管理分组
          _buildSectionHeader('数据管理'),
          _buildDataManagementSection(),

          const Divider(height: 32),

          // 同步设置分组（预留给Firebase）
          _buildSectionHeader('云同步设置'),
          _buildSyncSection(),

          const Divider(height: 32),

          // 关于信息
          _buildSectionHeader('关于'),
          _buildAboutSection(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildDataManagementSection() {
    return Consumer<StudyProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            // 导出数据
            ListTile(
              leading: const Icon(Icons.upload_file, color: Colors.blue),
              title: const Text('导出学习数据'),
              subtitle: Text('将数据导出为JSON文件，可在其他设备导入'),
              trailing: _isExporting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _isExporting ? null : () => _exportData(provider),
            ),

            // 导入数据
            ListTile(
              leading: const Icon(Icons.download, color: Colors.green),
              title: const Text('导入学习数据'),
              subtitle: const Text('从JSON文件导入数据，智能合并'),
              trailing: _isImporting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _isImporting ? null : () => _importData(provider),
            ),

            // 自动备份管理（新增）
            ListTile(
              leading: const Icon(Icons.history, color: Colors.purple),
              title: const Text('自动备份管理'),
              subtitle: const Text('查看和恢复应用自动创建的备份'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showAutoBackupDialog(provider),
            ),

            // 数据统计
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.grey),
              title: const Text('本地数据统计'),
              subtitle: Text(
                '总题数: ${provider.totalQuestions} | '
                '已学: ${provider.studiedQuestions} | '
                '收藏: ${provider.favoritesCount}',
              ),
            ),

            // 清除数据
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('清除所有学习数据'),
              subtitle: const Text('删除所有学习记录、笔记和作答（危险操作）'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _confirmClearData(provider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSyncSection() {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.cloud_off, color: Colors.grey),
          title: const Text('云同步'),
          subtitle: const Text('未启用（即将支持Firebase自动同步）'),
          trailing: Switch(
            value: false,
            onChanged: null, // 预留给Firebase功能
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            '提示：当前可使用"导出/导入"功能在设备间手动同步数据。',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.app_settings_alt),
          title: const Text('应用版本'),
          subtitle: const Text('v1.0.0'),
        ),
        ListTile(
          leading: const Icon(Icons.school),
          title: const Text('TsingR 刷题助手'),
          subtitle: const Text('传播学考研题库与学习工具'),
        ),
      ],
    );
  }

  /// 导出数据
  Future<void> _exportData(StudyProvider provider) async {
    setState(() => _isExporting = true);

    try {
      // 1. 生成JSON数据 (不变)
      final jsonString = ExportImportService.exportToJson(provider.studyRecords);
      final fileName = ExportImportService.generateExportFileName();

      // 2. 将字符串编码为字节 (关键步骤)
      final bytes = utf8.encode(jsonString);

      // 3. 调用 saveFile 并直接提供文件名和字节数据
      //    此方法现在统一适用于所有平台 (Android, iOS, Web, Desktop)
      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: '保存学习数据',
        fileName: fileName,
        bytes: bytes, // <--- 关键参数，现在对所有平台都是必需的
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      // 4. 处理用户取消操作
      if (outputPath == null) {
        // 用户取消了保存对话框
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('已取消导出'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.grey,
            ),
          );
        }
        return; // 提前返回，不再执行后续代码
      }

      // 5. 显示成功提示
      //    文件已经由 file_picker 插件成功保存，我们无需再进行任何文件写入操作
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导出成功！\n${provider.studyRecords.length} 条记录已保存'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: '好的',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导出失败：$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // 确保无论成功、失败还是取消，导出状态都会被重置
      if(mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  /// 导入数据
  Future<void> _importData(StudyProvider provider) async {
    // 显示导入策略选择对话框
    final strategy = await _showMergeStrategyDialog();
    if (strategy == null) return; // 用户取消策略选择

    setState(() => _isImporting = true);

    try {
      // 1. 选择文件 (这部分不变)
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: '选择要导入的数据文件',
        withData: true, // 在移动端也请求文件数据，以便统一处理（可选但推荐）
      );

      // 2. 检查用户是否取消了文件选择
      if (result == null) {
        // setState(() => _isImporting = false); // finally 块会处理
        return;
      }

      // 3. 读取文件内容（平台特定逻辑）
      String jsonString;
      final platformFile = result.files.single;

      if (kIsWeb) {
        // WEB 平台：从 bytes 属性读取
        if (platformFile.bytes == null) {
          throw Exception("在Web上未能读取到文件数据。");
        }
        // 将字节数据解码为UTF-8字符串
        jsonString = utf8.decode(platformFile.bytes!);
      } else {
        // 移动/桌面平台：从 path 属性读取
        if (platformFile.path == null) {
          throw Exception("在移动端未能获取到文件路径。");
        }
        final file = File(platformFile.path!);
        jsonString = await file.readAsString();
      }

      // 4. 执行导入 (后续逻辑不变)
      final importResult = await ExportImportService.performImport(
        jsonString,
        strategy: strategy,
      );

      // 5. 显示结果 (后续逻辑不变)
      if (mounted) {
        if (importResult.success) {
          await provider.initialize();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '导入成功！\n'
                '导入: ${importResult.stats!.totalImported} 条\n'
                '新增: ${importResult.stats!.newRecords} 条\n'
                '总计: ${importResult.stats!.finalTotal} 条',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(importResult.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导入失败：$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  /// 显示合并策略选择对话框
  Future<MergeStrategy?> _showMergeStrategyDialog() async {
    return showDialog<MergeStrategy>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('选择导入方式'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('如何处理已存在的题目数据？'),
              const SizedBox(height: 16),
              _buildStrategyOption(
                MergeStrategy.smart,
                '智能合并',
                '推荐：保留学习次数最多的，使用最新的笔记',
                Colors.blue,
              ),
              const SizedBox(height: 8),
              _buildStrategyOption(
                MergeStrategy.overwriteWithImported,
                '覆盖本地',
                '用导入的数据完全替换本地数据',
                Colors.orange,
              ),
              const SizedBox(height: 8),
              _buildStrategyOption(
                MergeStrategy.keepLocal,
                '保留本地',
                '只导入本地没有的新题目',
                Colors.green,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStrategyOption(
    MergeStrategy strategy,
    String title,
    String description,
    Color color,
  ) {
    return InkWell(
      onTap: () => Navigator.pop(context, strategy),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.radio_button_unchecked, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 确认清除数据
  Future<void> _confirmClearData(StudyProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text('危险操作'),
            ],
          ),
          content: const Text(
            '确定要清除所有学习数据吗？\n\n'
            '这将删除：\n'
            '• 所有学习记录\n'
            '• 所有笔记和作答\n'
            '• 所有收藏\n\n'
            '此操作不可恢复！建议先导出备份。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('确定清除'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await provider.clearAllRecords();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('所有数据已清除'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('清除失败：$e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// 显示自动备份管理对话框
  Future<void> _showAutoBackupDialog(StudyProvider provider) async {
    final backups = await AutoBackupService.listBackups();
    final totalSize = await AutoBackupService.getBackupDirectorySize();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.backup, color: Colors.purple),
              const SizedBox(width: 8),
              const Text('自动备份'),
              const Spacer(),
              if (backups.isNotEmpty)
                Chip(
                  label: Text(
                    AutoBackupService.formatFileSize(totalSize),
                    style: const TextStyle(fontSize: 12),
                  ),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: backups.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        '暂无自动备份\n\n应用会在每次启动时自动创建备份',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '自动备份会保留最近${AutoBackupService.maxBackupDays}天的数据',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: backups.length,
                          itemBuilder: (context, index) {
                            final backup = backups[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const Icon(Icons.file_present, color: Colors.purple),
                                title: Text(backup.formattedDate),
                                subtitle: Text(
                                  '${backup.recordCount} 条记录 · ${backup.formattedSize}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: PopupMenuButton(
                                  icon: const Icon(Icons.more_vert),
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'restore',
                                      child: Row(
                                        children: [
                                          Icon(Icons.restore, size: 18),
                                          SizedBox(width: 8),
                                          Text('恢复此备份'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, size: 18, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('删除'),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onSelected: (value) async {
                                    Navigator.pop(context);
                                    if (value == 'restore') {
                                      await _restoreAutoBackup(backup.path, provider);
                                    } else if (value == 'delete') {
                                      await AutoBackupService.deleteBackup(backup.path);
                                      _showAutoBackupDialog(provider);
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
          actions: [
            if (backups.isNotEmpty)
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('确认删除'),
                      content: const Text('确定要删除所有自动备份吗？'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('取消'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('删除'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    await AutoBackupService.deleteAllBackups();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('已删除所有自动备份')),
                      );
                    }
                  }
                },
                child: const Text('删除全部'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }

  /// 恢复自动备份
  Future<void> _restoreAutoBackup(String backupPath, StudyProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('恢复备份'),
        content: const Text(
          '确定要恢复此备份吗？\n\n'
          '当前数据将与备份数据智能合并。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('恢复'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final backupRecords = await AutoBackupService.restoreBackup(backupPath);

      if (backupRecords == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('恢复失败：无法读取备份文件'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // 与当前数据合并
      final mergedRecords = ExportImportService.mergeRecords(
        provider.studyRecords,
        backupRecords,
        strategy: MergeStrategy.smart,
      );

      // 保存合并后的数据
      await provider.initialize();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '恢复成功！\n备份: ${backupRecords.length} 条\n合并后: ${mergedRecords.length} 条',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('恢复失败：$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
