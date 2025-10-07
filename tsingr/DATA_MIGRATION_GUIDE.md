# 数据迁移与版本更新指南

## 📌 数据存储位置

### SharedPreferences 存储路径
- **Android**: `/data/data/com.tsingr.app/shared_prefs/`
- **iOS**: `Library/Preferences/`
- **Windows**: 注册表
- **Linux**: `~/.local/share/`
- **macOS**: `~/Library/Preferences/`

### 存储的数据
- Key: `study_records`
- Value: JSON字符串（所有学习记录）

## ✅ 数据不丢失保证

### 1. 应用更新（App Update）

#### ✅ **正常更新 - 数据不会丢失**
当用户通过以下方式更新应用时，数据**会保留**：
- 应用商店更新（Google Play/App Store）
- 下载新版APK覆盖安装（Android，需要签名一致）
- Windows/macOS 覆盖安装

**原理：**
- SharedPreferences 存储在应用沙盒目录
- 覆盖安装不会清除应用数据
- 只有"卸载应用"才会清除数据

#### ❌ **会丢失数据的情况**
以下操作**会清除数据**：
1. **卸载后重装**（最常见）
2. **清除应用数据**（Android: 设置 → 应用 → 清除数据）
3. **恢复出厂设置**
4. **更换设备**

### 2. 数据格式升级

#### 版本兼容性设计

**当前版本（v1.0.0）数据格式：**
```json
{
  "questionId": 1,
  "studyCount": 5,
  "lastStudyTime": "2025-01-15T10:30:00.000Z",
  "isFavorite": true,
  "answer": "",
  "notes": "",
  "lastModified": "2025-01-15T11:00:00.000Z"
}
```

**未来版本如果新增字段（如 v1.1.0）：**
```json
{
  "questionId": 1,
  "studyCount": 5,
  "lastStudyTime": "2025-01-15T10:30:00.000Z",
  "isFavorite": true,
  "answer": "",
  "notes": "",
  "lastModified": "2025-01-15T11:00:00.000Z",
  "tags": [],           // 新增字段
  "difficulty": "easy"  // 新增字段
}
```

**兼容性保证：**
```dart
factory StudyRecord.fromJson(Map<String, dynamic> json) {
  return StudyRecord(
    questionId: json['questionId'],
    studyCount: json['studyCount'] ?? 0,
    lastStudyTime: json['lastStudyTime'] != null
        ? DateTime.parse(json['lastStudyTime'])
        : null,
    isFavorite: json['isFavorite'] ?? false,
    answer: json['answer'] ?? '',  // 使用 ?? 提供默认值
    notes: json['notes'] ?? '',    // 旧版本没有这个字段时用空字符串
    lastModified: json['lastModified'] != null
        ? DateTime.parse(json['lastModified'])
        : null,
    // 未来新增字段也用 ?? 提供默认值
    tags: json['tags'] ?? [],
    difficulty: json['difficulty'] ?? 'medium',
  );
}
```

## 🛡️ 数据保护策略

### 策略1：自动备份到导出文件

创建 `lib/services/auto_backup_service.dart`：

```dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'export_import_service.dart';
import '../models/study_record.dart';

class AutoBackupService {
  /// 自动备份到应用文档目录
  static Future<void> autoBackup(Map<int, StudyRecord> records) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/backups');

      // 创建备份目录
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      // 保留最近7天的备份
      await _cleanOldBackups(backupDir);

      // 创建今日备份
      final fileName = 'auto_backup_${DateTime.now().toIso8601String().split('T')[0]}.json';
      final filePath = '${backupDir.path}/$fileName';

      await ExportImportService.exportToFile(records, filePath);

      print('自动备份成功: $filePath');
    } catch (e) {
      print('自动备份失败: $e');
    }
  }

  /// 清理7天前的备份
  static Future<void> _cleanOldBackups(Directory backupDir) async {
    final now = DateTime.now();
    final files = await backupDir.list().toList();

    for (var entity in files) {
      if (entity is File) {
        final stat = await entity.stat();
        final age = now.difference(stat.modified).inDays;

        if (age > 7) {
          await entity.delete();
          print('删除旧备份: ${entity.path}');
        }
      }
    }
  }

  /// 恢复最近的备份
  static Future<Map<int, StudyRecord>?> restoreLatestBackup() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/backups');

      if (!await backupDir.exists()) {
        return null;
      }

      // 找到最新的备份文件
      final files = await backupDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.json'))
          .cast<File>()
          .toList();

      if (files.isEmpty) {
        return null;
      }

      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      final latestBackup = files.first;

      return await ExportImportService.importFromFile(latestBackup.path);
    } catch (e) {
      print('恢复备份失败: $e');
      return null;
    }
  }
}
```

