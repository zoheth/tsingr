@echo off
echo ================================
echo TsingR APK 打包脚本
echo ================================
echo.

echo [1/4] 清理旧的构建文件...
call flutter clean

echo.
echo [2/4] 获取依赖包...
call flutter pub get

echo.
echo [3/4] 构建发布版APK...
call flutter build apk --release --split-per-abi

echo.
echo [4/4] 构建完成！
echo.
echo APK文件位置：
echo - ARM 64位 (推荐): build\app\outputs\flutter-apk\app-arm64-v8a-release.apk
echo - ARM 32位: build\app\outputs\flutter-apk\app-armeabi-v7a-release.apk
echo - x86 64位: build\app\outputs\flutter-apk\app-x86_64-release.apk
echo.

echo 打开输出目录？(y/n)
set /p open="请选择: "
if /i "%open%"=="y" (
    start build\app\outputs\flutter-apk
)

pause
