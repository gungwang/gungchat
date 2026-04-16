# GungChat 第 1 次开发交接

日期：2026-04-16

## 已完成范围

本次会话完成了 GungChat 的初始 Flutter 项目框架（位于 `gungchat/` 目录），并让本地 Linux 机器具备可构建 Android 的 Flutter 环境。

## 项目状态

项目根目录已创建：

- `gungchat/`

已加入的初始功能模块：

- App 外壳与 Riverpod 架构
- 核心加密服务与密钥管理器
- WebRTC 管理器、信令封装、ICE 管理器、网络监控
- 本地 SQLite 消息数据库
- 基础聊天、联系人、设置界面
- 初步的组件与加密测试

`gungchat/pubspec.yaml` 中的重要依赖更新：

- `flutter_webrtc` 升级到 `^1.4.1`

本地新增的 Android 发布签名文件：

- `gungchat/android/key.properties`
- `gungchat/android/upload-keystore.jks`

会话结束时的仓库状态：

- `gungchat/` 目录仍未加入父级仓库的版本控制

## 本地机器已完成的环境配置

### Flutter SDK

本地安装位置：

- `/home/wang/.local/flutter`

### JDK 17

本地安装位置：

- `/home/wang/.local/jdks/temurin-17`

配置 Flutter 使用该 JDK：

- `flutter config --jdk-dir=/home/wang/.local/jdks/temurin-17`

### Android SDK

本地安装位置：

- `/home/wang/.local/android-sdk`

配置 Flutter 使用该 SDK：

- `flutter config --android-sdk=/home/wang/.local/android-sdk`

已安装的 Android SDK 组件：

- platform-tools
- platforms;android-36
- build-tools;36.0.0
- cmake;3.22.1
- 构建过程中自动安装了 NDK side-by-side 28.2.13676358

### Shell 配置

更新了 `/home/wang/.zshrc`，加入：

- Flutter 与 Android 工具的 PATH
- `JAVA_HOME=/home/wang/.local/jdks/temurin-17`
- `ANDROID_HOME=/home/wang/.local/android-sdk`
- `ANDROID_SDK_ROOT=/home/wang/.local/android-sdk`

## 已完成验证

以下命令均成功执行：

- `flutter analyze`
- `flutter test`
- `flutter doctor -v`（在 Android 环境变量正确时显示正常）
- `flutter build apk --debug --target-platform android-arm64`
- `flutter build apk --debug`
- `flutter build apk --release`
- `flutter build appbundle --release`

生成的 APK：

- `gungchat/build/app/outputs/flutter-apk/app-debug.apk`
- `gungchat/build/app/outputs/flutter-apk/app-release.apk`

生成的 Android App Bundle：

- `gungchat/build/app/outputs/bundle/release/app-release.aab`

发布签名验证：

- `android/upload-keystore.jks` 的 SHA-256 指纹与 `app-release.apk` 的签名指纹一致

## 已发现并修复的问题

### 1. 缺少 Flutter 命令

通过本地安装 Flutter 并加入 PATH 解决。

### 2. Android Gradle 插件需要的 Java 版本不匹配

通过安装本地 Temurin JDK 17 并配置 Flutter 使用它解决。

### 3. 缺少 Android SDK

通过安装本地 Android 命令行工具与所需 SDK 包解决。

### 4. 旧版 `flutter_webrtc` 在 Android 上构建失败

原版本：

- `0.11.7`

问题：

- 使用了已删除的 Flutter Android v1 API（`PluginRegistry.Registrar`）

解决：

- 升级到 `flutter_webrtc ^1.4.1`

### 5. Android 原生构建缺少 Ninja

通过安装 Android SDK 的 CMake `3.22.1` 解决。

### 6. 磁盘空间不足

Linux 文件系统在打包 Android 时几乎满了。

表现：

- 通用 debug APK 打包失败，提示磁盘空间不足。

临时解决：

- 清理 Flutter 构建输出
- 删除下载的安装包
- 使用 `--target-platform android-arm64` 构建更小的单 ABI APK

### 7. Android 发布签名配置

通过以下方式解决：

- 更新 `gungchat/android/app/build.gradle.kts` 使用 `android/key.properties` 中的真实签名配置
- 生成本地 `android/upload-keystore.jks`
- 生成本地（忽略提交）`android/key.properties`
- 验证 `app-release.apk` 已使用该 keystore 签名

新增文档：

- `gungchat/android/RELEASE_SIGNING.md`

## 当前已知限制

- Linux 机器无法构建 iOS
- 父级仓库尚未提交 `gungchat/` 目录

## 现在必须备份的文件

在重装、清理或更换密钥前，请务必将以下文件备份到机器外部：

- `gungchat/android/key.properties`
- `gungchat/android/upload-keystore.jks`

丢失任意一个文件，都可能导致未来无法继续发布同一签名身份的 Android 更新。

## 重启与扩容后建议执行的步骤

机器重启后运行：

1. `source ~/.zshrc`
2. `cd /home/wang/projects/gungchat/gungchat`
3. `flutter doctor -v`
4. `flutter analyze`
5. `flutter test`

如需重新验证 Android 打包：

6. `flutter build apk --debug`

如需发布版：

7. `flutter build apk --release`

如需 Google Play 格式：

8. `flutter build appbundle --release`

## 下一步工程建议

继续 Phase 1 与 Phase 2 的早期实现，顺序如下：

1. 手动实现 offer、answer、ICE 的点对点信令流程
2. 在 data channel 上实现真正的加密消息传输
3. 加入局域网发现功能
4. 加入平台级截图与录屏防护

## 最需要重新打开的文件

- `gungchat/pubspec.yaml`
- `gungchat/android/app/build.gradle.kts`
- `gungchat/android/RELEASE_SIGNING.md`
- `gungchat/lib/app/providers.dart`
- `gungchat/lib/core/networking/webrtc_manager.dart`
- `gungchat/lib/core/networking/signaling_service.dart`
- `gungchat/lib/core/encryption/crypto_service.dart`
- `gungchat/lib/features/chat/chat_screen.dart`
- `/home/wang/.zshrc`

`app-release.apk` 是 Android 安装包，用户可直接在 Android 上手动安装，用于测试或私下分发。

`app-release.aab` 是 Google Play 用的 App Bundle，通常上传到 Google Play，由 Google Play 自动生成适配设备的 APK，用户不会直接安装 `.aab`。

---