### 策略2：版本号检测与迁移

创建 `lib/services/data_migration_service.dart`：

```dart
import 'package:shared_preferences/shared_preferences.dart';
import '../models/study_record.dart';
import 'storage_service.dart';

class DataMigrationService {
  static const String _versionKey = 'app_version';
  static const String _currentVersion = '1.0.0';

  /// 检查并执行数据迁移
  static Future<void> checkAndMigrate() async {
    final prefs = await SharedPreferences.getInstance();
    final oldVersion = prefs.getString(_versionKey);

    if (oldVersion == null) {
      // 首次安装
      await prefs.setString(_versionKey, _currentVersion);
      return;
    }

    if (oldVersion == _currentVersion) {
      // 版本相同，无需迁移
      return;
    }

    // 执行迁移
    await _performMigration(oldVersion, _currentVersion);
    await prefs.setString(_versionKey, _currentVersion);
  }

  /// 执行数据迁移
  static Future<void> _performMigration(String from, String to) async {
    print('数据迁移: $from -> $to');

    // 从 v1.0.0 到 v1.1.0 的迁移示例
    if (from == '1.0.0' && to == '1.1.0') {
      await _migrateV1_0_to_V1_1();
    }

    // 未来版本迁移可以在这里添加
    // if (from == '1.1.0' && to == '1.2.0') {
    //   await _migrateV1_1_to_V1_2();
    // }
  }

  /// v1.0.0 到 v1.1.0 的迁移
  static Future<void> _migrateV1_0_to_V1_1() async {
    final records = await StorageService.loadRecords();

    // 假设 v1.1.0 新增了 tags 字段
    // 由于 fromJson 使用了 ?? 默认值，旧数据会自动兼容
    // 这里可以做一些额外的数据处理

    await StorageService.saveRecords(records);
    print('迁移完成: v1.0.0 -> v1.1.0');
  }
}
```

### 策略3：在 StudyProvider 中集成保护机制

修改 `lib/providers/study_provider.dart`：

```dart
import '../services/auto_backup_service.dart';
import '../services/data_migration_service.dart';

class StudyProvider extends ChangeNotifier {
  // ... 现有代码 ...

  // 初始化数据
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. 检查并执行数据迁移
      await DataMigrationService.checkAndMigrate();

      // 2. 加载数据
      _allQuestions = await DataService.loadQuestions();
      _studyRecords = await StorageService.loadRecords();

      // 3. 自动备份（每次启动时）
      if (_studyRecords.isNotEmpty) {
        await AutoBackupService.autoBackup(_studyRecords);
      }
    } catch (e) {
      debugPrint('加载数据失败: $e');

      // 4. 尝试从自动备份恢复
      final backup = await AutoBackupService.restoreLatestBackup();
      if (backup != null) {
        _studyRecords = backup;
        await StorageService.saveRecords(_studyRecords);
        debugPrint('已从备份恢复数据');
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  // 保存时自动备份
  @override
  Future<void> markAsStudied(int questionId) async {
    // ... 现有代码 ...

    // 每隔一定次数自动备份
    if (_studyRecords.length % 10 == 0) {
      await AutoBackupService.autoBackup(_studyRecords);
    }
  }
}
```

## ⚠️ 重要注意事项

### 1. 应用签名一致性（Android）

**问题：** Android应用签名不一致会导致无法覆盖安装

**解决方案：**
```bash
# 生成签名密钥（仅首次）
keytool -genkey -v -keystore ~/key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias key

# 配置 android/app/build.gradle
signingConfigs {
    release {
        storeFile file("/path/to/key.jks")
        storePassword "password"
        keyAlias "key"
        keyPassword "password"
    }
}

buildTypes {
    release {
        signingConfig signingConfigs.release
    }
}
```

**⚠️ 警告：**
- 密钥文件丢失将无法更新应用！
- 必须妥善保管 `key.jks` 文件
- 建议备份到安全位置

### 2. iOS Bundle Identifier 一致性

**问题：** Bundle ID 不一致会被视为不同应用

**解决方案：**
- 在 `ios/Runner.xcodeproj` 中固定 Bundle Identifier
- 不要随意修改

### 3. 数据迁移测试

