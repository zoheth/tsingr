# 应用图标配置指南

## 📁 图标文件放置位置

### 1. 准备图标文件
- **文件名**：`icon.png` 或 `app_icon.png`
- **尺寸**：1024x1024 像素（推荐）
- **格式**：PNG（透明背景或纯色背景）
- **位置**：放到项目根目录的 `assets/` 文件夹

```
tsingr/
├── assets/
│   ├── icon.png          ← 把你的图标放这里
│   ├── questions.csv
│   └── appearances.csv
├── lib/
├── android/
└── ios/
```

## 🚀 自动生成所有平台图标

### 方法1：使用 flutter_launcher_icons（推荐）

#### 步骤1：添加依赖
在 `pubspec.yaml` 的 `dev_dependencies` 部分添加：

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  flutter_launcher_icons: ^0.14.2  # 添加这行
```

#### 步骤2：配置图标
在 `pubspec.yaml` 末尾添加配置：

```yaml
# 应用图标配置
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon.png"

  # Android 自适应图标（可选）
  adaptive_icon_background: "#782F91"  # 清华紫背景
  adaptive_icon_foreground: "assets/icon.png"

  # 其他平台
  windows:
    generate: true
    image_path: "assets/icon.png"
    icon_size: 256

  macos:
    generate: true
    image_path: "assets/icon.png"

  web:
    generate: true
    image_path: "assets/icon.png"
```

#### 步骤3：生成图标
```bash
# 安装依赖
flutter pub get

# 生成图标
flutter pub run flutter_launcher_icons
```

完成！图标会自动配置到所有平台。

---

## 🔧 手动配置（如果自动生成失败）

### Android

#### Android 传统图标
放置位置：
```
android/app/src/main/res/
├── mipmap-hdpi/ic_launcher.png      (72x72)
├── mipmap-mdpi/ic_launcher.png      (48x48)
├── mipmap-xhdpi/ic_launcher.png     (96x96)
├── mipmap-xxhdpi/ic_launcher.png    (144x144)
└── mipmap-xxxhdpi/ic_launcher.png   (192x192)
```

#### Android 自适应图标（Android 8.0+）
```
android/app/src/main/res/
├── mipmap-hdpi/
│   ├── ic_launcher_foreground.png
│   └── ic_launcher_background.png
├── mipmap-mdpi/
│   ├── ic_launcher_foreground.png
│   └── ic_launcher_background.png
└── ...
```

### iOS

放置位置：
```
ios/Runner/Assets.xcassets/AppIcon.appiconset/
```

需要的尺寸：
- Icon-20@2x.png (40x40)
- Icon-20@3x.png (60x60)
- Icon-29@2x.png (58x58)
- Icon-29@3x.png (87x87)
- Icon-40@2x.png (80x80)
- Icon-40@3x.png (120x120)
- Icon-60@2x.png (120x120)
- Icon-60@3x.png (180x180)
- Icon-76.png (76x76)
- Icon-76@2x.png (152x152)
- Icon-83.5@2x.png (167x167)
- Icon-1024.png (1024x1024)

### Windows

放置位置：
```
windows/runner/resources/app_icon.ico
```

### macOS

放置位置：
```
macos/Runner/Assets.xcassets/AppIcon.appiconset/
```

### Web

放置位置：
```
web/
├── favicon.png
└── icons/
    ├── Icon-192.png
    ├── Icon-512.png
    └── Icon-maskable-192.png
```

---

## 🎨 在线工具生成（替代方案）

如果 flutter_launcher_icons 不工作，使用在线工具：

### 1. App Icon Generator
- 网址：https://www.appicon.co/
- 上传 1024x1024 图片
- 下载所有平台图标
- 手动复制到对应目录

### 2. Icon Kitchen (Android)
- 网址：https://icon.kitchen/
- 专门生成 Android 图标
- 支持自适应图标

### 3. makeappicon.com
- 网址：https://makeappicon.com/
- 生成 iOS 和 Android 图标
- 免费使用

---

## ✅ 验证图标配置

### 运行应用查看
```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# Windows
flutter run -d windows
```

### 检查是否显示
- Android：查看应用抽屉
- iOS：查看主屏幕
- Windows：查看任务栏和开始菜单

---

## 🐛 常见问题

### Q: 图标没有更新？
A: 尝试：
```bash
# 清理构建
flutter clean
flutter pub get

# 重新生成图标
flutter pub run flutter_launcher_icons

# 重新构建
flutter build apk  # Android
flutter build ios  # iOS
```

### Q: Android 图标显示白色方块？
A: 确保图标有背景色或使用自适应图标配置

### Q: iOS 图标不显示？
A:
1. 检查 `Info.plist` 中的配置
2. 清理 Xcode 缓存：Product → Clean Build Folder
3. 重新运行

### Q: 图标太小或太大？
A: 确保原始图片：
- 尺寸正确（1024x1024）
- 没有过多留白
- 内容居中

---

## 📝 快速配置步骤

1. **准备图标**
   - 1024x1024 PNG
   - 放到 `assets/icon.png`

2. **编辑 pubspec.yaml**
   ```yaml
   dev_dependencies:
     flutter_launcher_icons: ^0.14.2

   flutter_launcher_icons:
     android: true
     ios: true
     image_path: "assets/icon.png"
   ```

3. **运行命令**
   ```bash
   flutter pub get
   flutter pub run flutter_launcher_icons
   ```

4. **验证**
   ```bash
   flutter run
   ```

完成！🎉
