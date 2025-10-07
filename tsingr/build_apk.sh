#!/bin/bash

echo "================================"
echo "TsingR APK 打包脚本"
echo "================================"
echo ""

echo "[1/4] 清理旧的构建文件..."
flutter clean

echo ""
echo "[2/4] 获取依赖包..."
flutter pub get

echo ""
echo "[3/4] 构建发布版APK..."
flutter build apk --release --split-per-abi

echo ""
echo "[4/4] 构建完成！"
echo ""
echo "APK文件位置："
echo "- ARM 64位 (推荐): build/app/outputs/flutter-apk/app-arm64-v8a-release.apk"
echo "- ARM 32位: build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk"
echo "- x86 64位: build/app/outputs/flutter-apk/app-x86_64-release.apk"
echo ""

# 在文件管理器中打开输出目录
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    open build/app/outputs/flutter-apk
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    xdg-open build/app/outputs/flutter-apk 2>/dev/null || echo "请手动打开目录查看APK文件"
fi
