# TsingR 刷题应用

一个基于 Flutter 的考研题库刷题应用，帮助你高效准备考试。

## 功能特性

### 📚 题库管理
- **热度排序**：自动按题目被考查次数排序，优先显示高频题
- **智能筛选**：
  - 按标签筛选（简答、论述、名解等）
  - 按热度筛选（≥5校、≥10校、≥15校）
  - 关键词搜索
- **分类浏览**：一级/二级标题分类显示

### 📝 刷题功能
- **学习记录**：记录每道题的学习次数和时间
- **重复刷题**：支持同一题目多次学习
- **收藏功能**：收藏重要题目方便复习
- **详细信息**：
  - 题目完整内容
  - 历年考试记录（学校、年份、专业代码）
  - 题目标签和分类
  - 学习统计

### 📊 统计分析
- **学习进度**：整体学习进度可视化
- **统计数据**：
  - 总题数
  - 已学习题数
  - 总刷题次数
  - 收藏数量
- **学习历史**：查看最近学习的题目
- **收藏列表**：快速访问收藏的题目

### 💾 数据持久化
- 使用 SharedPreferences 本地存储学习进度
- 数据自动保存，不会丢失

## 运行应用

1. 确保已安装 Flutter SDK
2. 安装依赖：
   ```bash
   cd tsingr
   flutter pub get
   ```
3. 运行应用：
   ```bash
   flutter run
   ```

## 使用指南

### 首页（题库）
1. 浏览题目列表，按热度自动排序
2. 使用顶部搜索框搜索题目
3. 点击右上角筛选按钮进行筛选
4. 点击题目卡片查看详情
5. 点击星标收藏/取消收藏

### 题目详情页
1. 查看题目完整内容和分类
2. 查看所有考试记录（学校、年份、标签）
3. 查看学习统计
4. 点击底部"标记为已学习"按钮记录学习

### 统计页
1. 查看整体学习进度和统计数据
2. 查看收藏的题目
3. 查看最近学习的题目
4. 点击任意题目卡片跳转到详情页

## 项目结构

```
lib/
├── models/              # 数据模型
│   ├── question.dart    # 题目和考试记录模型
│   └── study_record.dart # 学习记录模型
├── services/            # 服务层
│   ├── data_service.dart    # CSV数据加载
│   └── storage_service.dart # 本地存储
├── providers/           # 状态管理
│   └── study_provider.dart  # 全局状态管理
├── pages/               # 页面
│   ├── home_page.dart           # 主页（题目列表）
│   ├── question_detail_page.dart # 题目详情
│   └── statistics_page.dart     # 统计页面
└── main.dart            # 应用入口
```

## 数据说明

应用使用两个 CSV 文件（位于 `assets/` 目录）：

1. **questions.csv**：题目主表，包含6637道题目
2. **appearances.csv**：考试记录表，包含10788条记录

数据由 Python 脚本处理生成。更新数据：
```bash
python scripts/process_text.py
cp data/questions.csv data/appearances.csv tsingr/assets/
```

## 技术栈

- **Flutter**：跨平台 UI 框架
- **Provider**：状态管理
- **CSV**：CSV 文件解析
- **SharedPreferences**：本地数据持久化

## 打包安卓APK

### 方法一：快速打包（测试用）

直接构建调试版本APK：

```bash
cd tsingr
flutter build apk
```

APK 文件位置：`build/app/outputs/flutter-apk/app-release.apk`

### 方法二：打包发布版本（推荐）

#### 1. 修改应用信息

编辑 `android/app/build.gradle.kts`，修改以下内容：

```kotlin
defaultConfig {
    applicationId = "com.tsingr.study"  // 修改为你的应用ID
    minSdk = 21  // 最低支持 Android 5.0
    targetSdk = 34
    versionCode = 1  // 版本号，每次发布递增
    versionName = "1.0.0"  // 版本名称
}
```

#### 2. 修改应用名称和图标

**修改应用名称：**

编辑 `android/app/src/main/AndroidManifest.xml`：
```xml
<application
    android:label="TsingR刷题"  <!-- 修改这里 -->
    ...>
```

**修改应用图标：**

将图标文件放到以下目录（替换默认图标）：
- `android/app/src/main/res/mipmap-hdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-mdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`

或使用工具生成：[https://icon.kitchen/](https://icon.kitchen/)

#### 3. 生成签名密钥（可选，用于正式发布）

```bash
# 生成密钥库
keytool -genkey -v -keystore ~/tsingr-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias tsingr

# 按提示输入密码和信息
```

创建 `android/key.properties` 文件：
```properties
storePassword=你的密钥库密码
keyPassword=你的密钥密码
keyAlias=tsingr
storeFile=你的密钥库路径（如：C:/Users/YourName/tsingr-key.jks）
```

修改 `android/app/build.gradle.kts`：

```kotlin
// 在 android 块之前添加
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    // ... 其他配置

    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release  // 使用发布签名
            minifyEnabled true  // 启用代码混淆
            shrinkResources true  // 启用资源压缩
        }
    }
}
```

#### 4. 构建发布版APK

```bash
cd tsingr

# 构建发布版 APK
flutter build apk --release

# 或构建分架构APK（文件更小）
flutter build apk --split-per-abi
```

输出文件位置：
- 通用版：`build/app/outputs/flutter-apk/app-release.apk`
- 分架构版：
  - `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk` (32位ARM)
  - `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` (64位ARM，推荐)
  - `build/app/outputs/flutter-apk/app-x86_64-release.apk` (x86模拟器)

#### 5. 构建 App Bundle（Google Play 推荐）

```bash
flutter build appbundle --release
```

输出：`build/app/outputs/bundle/release/app-release.aab`

### 常见问题

**1. 构建失败？**
```bash
# 清理构建缓存
flutter clean
flutter pub get
flutter build apk
```

**2. APK 过大？**
- 使用 `--split-per-abi` 分架构构建
- 启用代码混淆和资源压缩（见上文）

**3. 安装时提示"未知来源"？**
- 在手机设置中允许安装未知来源应用

**4. CSV 数据加载失败？**
- 确保 `assets/` 目录下有 `questions.csv` 和 `appearances.csv`
- 检查 `pubspec.yaml` 中的 assets 配置

### 快速命令

```bash
# 开发测试
flutter run

# 打包调试版
flutter build apk --debug

# 打包发布版（推荐）
flutter build apk --release --split-per-abi

# 查看APK大小分析
flutter build apk --analyze-size
```