**升级前测试清单：**
```
□ 旧版本导出数据 → 新版本导入，验证完整性
□ 旧版本直接覆盖升级到新版本，验证数据保留
□ 新增字段的默认值是否合理
□ 数据格式变化是否向后兼容
```

### 4. 用户提示

在应用中添加更新提示：

```dart
// 在设置页面添加
ListTile(
  leading: Icon(Icons.backup),
  title: Text('数据备份建议'),
  subtitle: Text('更新前请导出数据备份，以防万一'),
  trailing: Icon(Icons.arrow_forward_ios),
  onTap: () {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('数据安全提示'),
        content: Text(
          '建议定期导出学习数据：\n\n'
          '1. 应用更新前导出一次\n'
          '2. 每周导出一次到云盘\n'
          '3. 更换设备前导出\n\n'
          '导出的数据可以在任何设备导入恢复。'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('知道了'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _exportData(provider);
            },
            child: Text('立即导出'),
          ),
        ],
      ),
    );
  },
)
```

## 📋 发布新版本检查清单

### 开发阶段
- [ ] 数据模型变更时使用 `?? 默认值`
- [ ] 新增字段标记为可选或提供默认值
- [ ] 编写数据迁移代码
- [ ] 更新版本号

### 测试阶段
- [ ] 旧版本 → 新版本覆盖安装测试
- [ ] 导出导入测试
- [ ] 自动备份恢复测试
- [ ] 多设备同步测试

### 发布前
- [ ] 更新 CHANGELOG.md
- [ ] 提醒用户导出备份
- [ ] 准备回滚方案
- [ ] 签名密钥备份确认

### 发布后
- [ ] 监控崩溃报告
- [ ] 收集数据迁移反馈
- [ ] 准备热修复（如有问题）

## 🆘 数据恢复方案

### 方案1：用户手动导出的备份
```
用户操作: 设置 → 导入学习数据 → 选择备份文件
```

### 方案2：应用自动备份
```
位置: /data/data/com.tsingr.app/files/backups/
用户操作: 设置 → 恢复自动备份 → 选择日期
```

### 方案3：云同步恢复（Firebase版本）
```
用户操作: 登录同一账号 → 自动从云端同步
```

## 💡 最佳实践总结

1. **向后兼容**
   - 新增字段用 `??` 提供默认值
   - 不删除旧字段，标记为 `@Deprecated` 并逐步迁移

2. **自动备份**
   - 应用启动时自动备份
   - 定期清理旧备份（保留7天）

3. **用户提示**
   - 更新前提示导出
   - 首次启动新版本时显示更新说明

4. **测试完备**
   - 升级路径测试（v1.0 → v1.1 → v1.2）
   - 跨版本导入测试

5. **密钥管理**
   - 签名密钥多地备份
   - 使用密钥管理服务

## 📞 应急响应

### 如果用户报告数据丢失：

1. **立即检查**
   - 应用是否被卸载重装
   - 是否清除了应用数据
   - 是否有导出的备份文件

2. **恢复步骤**
   ```
   a. 查找自动备份（如果应用未卸载）
   b. 导入用户的手动备份
   c. 联系用户获取云盘备份（如果有）
   ```

3. **改进措施**
   - 增加备份提醒频率
   - 添加云同步功能
   - 优化自动备份机制

## 🔍 版本兼容性矩阵

| 数据版本 | 应用版本 | 兼容性 | 说明 |
|---------|---------|--------|------|
| v1.0    | v1.0    | ✅ 完全兼容 | 当前版本 |
| v1.0    | v1.1    | ✅ 向前兼容 | 旧数据在新版本可用 |
| v1.1    | v1.0    | ⚠️ 部分兼容 | 新字段会丢失 |
| v1.0    | v2.0    | ✅ 通过迁移兼容 | 自动执行迁移脚本 |

## 🎯 总结

**数据不会丢失的情况：**
- ✅ 正常应用更新（覆盖安装）
- ✅ 导出后导入
- ✅ 自动备份恢复
- ✅ 云同步（Firebase版本）

**需要注意的点：**
1. 保持签名一致性（Android）
2. 不要随意修改包名/Bundle ID
3. 数据模型变更使用默认值
4. 提醒用户定期导出备份
5. 实现自动备份机制

**推荐的更新流程：**
```
1. 用户更新前 → 应用提示"建议先导出备份"
2. 用户更新应用 → 覆盖安装
3. 首次启动 → 自动检测数据迁移
4. 数据迁移完成 → 自动备份
5. 显示更新日志 → 用户继续使用
```

这样可以最大限度保证数据安全！
