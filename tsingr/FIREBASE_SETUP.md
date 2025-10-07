# Firebase 自动同步配置指南

本文档指导你如何配置Firebase实现多设备自动同步功能。

## 📋 前置条件

- Google账号
- Flutter开发环境
- Firebase CLI工具

## 🚀 配置步骤

### 第一步：创建Firebase项目

1. 访问 [Firebase Console](https://console.firebase.google.com/)
2. 点击"添加项目"
3. 输入项目名称（如 `tsingr-study`）
4. 选择是否启用Google Analytics（可选）
5. 创建项目

### 第二步：安装Firebase CLI

```bash
# 安装Firebase CLI
npm install -g firebase-tools

# 登录Firebase账号
firebase login

# 安装FlutterFire CLI
dart pub global activate flutterfire_cli
```

### 第三步：在Firebase控制台配置应用

#### 3.1 Android应用
1. 在Firebase控制台点击"Android"图标
2. 输入包名：`com.tsingr.app`（或你的包名）
3. 下载 `google-services.json`
4. 放到 `android/app/` 目录

#### 3.2 iOS应用
1. 在Firebase控制台点击"iOS"图标
2. 输入Bundle ID：`com.tsingr.app`
3. 下载 `GoogleService-Info.plist`
4. 放到 `ios/Runner/` 目录

#### 3.3 Web应用
1. 在Firebase控制台点击"Web"图标
2. 注册应用
3. 复制Firebase配置代码

### 第四步：配置Flutter项目

#### 4.1 添加依赖

编辑 `pubspec.yaml`：

```yaml
dependencies:
  # Firebase Core
  firebase_core: ^3.10.0

  # Firebase Authentication
  firebase_auth: ^5.3.4

  # Cloud Firestore
  cloud_firestore: ^5.5.2

  # Firebase Storage (可选，用于大文件存储)
  firebase_storage: ^12.3.8
```

#### 4.2 运行FlutterFire配置

```bash
# 在项目根目录运行
flutterfire configure
```

这个命令会：
- 自动配置所有平台
- 生成 `firebase_options.dart` 文件
- 配置iOS和Android的Firebase

### 第五步：启用Firestore数据库

1. 在Firebase控制台，进入"Firestore Database"
2. 点击"创建数据库"
3. 选择模式：
   - **测试模式**（开发期间）：允许所有读写
   - **生产模式**（正式上线）：需要配置安全规则

4. 选择数据库位置（选择离用户最近的区域）

### 第六步：配置Firestore安全规则

在Firestore控制台 → 规则，添加以下规则：

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 用户只能访问自己的数据
    match /users/{userId}/study_records/{recordId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // 禁止匿名用户访问
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

### 第七步：启用Firebase Authentication

1. 在Firebase控制台，进入"Authentication"
2. 点击"开始使用"
3. 启用登录方式：
   - **匿名登录**：快速开始，无需注册
   - **电子邮件/密码**：传统登录方式
   - **Google登录**（可选）：第三方登录

## 💻 代码实现

### 1. 初始化Firebase

编辑 `lib/main.dart`：

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}
```

### 2. 创建Firebase同步服务

创建 `lib/services/firebase_sync_service.dart`：

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/study_record.dart';
import 'sync_service_interface.dart';

class FirebaseSyncService implements SyncServiceInterface {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Future<bool> isAuthenticated() async {
    return _auth.currentUser != null;
  }

  @override
  Future<String?> getUserId() async {
    return _auth.currentUser?.uid;
  }

  // 匿名登录
  Future<void> signInAnonymously() async {
    await _auth.signInAnonymously();
  }

  // 邮箱登录
  Future<void> signInWithEmail(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // 注册
  Future<void> signUpWithEmail(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> syncToCloud(Map<int, StudyRecord> records) async {
    final userId = await getUserId();
    if (userId == null) throw Exception('未登录');

    final batch = _firestore.batch();

    for (var entry in records.entries) {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('study_records')
          .doc(entry.key.toString());

      batch.set(docRef, entry.value.toJson());
    }

    await batch.commit();
  }

  @override
  Future<Map<int, StudyRecord>> syncFromCloud() async {
    final userId = await getUserId();
    if (userId == null) throw Exception('未登录');

    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('study_records')
        .get();

    final records = <int, StudyRecord>{};
    for (var doc in snapshot.docs) {
      final record = StudyRecord.fromJson(doc.data());
      records[record.questionId] = record;
    }

    return records;
  }

  @override
  Future<Map<int, StudyRecord>> mergeData(
    Map<int, StudyRecord> localRecords,
    Map<int, StudyRecord> cloudRecords,
  ) async {
    final merged = Map<int, StudyRecord>.from(localRecords);

    for (var entry in cloudRecords.entries) {
      final questionId = entry.key;
      final cloudRecord = entry.value;

      if (!merged.containsKey(questionId)) {
        merged[questionId] = cloudRecord;
      } else {
        merged[questionId] = merged[questionId]!.merge(cloudRecord);
      }
    }

    return merged;
  }

  // 实时监听云端数据变化
  Stream<Map<int, StudyRecord>> watchCloudData() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value({});
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('study_records')
        .snapshots()
        .map((snapshot) {
      final records = <int, StudyRecord>{};
      for (var doc in snapshot.docs) {
        final record = StudyRecord.fromJson(doc.data());
        records[record.questionId] = record;
      }
      return records;
    });
  }

  // 上传单个记录
  Future<void> uploadRecord(StudyRecord record) async {
    final userId = await getUserId();
    if (userId == null) throw Exception('未登录');

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('study_records')
        .doc(record.questionId.toString())
        .set(record.toJson());
  }
}
```

### 3. 集成到StudyProvider

修改 `lib/providers/study_provider.dart`：

```dart
class StudyProvider extends ChangeNotifier {
  // ... 现有代码 ...

  FirebaseSyncService? _firebaseSync;
  bool _isSyncEnabled = false;

  // 启用Firebase同步
  Future<void> enableFirebaseSync() async {
    _firebaseSync = FirebaseSyncService();

    // 匿名登录
    if (!await _firebaseSync!.isAuthenticated()) {
      await _firebaseSync!.signInAnonymously();
    }

    _isSyncEnabled = true;

    // 首次同步
    await syncWithCloud();

    // 监听云端变化
    _firebaseSync!.watchCloudData().listen((cloudRecords) {
      _handleCloudUpdate(cloudRecords);
    });

    notifyListeners();
  }

  // 同步到云端
  Future<void> syncWithCloud() async {
    if (!_isSyncEnabled || _firebaseSync == null) return;

    try {
      // 拉取云端数据
      final cloudRecords = await _firebaseSync!.syncFromCloud();

      // 合并数据
      final mergedRecords = await _firebaseSync!.mergeData(
        _studyRecords,
        cloudRecords,
      );

      // 更新本地
      _studyRecords = mergedRecords;
      await StorageService.saveRecords(_studyRecords);

      // 推送到云端
      await _firebaseSync!.syncToCloud(_studyRecords);

      notifyListeners();
    } catch (e) {
      debugPrint('同步失败: $e');
    }
  }

  // 保存时自动上传
  @override
  Future<void> markAsStudied(int questionId) async {
    await super.markAsStudied(questionId);

    if (_isSyncEnabled && _firebaseSync != null) {
      final record = getRecord(questionId);
      await _firebaseSync!.uploadRecord(record);
    }
  }
}
```

## 🔐 安全最佳实践

1. **使用安全规则**
   - 永远不要使用测试模式的规则在生产环境
   - 确保用户只能访问自己的数据

2. **数据验证**
   - 在Firestore规则中验证数据格式
   - 防止恶意数据注入

3. **速率限制**
   - 使用Firebase App Check防止滥用
   - 设置配额和预算提醒

4. **密钥管理**
   - 不要将Firebase配置提交到公开仓库
   - 使用环境变量管理敏感信息

## 💰 费用估算

### Firebase免费套餐（Spark Plan）

**Firestore：**
- 存储：1GB
- 读取：50,000 次/天
- 写入：20,000 次/天
- 删除：20,000 次/天

**估算：**
- 每个用户约 100 条记录 = 100KB
- 10,000 用户 = 1GB（刚好免费额度）
- 每天同步 5 次 × 100 条 = 500 次读写（远低于限制）

**结论：** 对于中小规模应用，免费套餐完全够用！

### 超出免费套餐

如果用户量很大，可以升级到Blaze计划（按使用付费）：
- 存储：$0.18/GB/月
- 读取：$0.06/10万次
- 写入：$0.18/10万次

## 🧪 测试

### 本地测试
```bash
# 启动Firestore模拟器
firebase emulators:start --only firestore

# 在代码中连接到模拟器
FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
```

### 多设备测试
1. 在设备A登录并添加数据
2. 在设备B登录同一账号
3. 验证数据自动同步
4. 离线修改数据
5. 恢复网络后验证同步

## 🐛 常见问题

### Q: 为什么同步失败？
A: 检查：
- 网络连接
- Firebase配置是否正确
- 是否已登录
- Firestore规则是否允许访问

### Q: 如何处理同步冲突？
A: 使用 `StudyRecord.merge()` 方法：
- 保留学习次数最多的
- 使用最新修改时间的数据

### Q: 同步会消耗多少流量？
A: 每条记录约 200-500 字节
- 100 条记录 ≈ 50KB
- 很少的流量消耗

## 📚 相关资源

- [Firebase文档](https://firebase.google.com/docs)
- [FlutterFire文档](https://firebase.flutter.dev/)
- [Firestore安全规则](https://firebase.google.com/docs/firestore/security/rules-structure)

## ⏭️ 下一步

配置完成后：
1. 测试匿名登录
2. 测试数据同步
3. 在多个设备上验证
4. 添加同步状态UI
5. 实现手动同步按钮
6. 优化同步策略（防抖、批量上传等）
