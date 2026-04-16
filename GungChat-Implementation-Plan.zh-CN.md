# GungChat (敢说) - 实施计划

**项目**：点对点加密消息应用
**目标平台**：Android 与 iOS（移动优先）
**技术栈**：Flutter（Dart）
**时间线**：灵活（MVP 约 33 周）
**最后更新**：2026 年 4 月 13 日

> **阅读提示**
> - P2P 指设备之间直接通信，消息不先经过中心服务器。
> - WebRTC 是用于建立点对点数据通道和音视频连接的标准技术。
> - STUN/TURN 用于 NAT 穿透；STUN 帮助直连，TURN 在直连失败时中继流量。
> - Double Ratchet 是持续轮换消息密钥的机制，可提供前向保密。

---

## 目录

1. [项目概览](#项目概览)
2. [架构概览](#架构概览)
3. [技术栈](#技术栈)
4. [实施阶段](#实施阶段)
5. [关键架构决策](#关键架构决策)
6. [风险与缓解措施](#风险与缓解措施)
7. [成功指标](#成功指标)
8. [后续步骤](#后续步骤)

---

## 项目概览

**GungChat（敢说）** 是一款开源的点对点（P2P）加密消息应用，以 **完全隐私** 和 **零服务器基础设施** 为核心原则构建。

### 核心功能

- ✅ **无需注册** - 无需账号即可直接建立 P2P 连接
- ✅ **端到端加密** - 所有通信均使用 libsodium 加密
- ✅ **阅后即焚消息** - 默认启用“阅后即焚”
- ✅ **多模态通信** - 支持文本、图片、语音通话和视频通话
- ✅ **无服务器架构** - 通过 IP 地址或本地网络发现建立连接
- ✅ **隐私优先** - 防截屏，不保留消息历史（可选本地加密缓存）
- ✅ **反监控防护** - 检测尝试监视 GungChat 的应用/进程；提醒用户并强制停用违规应用
- ✅ **局域网优化** - 优先使用本地网络而不是互联网路由
- ✅ **输入状态提示** - 通过加密数据通道实时显示“对方正在输入...”
- ✅ **消息格式化** - URL 自动转链接、内联图片预览、代码块渲染、Emoji/表情支持
- ✅ **已读回执** - 加密的送达/已读确认（尊重隐私，需用户主动开启）
- ✅ **在线状态** - 在线/离线/离开状态指示，并提供隐私控制（可隐藏）
- ✅ **未读与提及角标** - 通知计数器与系统级推送提醒
- ✅ **带校验的文件传输** - MIME 类型白名单、大小限制、发送前预览
- ✅ **本地加密搜索** - 对本地缓存的消息历史执行全文检索
- ✅ **连接韧性** - 网络中断后自动重连并恢复会话状态
- ✅ **扩展国际化（i18n，多语言）** - 除 EN/ZH 外，还支持日语、韩语、俄语、西班牙语、法语、德语等
- ✅ **消息回应** - 可对单条消息添加 Emoji 反应（通过加密通道发送）
- ✅ **消息星标** - 为重要消息添加个人书签（仅本地保存，绝不共享）
- ✅ **消息编辑与删除** - 支持编辑已发送消息或删除消息，并采用兼顾隐私的墓碑语义（tombstone semantics）
- ✅ **语音消息** - 录制并发送加密音频消息，可在聊天中直接播放
- ✅ **回复/引用消息** - 回复某条指定消息并附带引用上下文
- ✅ **URL 链接预览** - 客户端提取元数据，并提供隐私控制（需用户主动开启抓取）
- ✅ **剧透消息** - 隐藏内容，点击后显示（`||spoiler||` 语法）
- ✅ **自定义状态文本** - 在在线/离线/离开之外设置个人状态消息
- ✅ **斜杠命令** - 本地命令（`/clear`、`/export`、`/status`、`/destroy`）
- ✅ **聊天数据导出** - 本地加密导出会话历史（类似 GDPR 的数据导出）
- ✅ **联系人屏蔽** - 阻止某个对端主动发起连接
- ✅ **应用锁** - 使用生物识别（指纹/人脸）或 PIN 码保护应用访问
- ✅ **快捷回复模板** - 保存可复用的消息片段，并支持短代码搜索
- ✅ **会话标签** - 使用颜色标签组织不同对端会话
- ✅ **联系人备注** - 为联系人添加私密备注（仅本地保存，绝不共享）
- ✅ **多附件消息** - 单条消息支持多个文件 + 位置共享 + 联系人名片
- ✅ **共享媒体图库** - 浏览某个会话中的全部共享媒体
- ✅ **主题系统** - 亮色/暗色/跟随系统三种外观模式
- ✅ **键盘快捷键** - 面向高级用户的导航与快速操作
- ✅ **会话静音与稍后提醒** - 可按会话临时关闭通知
- ✅ **细粒度通知偏好** - 按事件类型单独控制通知
- ✅ **无障碍支持（A11y）** - ARIA 语义、键盘导航、屏幕阅读器支持
- ❌ **不支持群聊** - 严格限定为点对点通信

### 连接方式

1. **手动输入 IP 地址** - 通过 IPv4/IPv6 直接连接
2. **局域网发现** - 通过 mDNS 自动发现本地网络中的设备
3. **二维码交换** - 安全共享联系信息（无服务器）
4. **手机号/通讯录** - 未来：基于 DHT（分布式哈希表）的发现方式（第 2 阶段之后）

---

## 架构概览

### 高层架构

```text
┌─────────────────────────────────────────────────────────────┐
│                     GungChat Mobile App                      │
│                        (Flutter)                             │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Chat UI    │  │  Call UI     │  │ Contacts UI  │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
│         │                  │                  │              │
│  ┌──────▼──────────────────▼──────────────────▼───────┐    │
│  │          State Management (Riverpod/Bloc)          │    │
│  └──────┬──────────────────┬──────────────────┬───────┘    │
│         │                  │                  │              │
│  ┌──────▼───────┐  ┌──────▼───────┐  ┌──────▼───────┐    │
│  │   Message    │  │ Call Manager │  │  Discovery   │    │
│  │   Service    │  │   (WebRTC)   │  │   Service    │    │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘    │
│         │                  │                  │              │
│  ┌──────▼──────────────────▼──────────────────▼───────┐    │
│  │         WebRTC Manager (P2P Connections)           │    │
│  └──────┬─────────────────────────────────────────────┘    │
│         │                                                    │
│  ┌──────▼──────────────────────────────────────┐          │
│  │  Encryption Layer (libsodium/ChaCha20)      │          │
│  └──────┬──────────────────────────────────────┘          │
│         │                                                    │
│  ┌──────▼──────────────────────────────────────┐          │
│  │  Secure Storage (Encrypted SQLite)          │          │
│  └─────────────────────────────────────────────┘          │
│                                                               │
└─────────────────────────────────────────────────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
   ┌─────────┐           ┌─────────┐           ┌─────────┐
   │  STUN   │           │  Peer   │           │  mDNS   │
   │ Server  │           │ Device  │           │  (LAN)  │
   └─────────┘           └─────────┘           └─────────┘
```

### 核心原则

1. **零服务器基础设施** - 所有通信都是点对点的（NAT 穿透场景可选使用 STUN/TURN）
2. **端到端加密** - 消息在离开发送端设备之前就完成加密
3. **默认阅后即焚** - 消息在查看后或达到时限后自毁
4. **优先局域网** - 本地连接优先于互联网路由
5. **全面开源** - 所有依赖必须是开源的

---

## 技术栈

### 框架与语言

- **Flutter 3.x** - 跨平台移动框架（Android + iOS）
- **Dart** - 主要编程语言
- **状态管理**：Riverpod 或 Bloc 模式

### 网络与通信

- **WebRTC**（`flutter_webrtc` 插件）
  - 用于文本/图片的 P2P 数据通道
  - 用于通话的音频/视频流
  - 内置 NAT 穿透（ICE）
- **STUN 服务器** - 用于建立连接的公共服务器（Google、Cloudflare）
- **TURN 服务器**（可选） - 为对称 NAT 场景提供自托管中继
- **mDNS/Bonjour**（`multicast_dns` package） - 局域网设备发现

### 加密与安全

- **libsodium** - 加密库
  - **密钥交换**：X25519（椭圆曲线 Diffie-Hellman）
  - **加密**：ChaCha20-Poly1305（认证加密）
  - **哈希**：SHA-256，用于联系人匹配
- **Double Ratchet**（第 8 阶段） - 完美前向保密（Signal 协议）
- **Flutter Secure Storage** - 安全持久化密钥存储

### 数据存储

- **SQLite**（`sqflite` package） - 本地数据库
- **SQLCipher** - 加密数据库（可选实现）
- **Shared Preferences** - 应用设置

### 媒体编解码

- **音频**：Opus 编解码器（16-48 kbps，WebRTC 内置）
- **视频**：VP8/VP9 编解码器（100-500 kbps，限制为 320p）
- **图片压缩**：Flutter 的 `image` 包

### 权限与平台 API

- **摄像头**（`camera` package）
- **麦克风** - WebRTC 音频采集
- **联系人**（`contacts_service` package）
- **网络状态**（`connectivity_plus` package）
- **通知**（`flutter_local_notifications`）

### 开发工具

- **版本控制**：Git + GitHub/GitLab
- **CI/CD**：GitHub Actions（可选）
- **测试**：Flutter 测试框架（单元测试、Widget 测试、集成测试）
- **代码混淆**：Flutter 内置的发布版混淆能力

---

## 实施阶段

### 第 1 阶段：项目基础与核心基础设施（第 1-3 周）

**目标**：搭建项目结构、加密层和基础 WebRTC P2P 连接。

#### 第 1 步：初始化 Flutter 项目
```bash
flutter create gungchat
cd gungchat
```

**任务**：
- 为 Flutter 项目配置 `.gitignore`
- 设置代码仓库（GitHub/GitLab）
- 添加开源许可证（GPLv3 / MIT / Apache 2.0）
- 创建包含项目说明的 `README.md`

#### 第 2 步：项目结构

创建如下目录结构：

```text
lib/
├── core/
│   ├── encryption/
│   │   ├── crypto_service.dart         # 加密封装层
│   │   └── key_manager.dart            # 密钥生成与存储
│   ├── networking/
│   │   ├── webrtc_manager.dart         # WebRTC 连接
│   │   ├── signaling_service.dart      # 对端发现与信令
│   │   ├── ice_manager.dart            # STUN/TURN 配置
│   │   └── network_monitor.dart        # 网络状态检测
│   ├── storage/
│   │   ├── secure_storage.dart         # 加密本地存储
│   │   └── message_db.dart             # SQLite 数据库封装
│   ├── guard/
│   │   ├── surveillance_detector.dart   # 检测间谍/监控应用与进程
│   │   └── app_shield.dart             # 强制停用或阻止违规应用
│   └── error/
│       └── error_handler.dart          # 集中式错误处理
├── features/
│   ├── chat/
│   │   ├── chat_screen.dart            # 主聊天 UI
│   │   ├── message_service.dart        # 发送/接收消息
│   │   ├── ephemeral_manager.dart      # 自毁逻辑
│   │   └── widgets/
│   │       ├── message_bubble.dart     # 文本消息组件
│   │       └── image_message_bubble.dart
│   ├── calling/
│   │   ├── call_manager.dart           # 语音/视频通话逻辑
│   │   ├── voice_call_screen.dart      # 语音通话 UI
│   │   ├── video_call_screen.dart      # 视频通话 UI
│   │   └── services/
│   │       ├── call_signaling_service.dart
│   │       └── video_service.dart
│   ├── contacts/
│   │   ├── contacts_screen.dart        # 联系人列表 UI
│   │   ├── discovery_service.dart      # mDNS 与联系人查找
│   │   └── qr_code_screen.dart         # 二维码生成/扫描
│   ├── notifications/
│   │   └── notification_service.dart   # 推送通知与角标计数
│   └── settings/
│       └── settings_screen.dart        # 应用设置 UI
├── formatters/
│   ├── message_formatter.dart          # URL 转链接、图片嵌入、代码块
│   ├── emoji_manager.dart              # Emoji/表情渲染与映射
│   ├── link_preview_service.dart       # 客户端 URL 元数据提取
│   └── spoiler_renderer.dart           # 剧透文本解析与显示组件
├── commands/
│   └── slash_command_registry.dart     # 本地斜杠命令框架
├── security/
│   ├── app_lock_service.dart           # 生物识别/PIN 应用锁
│   └── contact_block_service.dart      # 对端屏蔽逻辑
├── templates/
│   └── quick_reply_service.dart        # 预设回复 / 快捷回复模板
├── organization/
│   ├── label_service.dart              # 会话标签/标签管理
│   ├── contact_notes_service.dart      # 私密联系人备注
│   └── conversation_mute_service.dart  # 按会话静音/稍后提醒
├── media/
│   └── media_gallery_service.dart      # 共享媒体图库浏览
├── preferences/
│   ├── theme_service.dart              # 亮色/暗色/自动外观
│   ├── notification_prefs_service.dart # 细粒度通知控制
│   └── keyboard_shortcut_service.dart  # 键盘快捷键注册表
├── models/
│   ├── message.dart                    # 消息数据模型
│   ├── contact.dart                    # 联系人模型
│   └── call.dart                       # 通话状态模型
├── ui/
│   ├── screens/                        # 共用页面
│   └── widgets/                        # 可复用组件
├── l10n/                               # 本地化文件
│   ├── app_en.arb                      # 英文文案
│   ├── app_zh.arb                      # 简体中文文案
│   ├── app_zh_TW.arb                   # 繁体中文文案
│   ├── app_ja.arb                      # 日文文案
│   ├── app_ko.arb                      # 韩文文案
│   ├── app_ru.arb                      # 俄文文案
│   ├── app_es.arb                      # 西班牙文文案
│   ├── app_fr.arb                      # 法文文案
│   ├── app_de.arb                      # 德文文案
│   └── app_pt.arb                      # 葡萄牙文文案
└── main.dart                           # 应用入口
```

#### 第 3 步：添加依赖

**`pubspec.yaml`**：
```yaml
dependencies:
  flutter:
    sdk: flutter

  # 用于 P2P 通信的 WebRTC
  flutter_webrtc: ^0.9.0

  # 加密
  flutter_sodium: ^0.2.0  # libsodium 绑定

  # 存储
  sqflite: ^2.3.0
  flutter_secure_storage: ^9.0.0
  shared_preferences: ^2.2.0

  # 状态管理
  flutter_riverpod: ^2.4.0  # 或 bloc: ^8.1.0

  # 网络与发现
  multicast_dns: ^0.3.2
  connectivity_plus: ^5.0.0

  # 权限
  permission_handler: ^11.0.0

  # 媒体
  camera: ^0.10.0
  image_picker: ^1.0.0
  image: ^4.1.0  # 图片压缩

  # UI
  qr_flutter: ^4.1.0  # 二维码生成
  mobile_scanner: ^3.5.0  # 二维码扫描

  # 工具
  path_provider: ^2.1.0
  uuid: ^4.0.0
  linkify: ^5.0.0             # URL 检测与链接化
  flutter_linkify: ^6.0.0     # 链接化文本组件
  emoji_picker_flutter: ^1.6.0 # Emoji 键盘与选择器
  flutter_highlight: ^0.7.0   # 代码语法高亮
  flutter_local_notifications: ^16.0.0  # 系统推送通知
  flutter_app_badger: ^1.5.0  # 应用图标角标计数
  record: ^4.5.0              # 语音消息音频录制
  audioplayers: ^5.2.0        # 语音消息音频播放
  local_auth: ^2.1.0          # 生物识别认证（指纹/人脸）
  html: ^0.15.0               # 用于链接预览的 HTML 元数据解析
  share_plus: ^7.2.0          # 共享/导出聊天数据
  archive: ^3.4.0             # 数据导出的 ZIP 压缩
  geolocator: ^10.1.0         # 消息中的位置共享
  flutter_contacts: ^1.1.7    # 联系人名片共享
  photo_view: ^0.14.0         # 媒体图库的全屏图片查看器
  flutter_keyboard_visibility: ^5.4.0  # 键盘状态检测

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  integration_test:
    sdk: flutter
```

运行：
```bash
flutter pub get
```

#### 第 4 步：实现加密层

**`lib/core/encryption/crypto_service.dart`**：

```dart
import 'package:flutter_sodium/flutter_sodium.dart';

class CryptoService {
  // 为当前设备生成 X25519 密钥对
  static Future<KeyPair> generateKeyPair() async {
    await Sodium.init();
    return CryptoKx.keyPair();
  }

  // 执行密钥交换以派生共享会话密钥
  static Uint8List deriveSharedKey(
    Uint8List mySecretKey,
    Uint8List theirPublicKey,
  ) {
    // X25519 密钥协商
    return CryptoBox.beforeNm(theirPublicKey, mySecretKey);
  }

  // 使用 ChaCha20-Poly1305 加密消息
  static Uint8List encrypt(Uint8List plaintext, Uint8List sharedKey) {
    final nonce = RandomBytes.buffer(CryptoBox.nonceBytes);
    final ciphertext = CryptoBox.easyAfterNm(plaintext, nonce, sharedKey);

    // 在密文前附加 nonce
    return Uint8List.fromList([...nonce, ...ciphertext]);
  }

  // 解密消息
  static Uint8List? decrypt(Uint8List encryptedData, Uint8List sharedKey) {
    final nonce = encryptedData.sublist(0, CryptoBox.nonceBytes);
    final ciphertext = encryptedData.sublist(CryptoBox.nonceBytes);

    try {
      return CryptoBox.openEasyAfterNm(ciphertext, nonce, sharedKey);
    } catch (e) {
      return null; // 解密失败
    }
  }
}
```

#### 第 5 步：搭建基础 WebRTC 连接

**`lib/core/networking/webrtc_manager.dart`**：

```dart
import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCManager {
  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;

  // STUN 服务器配置
  final Map<String, dynamic> _configuration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ],
  };

  // 初始化 P2P 连接
  Future<void> createConnection({
    required Function(RTCDataChannelMessage) onMessage,
    required Function(RTCIceCandidate) onIceCandidate,
  }) async {
    _peerConnection = await createPeerConnection(_configuration);

    // 为消息创建数据通道
    _dataChannel = await _peerConnection!.createDataChannel(
      'messages',
      RTCDataChannelInit()..ordered = true,
    );

    _dataChannel!.onMessage = (message) {
      onMessage(message);
    };

    // ICE candidate 回调
    _peerConnection!.onIceCandidate = (candidate) {
      if (candidate != null) {
        onIceCandidate(candidate);
      }
    };
  }

  // 通过数据通道发送消息
  void sendMessage(String message) {
    if (_dataChannel != null && _dataChannel!.state == RTCDataChannelState.RTCDataChannelOpen) {
      _dataChannel!.send(RTCDataChannelMessage(message));
    }
  }

  // 创建 offer（发起方）
  Future<RTCSessionDescription> createOffer() async {
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    return offer;
  }

  // 处理 answer（发起方接收）
  Future<void> setRemoteDescription(RTCSessionDescription description) async {
    await _peerConnection!.setRemoteDescription(description);
  }

  // 处理 offer 并创建 answer（接收方）
  Future<RTCSessionDescription> createAnswer(RTCSessionDescription offer) async {
    await _peerConnection!.setRemoteDescription(offer);
    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);
    return answer;
  }

  // 添加来自对端的 ICE candidate
  Future<void> addIceCandidate(RTCIceCandidate candidate) async {
    await _peerConnection!.addCandidate(candidate);
  }

  // 关闭连接
  void close() {
    _dataChannel?.close();
    _peerConnection?.close();
  }
}
```

#### 验证（第 1 阶段）

- [ ] Flutter 应用可在 Android/iOS 模拟器上构建并运行
- [ ] 加密层可正确加密/解密测试消息
- [ ] 两台测试设备成功建立 WebRTC 数据通道
- [ ] 基础 UI 可显示连接状态

---

### 第 2 阶段：文本消息与阅后即焚消息（第 4-6 周）

**目标**：实现带自毁能力的加密文本消息。

#### 第 6 步：消息数据模型

**`lib/models/message.dart`**：

```dart
import 'package:uuid/uuid.dart';

enum MessageType { text, image, audio, video, system }
enum MessageStatus { sending, sent, delivered, read, failed }

class Message {
  final String id;
  final String senderId;
  final String recipientId;
  final MessageType type;
  final String content; // 加密负载
  final DateTime timestamp;
  final MessageStatus status;
  final int? expirySeconds; // null = 不过期，否则为自毁时间
  final DateTime? viewedAt;

  Message({
    String? id,
    required this.senderId,
    required this.recipientId,
    required this.type,
    required this.content,
    DateTime? timestamp,
    this.status = MessageStatus.sending,
    this.expirySeconds,
    this.viewedAt,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  // 检查消息是否应被删除
  bool get isExpired {
    if (expirySeconds == null || viewedAt == null) return false;
    return DateTime.now().difference(viewedAt!).inSeconds >= expirySeconds!;
  }

  Message copyWith({
    MessageStatus? status,
    DateTime? viewedAt,
  }) {
    return Message(
      id: id,
      senderId: senderId,
      recipientId: recipientId,
      type: type,
      content: content,
      timestamp: timestamp,
      status: status ?? this.status,
      expirySeconds: expirySeconds,
      viewedAt: viewedAt ?? this.viewedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderId': senderId,
        'recipientId': recipientId,
        'type': type.index,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'status': status.index,
        'expirySeconds': expirySeconds,
        'viewedAt': viewedAt?.toIso8601String(),
      };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id'],
        senderId: json['senderId'],
        recipientId: json['recipientId'],
        type: MessageType.values[json['type']],
        content: json['content'],
        timestamp: DateTime.parse(json['timestamp']),
        status: MessageStatus.values[json['status']],
        expirySeconds: json['expirySeconds'],
        viewedAt: json['viewedAt'] != null ? DateTime.parse(json['viewedAt']) : null,
      );
}
```

#### 第 7 步：聊天 UI

**`lib/features/chat/chat_screen.dart`**：

```dart
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  final String contactName;
  final String contactId;

  const ChatScreen({
    Key? key,
    required this.contactName,
    required this.contactId,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Message> _messages = [];

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final message = Message(
      senderId: 'me', // 替换为真实设备 ID
      recipientId: widget.contactId,
      type: MessageType.text,
      content: _messageController.text,
      expirySeconds: 30, // 30 秒后自毁
    );

    setState(() {
      _messages.add(message);
    });

    // TODO: 通过 WebRTC 数据通道发送
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.contactName),
      ),
      body: Column(
        children: [
          // 消息列表
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[_messages.length - 1 - index];
                return MessageBubble(message: message);
              },
            ),
          ),
          // 输入框
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: '输入消息...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

#### 第 8 步：阅后即焚消息管理器

**`lib/features/chat/ephemeral_manager.dart`**：

```dart
import 'dart:async';
import 'package:flutter/material.dart';

class EphemeralManager {
  final Map<String, Timer> _timers = {};

  // 启动消息自毁倒计时
  void startTimer(String messageId, int seconds, VoidCallback onExpire) {
    _timers[messageId]?.cancel();
    _timers[messageId] = Timer(Duration(seconds: seconds), () {
      onExpire();
      _timers.remove(messageId);
    });
  }

  // 标记消息已查看并启动过期计时器
  void markViewed(Message message, VoidCallback onExpire) {
    if (message.expirySeconds != null) {
      startTimer(message.id, message.expirySeconds!, onExpire);
    }
  }

  // 取消所有计时器
  void dispose() {
    for (var timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }
}
```

#### 第 9 步：加密本地存储（可选）

**`lib/core/storage/message_db.dart`**：

```dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class MessageDatabase {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'messages.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE messages(id TEXT PRIMARY KEY, senderId TEXT, recipientId TEXT, type INTEGER, content TEXT, timestamp TEXT, status INTEGER, expirySeconds INTEGER, viewedAt TEXT)',
        );
      },
    );
  }

  Future<void> insertMessage(Message message) async {
    final db = await database;
    await db.insert('messages', message.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Message>> getMessages(String contactId) async {
    final db = await database;
    final maps = await db.query(
      'messages',
      where: 'recipientId = ? OR senderId = ?',
      whereArgs: [contactId, contactId],
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => Message.fromJson(maps[i]));
  }

  Future<void> deleteMessage(String messageId) async {
    final db = await database;
    await db.delete('messages', where: 'id = ?', whereArgs: [messageId]);
  }

  Future<void> deleteAllMessages() async {
    final db = await database;
    await db.delete('messages');
  }
}
```

#### 验证（第 2 阶段）

- [ ] 在两台设备之间发送/接收文本消息
- [ ] 消息在聊天 UI 中正确显示时间戳
- [ ] 阅后即焚消息会在配置时间后自毁
- [ ] 截屏防护已启用（Android：`FLAG_SECURE`）

---

### 第 3 阶段：图片分享（第 7-8 周）

**目标**：支持加密图片拍摄、传输和阅后查看。

#### 第 10 步：图片拍摄与选择

**集成示例**：
```dart
import 'package:image_picker/image_picker.dart';

Future<File?> pickImage(ImageSource source) async {
  final picker = ImagePicker();
  final image = await picker.pickImage(source: source);
  return image != null ? File(image.path) : null;
}
```

#### 第 11 步：图片加密与分块传输

**`lib/core/networking/file_transfer_manager.dart`**：

```dart
class FileTransferManager {
  static const int chunkSize = 16 * 1024; // 16 KB 分块

  // 分块加密并发送图片
  Future<void> sendImage(File imageFile, String recipientId) async {
    final imageBytes = await imageFile.readAsBytes();
    final encrypted = CryptoService.encrypt(imageBytes, sharedKey);

    // 拆分为多个分块
    for (int i = 0; i < encrypted.length; i += chunkSize) {
      final chunk = encrypted.sublist(
        i,
        (i + chunkSize < encrypted.length) ? i + chunkSize : encrypted.length,
      );

      // 通过 WebRTC 数据通道发送分块
      webrtcManager.sendData(chunk);
    }
  }

  // 接收并解密图片分块
  Future<File> receiveImage(List<Uint8List> chunks) async {
    final combinedData = Uint8List.fromList(chunks.expand((x) => x).toList());
    final decrypted = CryptoService.decrypt(combinedData, sharedKey);

    // 保存到临时加密缓存
    final tempFile = File('${tempDir}/temp_image_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await tempFile.writeAsBytes(decrypted!);
    return tempFile;
  }
}
```

#### 验证（第 3 阶段）

- [ ] 发送/接收小于 5 MB 的图片
- [ ] 图片可在聊天中正确显示
- [ ] 阅后图片在查看后会自毁
- [ ] 磁盘上不存储明文图片

---

### 第 4 阶段：语音通话（第 9-11 周）

**目标**：使用 Opus 编解码器实现 WebRTC 语音通话。

#### 第 12 步：语音通话设置

**`lib/features/calling/call_manager.dart`**：

```dart
class CallManager {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  // 发起语音通话
  Future<void> startVoiceCall(String contactId) async {
    // 获取麦克风流
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': false,
    });

    // 将音频轨道添加到对等连接
    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });

    // 创建 offer 并发送给对端
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    // TODO: 通过 signaling 发送 offer
  }

  // 接听来电语音通话
  Future<void> answerVoiceCall(RTCSessionDescription offer) async {
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': false,
    });

    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });

    await _peerConnection!.setRemoteDescription(offer);
    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);
    // TODO: 向呼叫方发送 answer
  }

  // 结束通话
  void endCall() {
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();
    _remoteStream?.dispose();
    _peerConnection?.close();
  }
}
```

#### 第 13 步：语音通话界面

**`lib/features/calling/voice_call_screen.dart`**:

```dart
class VoiceCallScreen extends StatefulWidget {
  final String contactName;
  final bool isIncoming;

  const VoiceCallScreen({
    Key? key,
    required this.contactName,
    this.isIncoming = false,
  }) : super(key: key);

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> {
  bool _isMuted = false;
  bool _isSpeakerOn = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.contactName,
              style: const TextStyle(color: Colors.white, fontSize: 24),
            ),
            const SizedBox(height: 20),
            const Text(
              'Voice Call',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 60),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 静音按钮
                IconButton(
                  icon: Icon(_isMuted ? Icons.mic_off : Icons.mic),
                  color: Colors.white,
                  iconSize: 40,
                  onPressed: () {
                    setState(() => _isMuted = !_isMuted);
                    // TODO: 切换麦克风状态
                  },
                ),
                // 挂断按钮
                IconButton(
                  icon: const Icon(Icons.call_end),
                  color: Colors.red,
                  iconSize: 60,
                  onPressed: () {
                    // TODO: 结束通话
                    Navigator.pop(context);
                  },
                ),
                // 扬声器按钮
                IconButton(
                  icon: Icon(_isSpeakerOn ? Icons.volume_up : Icons.volume_down),
                  color: Colors.white,
                  iconSize: 40,
                  onPressed: () {
                    setState(() => _isSpeakerOn = !_isSpeakerOn);
                    // TODO: 切换扬声器状态
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

#### 验证（第 4 阶段）

- [ ] 在两台设备之间发起语音通话
- [ ] 在局域网连接下音频清晰
- [ ] 静音/扬声器控制可正常工作
- [ ] 通话能被干净地结束

---

### 第 5 阶段：视频通话（第 12-14 周）

**目标**：添加视频通话，并将分辨率上限限制为 320p。

#### 第 15 步：视频通话实现

**视频约束（最高 320p）**：
```dart
final constraints = {
  'audio': true,
  'video': {
    'mandatory': {
      'maxWidth': '480',
      'maxHeight': '320',
      'maxFrameRate': '15',
    },
  },
};

_localStream = await navigator.mediaDevices.getUserMedia(constraints);
```

#### 第 16 步：视频通话界面

**`lib/features/calling/video_call_screen.dart`**:

```dart
class VideoCallScreen extends StatefulWidget {
  final String contactName;

  const VideoCallScreen({Key? key, required this.contactName}) : super(key: key);

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  @override
  void initState() {
    super.initState();
    _initRenderers();
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    // TODO: 设置视频流
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 远端视频（全屏）
          RTCVideoView(_remoteRenderer, mirror: false),
          // 本地视频（小窗浮层）
          Positioned(
            top: 40,
            right: 20,
            child: SizedBox(
              width: 120,
              height: 160,
              child: RTCVideoView(_localRenderer, mirror: true),
            ),
          ),
          // 控件
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.flip_camera_ios),
                  color: Colors.white,
                  iconSize: 40,
                  onPressed: () {
                    // TODO: 切换摄像头
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.call_end),
                  color: Colors.red,
                  iconSize: 60,
                  onPressed: () => Navigator.pop(context),
                ),
                IconButton(
                  icon: const Icon(Icons.videocam_off),
                  color: Colors.white,
                  iconSize: 40,
                  onPressed: () {
                    // TODO: 禁用视频
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }
}
```

#### 验证（第 5 阶段）

- [ ] 视频通话以 320p 显示
- [ ] 带宽 < 500 kbps
- [ ] 摄像头切换可正常工作
- [ ] 当带宽不足时可回退到纯音频模式

---

### 第 6 阶段：联系人发现与连接（第 15-17 周）

**目标**：实现 IP 连接、局域网（LAN）发现和二维码交换。

#### 第 18 和第 19 步：IP 连接 + 局域网发现

**`lib/features/contacts/discovery_service.dart`**:

```dart
import 'package:multicast_dns/multicast_dns.dart';

class DiscoveryService {
  static const String serviceType = '_gungchat._tcp';

  // 在局域网中广播设备存在状态
  Future<void> startBroadcast(String deviceName, String deviceId) async {
    final mdns = MDnsClient();
    await mdns.start();

    // 注册服务
    // TODO: 实现 mDNS 服务注册
  }

  // 扫描附近的 GungChat 设备
  Future<List<Contact>> scanNearbyDevices() async {
    final mdns = MDnsClient();
    await mdns.start();

    final List<Contact> devices = [];

    await for (final PtrResourceRecord ptr in mdns.lookup<PtrResourceRecord>(
      ResourceRecordQuery.serverPointer(serviceType),
    )) {
      // 解析发现到的设备信息
      // TODO: 提取设备名称、IP 和 ID
      devices.add(Contact(
        id: 'discovered_id',
        name: 'Discovered Device',
        ipAddress: '192.168.1.100',
        publicKey: '',
      ));
    }

    mdns.stop();
    return devices;
  }

  // 通过手动输入 IP 地址进行连接
  Future<bool> connectViaIP(String ipAddress) async {
    try {
      // TODO: 尝试与该 IP 建立 WebRTC 连接
      return true;
    } catch (e) {
      return false;
    }
  }
}
```

#### 第 20 步：二维码交换

**`lib/features/contacts/qr_code_screen.dart`**:

```dart
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';

class QRCodeScreen extends StatelessWidget {
  final Contact myContact;

  const QRCodeScreen({Key? key, required this.myContact}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 将联系人信息编码为 JSON
    final contactData = jsonEncode({
      'id': myContact.id,
      'name': myContact.name,
      'publicKey': myContact.publicKey,
      'timestamp': DateTime.now().toIso8601String(),
    });

    return Scaffold(
      appBar: AppBar(title: const Text('My QR Code')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            QrImageView(
              data: contactData,
              version: QrVersions.auto,
              size: 300.0,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const QRScannerScreen()),
                );
              },
              child: const Text('Scan QR Code'),
            ),
          ],
        ),
      ),
    );
  }
}

class QRScannerScreen extends StatelessWidget {
  const QRScannerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: MobileScanner(
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null) {
              final contactData = jsonDecode(barcode.rawValue!);
              // TODO: 添加联系人并验证公钥
              Navigator.pop(context, contactData);
              return;
            }
          }
        },
      ),
    );
  }
}
```

#### 验证（第 6 阶段）

- [ ] 手动 IP 连接可正常工作
- [ ] 可自动发现局域网设备
- [ ] 二维码可正确生成和扫描
- [ ] 连接请求需要经过批准

---

### 第 7 阶段：网络优化与 NAT 穿透（第 18-19 周）

**目标**：针对不同网络条件进行优化，并支持互联网 P2P（点对点）连接。

#### 第 22 步：STUN/TURN 配置

**`lib/core/networking/ice_manager.dart`**:

```dart
final Map<String, dynamic> iceConfiguration = {
  'iceServers': [
    // 公共 STUN 服务器
    {'urls': 'stun:stun.l.google.com:19302'},
    {'urls': 'stun:stun1.l.google.com:19302'},
    {'urls': 'stun:stun.cloudflare.com:3478'},

    // 可选：自托管 TURN 服务器
    // {
    //   'urls': 'turn:your-turn-server.com:3478',
    //   'username': 'user',
    //   'credential': 'password'
    // },
  ],
  'iceTransportPolicy': 'all', // 或使用 'relay' 强制走 TURN
};
```

#### 第 23 步：局域网优先

**`lib/core/networking/network_monitor.dart`**:

```dart
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkMonitor {
  // 检测网络类型
  Future<NetworkType> getNetworkType() async {
    final connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.wifi) {
      return NetworkType.wifi;
    } else if (connectivityResult == ConnectivityResult.mobile) {
      return NetworkType.mobile;
    } else {
      return NetworkType.none;
    }
  }

  // 检查对端是否位于同一局域网
  bool isLocalIP(String ipAddress) {
    return ipAddress.startsWith('192.168.') ||
           ipAddress.startsWith('10.') ||
           ipAddress.startsWith('172.');
  }

  // 根据网络情况调整编解码器比特率
  int getOptimalBitrate(NetworkType networkType) {
    switch (networkType) {
      case NetworkType.wifi:
        return 500; // 视频使用 kbps
      case NetworkType.mobile:
        return 200; // 视频使用 kbps
      default:
        return 100;
    }
  }
}

enum NetworkType { wifi, mobile, none }
```

#### 验证（第 7 阶段）

- [ ] P2P 可在不同网络之间正常工作
- [ ] 局域网连接被优先使用
- [ ] 媒体质量可根据网络类型自动调整
- [ ] TURN 中继可作为回退方案正常工作

---

### 第 8 阶段：安全加固与隐私功能（第 20-21 周）

**目标**：增强隐私保护，并实现前向保密（Perfect Forward Secrecy）。

#### 第 25 步：防截屏

**Android** (`android/app/src/main/kotlin/MainActivity.kt`)：
```kotlin
import android.view.WindowManager

override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    window.setFlags(
        WindowManager.LayoutParams.FLAG_SECURE,
        WindowManager.LayoutParams.FLAG_SECURE
    )
}
```

**iOS**（受限 - 进入后台时模糊处理）：
```swift
// 在 AppDelegate.swift 中
NotificationCenter.default.addObserver(
    forName: UIApplication.willResignActiveNotification,
    object: nil,
    queue: .main
) { _ in
    // 模糊处理或隐藏敏感内容
}
```

#### 第 26 步：反监控防护（进程与应用检测防御）

**目标**：检测任何在 GungChat 运行期间试图观察、捕获或检查它的第三方应用、间谍软件、录屏工具、无障碍服务窥探程序或监控进程。向用户发出警告，并强制禁用/阻止有问题的应用。

**`lib/core/guard/surveillance_detector.dart`**:

```dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

/// 监控设备上可能正在监视 GungChat 的应用/进程。
/// 当应用位于前台时，按固定时间间隔执行检查。
class SurveillanceDetector {
  static const _platform = MethodChannel('com.gungchat/guard');
  Timer? _pollTimer;
  final void Function(List<String> threats) onThreatsDetected;

  SurveillanceDetector({required this.onThreatsDetected});

  /// 需要标记的已知包名模式和进程关键字。
  static const List<String> _suspiciousPatterns = [
    // 录屏器 / 屏幕捕获
    'screenrecord', 'screencap', 'screen_record', 'scrcpy',
    // 基于无障碍服务的窥探程序
    'accessibilityservice', 'inputmethod',
    // 商业间谍软件家族
    'mspy', 'flexispy', 'cocospy', 'spyzie', 'hoverwatch',
    'eyezy', 'cerberus', 'xnspy',
    // 远程访问 / 调试桥接
    'teamviewer', 'anydesk', 'vnc', 'adb', 'frida', 'xposed',
    // 键盘记录器 / 剪贴板监视器
    'keylogger', 'clipboard_monitor',
    // 通用监控标记
    'spy', 'monitor', 'tracker', 'sniffer', 'logger',
  ];

  void startMonitoring({Duration interval = const Duration(seconds: 5)}) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(interval, (_) => _scan());
  }

  void stopMonitoring() => _pollTimer?.cancel();

  Future<void> _scan() async {
    try {
      // 平台通道调用原生代码来枚举：
      //   Android - 运行中的服务、已安装软件包、激活的无障碍服务、
      //            MediaProjection 会话、悬浮窗。
      //   iOS     - 后台音频会话、屏幕捕获 API、
      //            MDM 配置（受沙箱限制）。
      final List<dynamic> result =
          await _platform.invokeMethod('getRunningApps');

      final threats = result.cast<String>().where((name) {
        final lower = name.toLowerCase();
        return _suspiciousPatterns.any((p) => lower.contains(p));
      }).toList();

      if (threats.isNotEmpty) {
        onThreatsDetected(threats);
      }
    } on PlatformException catch (_) {
      // 平台通道不可用 - 平稳降级
    }
  }
}
```

**`lib/core/guard/app_shield.dart`**:

```dart
import 'package:flutter/services.dart';

/// 尝试强制停止或禁用已检测到的监控应用。
/// 在 Android 上，这需要 Device Admin 或无障碍权限；
/// 在 iOS 上，应用只能发出警告并拒绝运行。
class AppShield {
  static const _platform = MethodChannel('com.gungchat/guard');

  /// 请求操作系统强制停止指定包（仅 Android）。
  /// 若平台确认终止成功，则返回 true。
  static Future<bool> forceStopApp(String packageName) async {
    try {
      final result = await _platform.invokeMethod<bool>(
        'forceStopApp',
        {'package': packageName},
      );
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// 显示系统级警告对话框；如果威胁无法被
  /// 清除，则锁定 GungChat 本身以防止数据泄露。
  static Future<void> lockdownIfNeeded(List<String> unresolvedThreats) async {
    if (unresolvedThreats.isNotEmpty) {
      await _platform.invokeMethod('enterLockdown');
    }
  }
}
```

**Android 原生辅助代码**（`android/app/src/main/kotlin/.../GuardMethodChannel.kt`）：
```kotlin
// 在 MainActivity 中通过 MethodChannel("com.gungchat/guard") 注册
// getRunningApps  → ActivityManager.getRunningServices() +
//                   PackageManager.getInstalledApplications() +
//                   AccessibilityManager.getEnabledAccessibilityServiceList()
// forceStopApp    → Runtime.exec("am force-stop $pkg")（需要 root 或
//                   Device Owner）或提示用户前往 Settings > Apps > Force Stop
// enterLockdown   → 结束所有 Activity、清空任务栈、擦除临时密钥
```

**在 `main.dart` 中集成**：
```dart
final detector = SurveillanceDetector(
  onThreatsDetected: (threats) {
    // 1. 显示全屏警告浮层，列出检测到的威胁
    // 2. 对每个威胁尝试调用 AppShield.forceStopApp()
    // 3. 如果重试后仍有威胁存在：
    //    - 显示“环境不安全 - GungChat 已锁定”界面
    //    - 从内存中擦除临时会话密钥
    //    - 在威胁清除前拒绝发送/接收
  },
);
detector.startMonitoring();
```

**行为摘要**：
| 情况 | 操作 |
|---|---|
| 启动时检测到可疑应用 | 阻止 GungChat 打开；显示包含应用名称的警告 |
| GungChat 运行时可疑应用启动 | 立即显示警告浮层；尝试强制停止 |
| 强制停止成功 | 关闭警告；恢复正常运行 |
| 强制停止失败（无 root / iOS） | 锁定 GungChat，擦除会话密钥，并引导用户手动卸载 |
| 屏幕录制 / MediaProjection 激活 | 视为严重威胁；立即锁定 |
| 启用了无障碍窥探程序 | 发出警告并拒绝显示消息内容 |

---

#### 第 27 步：双棘轮（前向保密）

**`lib/core/encryption/double_ratchet.dart`**:

```dart
// 实现 Signal 协议的双棘轮
// 参考：https://signal.org/docs/specifications/doubleratchet/

class DoubleRatchet {
  // 简化实现 - 生产环境请使用现成库

  // 根密钥与链密钥
  Uint8List rootKey;
  Uint8List sendChainKey;
  Uint8List receiveChainKey;

  DoubleRatchet(this.rootKey, this.sendChainKey, this.receiveChainKey);

  // 发送时执行棘轮步进
  Uint8List encryptMessage(Uint8List plaintext) {
    // 从链密钥派生消息密钥
    final messageKey = _deriveMessageKey(sendChainKey);
    sendChainKey = _deriveNextChainKey(sendChainKey);

    return CryptoService.encrypt(plaintext, messageKey);
  }

  // 接收时执行棘轮步进
  Uint8List? decryptMessage(Uint8List ciphertext) {
    final messageKey = _deriveMessageKey(receiveChainKey);
    receiveChainKey = _deriveNextChainKey(receiveChainKey);

    return CryptoService.decrypt(ciphertext, messageKey);
  }

  Uint8List _deriveMessageKey(Uint8List chainKey) {
    // 基于 HMAC 的密钥派生
    return Sodium.cryptoAuth(chainKey, Uint8List.fromList('MessageKey'.codeUnits));
  }

  Uint8List _deriveNextChainKey(Uint8List chainKey) {
    return Sodium.cryptoAuth(chainKey, Uint8List.fromList('ChainKey'.codeUnits));
  }
}
```

#### 验证（第 8 阶段）

- [ ] Android 上已阻止截图
- [ ] 反监控防护可检测已知间谍/录屏应用
- [ ] 在检测到威胁时，可正确触发强制停止或锁定
- [ ] 当仍存在未解决威胁时，GungChat 会拒绝运行
- [ ] 已实现前向保密
- [ ] 日志中不包含敏感数据
- [ ] 已检查内存泄漏

---

### 第 9 阶段：打磨与用户体验（第 22-24 周）

**目标**：提升可用性与本地化支持。

#### 第 28 步：深色模式与本地化

**`lib/l10n/app_en.arb`**:
```json
{
  "appTitle": "GungChat",
  "sendMessage": "Send",
  "voiceCall": "Voice Call",
  "videoCall": "Video Call",
  "settings": "Settings",
  "privacySettings": "Privacy Settings",
  "ephemeralMessages": "Ephemeral Messages",
  "autoDestruct": "Auto-destruct after viewing"
}
```

**`lib/l10n/app_zh.arb`**:
```json
{
  "appTitle": "敢说",
  "sendMessage": "发送",
  "voiceCall": "语音通话",
  "videoCall": "视频通话",
  "settings": "设置",
  "privacySettings": "隐私设置",
  "ephemeralMessages": "阅后即焚",
  "autoDestruct": "查看后自动销毁"
}
```

#### 第 29 步：设置界面

**`lib/features/settings/settings_screen.dart`**:

```dart
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text('Dark Mode'),
            trailing: Switch(value: true, onChanged: (val) {}),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            subtitle: const Text('English'),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Privacy Settings'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.timer),
            title: const Text('Default Message Expiry'),
            subtitle: const Text('30 seconds'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.screenshot),
            title: const Text('Screenshot Protection'),
            trailing: Switch(value: true, onChanged: (val) {}),
          ),
          ListTile(
            leading: const Icon(Icons.shield),
            title: const Text('Anti-Surveillance Guard'),
            subtitle: const Text('Detect & block spy apps'),
            trailing: Switch(value: true, onChanged: (val) {}),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.network_check),
            title: const Text('Network Settings'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.data_usage),
            title: const Text('Data Usage'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
```

#### 验证（第 9 阶段）

- [ ] 深色模式切换正确
- [ ] 应用可在英文和中文环境下正常工作
- [ ] 设置在重启后仍能保留
- [ ] 动画流畅

### 第 9.5 阶段：增强型用户体验（UX）功能（第 24-26 周） - *受 lets-chat 启发*

**目标**: 添加借鉴 lets-chat 开源项目的聊天 UX 打磨功能，并为 P2P 加密架构重新设计。

> **来源**: 以下功能灵感来自对 [sdelements/lets-chat](https://github.com/sdelements/lets-chat) 的分析，它是一个自托管团队聊天应用。所有实现都已针对 GungChat 的无服务器、端到端加密、P2P 模型重新设计。

#### 步骤 30A：正在输入指示器

通过加密的 WebRTC 数据通道发送实时“正在输入...”状态。

**`lib/features/chat/typing_indicator_service.dart`**:

```dart
import 'dart:async';

/// 通过加密的 P2P 数据通道发送/接收输入状态。
/// 输入信号属于临时元数据，绝不会持久化或写入日志。
class TypingIndicatorService {
  Timer? _debounceTimer;
  bool _isTyping = false;
  final Duration _timeout = const Duration(seconds: 3);
  final void Function(bool isTyping) onPeerTypingChanged;
  final void Function(bool isTyping) sendTypingStatus;

  TypingIndicatorService({
    required this.onPeerTypingChanged,
    required this.sendTypingStatus,
  });

  /// 在消息输入框每次按键时调用。
  void onLocalKeystroke() {
    if (!_isTyping) {
      _isTyping = true;
      sendTypingStatus(true);
    }
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_timeout, () {
      _isTyping = false;
      sendTypingStatus(false);
    });
  }

  /// 当收到来自对等端的输入状态消息时调用。
  void onRemoteTypingReceived(bool peerIsTyping) {
    onPeerTypingChanged(peerIsTyping);
  }

  void dispose() {
    _debounceTimer?.cancel();
  }
}
```

#### 步骤 30B：消息格式化流水线

客户端格式化器将纯文本消息处理为富显示内容，包括 URL 链接化、内联图片预览、代码块检测和 emoji 渲染。灵感来自 lets-chat 的 `media/js/util/message.js` 格式化链。

**`lib/formatters/message_formatter.dart`**:

```dart
/// 将原始消息文本处理为结构化显示片段。
/// 所有格式化都只在客户端进行，加密负载始终为纯文本。
class MessageFormatter {
  /// 检测并将消息内容切分为带类型的片段。
  static List<MessageSegment> format(String rawText) {
    final segments = <MessageSegment>[];

    // 1. 代码块检测（三反引号或多行粘贴）
    if (rawText.contains('```') || _isMultilinePaste(rawText)) {
      segments.add(MessageSegment(type: SegmentType.codeBlock, content: rawText));
      return segments;
    }

    // 2. URL 检测与链接化
    final urlPattern = RegExp(
      r'https?://[^\s<>\]\)]+',
      caseSensitive: false,
    );

    int lastIndex = 0;
    for (final match in urlPattern.allMatches(rawText)) {
      if (match.start > lastIndex) {
        segments.add(MessageSegment(
          type: SegmentType.text,
          content: rawText.substring(lastIndex, match.start),
        ));
      }

      final url = match.group(0)!;
      if (_isImageUrl(url)) {
        segments.add(MessageSegment(type: SegmentType.imageEmbed, content: url));
      } else {
        segments.add(MessageSegment(type: SegmentType.link, content: url));
      }
      lastIndex = match.end;
    }

    if (lastIndex < rawText.length) {
      segments.add(MessageSegment(
        type: SegmentType.text,
        content: rawText.substring(lastIndex),
      ));
    }

    return segments.isEmpty
        ? [MessageSegment(type: SegmentType.text, content: rawText)]
        : segments;
  }

  static bool _isImageUrl(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp');
  }

  static bool _isMultilinePaste(String text) {
    return '\n'.allMatches(text).length >= 3;
  }
}

enum SegmentType { text, link, imageEmbed, codeBlock, emoji }

class MessageSegment {
  final SegmentType type;
  final String content;
  const MessageSegment({required this.type, required this.content});
}
```

#### 步骤 30C：已读回执（尊重隐私）

通过数据通道发送加密的送达与已读确认。**仅在用户选择加入（opt-in）时启用**，默认关闭以尊重隐私。lets-chat 完全没有这个功能；GungChat 在加入隐私控制后实现它。

```dart
enum ReceiptType { delivered, read }

class ReadReceiptService {
  bool enabled; // 用户可配置，默认关闭

  ReadReceiptService({this.enabled = false});

  /// 生成一个加密回执并回传给对等端。
  Map<String, dynamic> createReceipt(String messageId, ReceiptType type) {
    return {
      'type': 'receipt',
      'messageId': messageId,
      'receipt': type.name,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// 处理来自对等端的回执并更新消息状态。
  void handleReceipt(Map<String, dynamic> data, Function(String, ReceiptType) onReceiptReceived) {
    if (!enabled) return;
    final messageId = data['messageId'] as String;
    final type = ReceiptType.values.byName(data['receipt']);
    onReceiptReceived(messageId, type);
  }
}
```

#### 步骤 30D：带隐私控制的在线状态

通过 P2P 通道传输在线/离线/离开状态指示。不同于 lets-chat 的服务器跟踪在线状态，GungChat 的在线状态是点对点直连，并提供“隐身显示”的选项。

```dart
enum PresenceStatus { online, away, offline, invisible }

class PresenceService {
  PresenceStatus _currentStatus = PresenceStatus.online;
  bool showPresence; // 用户开关，如果为 false，则始终对对等端显示为离线

  PresenceService({this.showPresence = true});

  PresenceStatus get currentStatus => _currentStatus;

  /// 将状态变化广播给已连接的对等端。
  Map<String, dynamic> setStatus(PresenceStatus status) {
    _currentStatus = status;
    return {
      'type': 'presence',
      'status': showPresence ? status.name : PresenceStatus.offline.name,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// 根据应用生命周期自动检测离开状态。
  PresenceStatus detectFromAppState(bool isInForeground) {
    if (!isInForeground && _currentStatus == PresenceStatus.online) {
      return PresenceStatus.away;
    }
    return _currentStatus;
  }
}
```

#### 步骤 30E：通知角标与推送提醒

未读消息计数器和系统通知，灵感来自 lets-chat 的标签页角标/favicon/桌面通知系统。这里针对移动端做了适配，使用 Flutter 本地通知。

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  int _unreadCount = 0;

  Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _notifications.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

  /// 当应用处于后台时，为收到的消息显示通知。
  Future<void> showMessageNotification({
    required String contactName,
    required String preview, // 截断预览，或在隐私模式下显示 "Encrypted message"
  }) async {
    _unreadCount++;
    FlutterAppBadger.updateBadgeCount(_unreadCount);

    await _notifications.show(
      contactName.hashCode,
      contactName,
      preview,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'messages', 'Messages',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  void clearBadge() {
    _unreadCount = 0;
    FlutterAppBadger.removeBadge();
  }
}
```

#### 步骤 30F：文件传输校验与预览

在通过数据通道进行加密传输之前，先进行 MIME 类型白名单校验和文件大小限制。将 lets-chat 基于服务器端的 Multer 校验，改造为适用于客户端 P2P 的实现。

```dart
class FileTransferValidator {
  static const int maxFileSizeBytes = 50 * 1024 * 1024; // 50 MB

  static const List<String> allowedMimeTypes = [
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp',
    'video/mp4',
    'audio/aac',
    'audio/opus',
    'application/pdf',
  ];

  /// 在加密和传输前校验文件。
  static FileValidationResult validate(String fileName, String mimeType, int sizeBytes) {
    if (sizeBytes > maxFileSizeBytes) {
      return FileValidationResult(
        valid: false,
        error: 'File exceeds ${maxFileSizeBytes ~/ (1024 * 1024)} MB limit',
      );
    }
    if (!allowedMimeTypes.contains(mimeType)) {
      return FileValidationResult(
        valid: false,
        error: 'File type "$mimeType" not allowed',
      );
    }
    return FileValidationResult(valid: true);
  }
}

class FileValidationResult {
  final bool valid;
  final String? error;
  const FileValidationResult({required this.valid, this.error});
}
```

#### 步骤 30G：本地加密消息搜索

对可选的本地加密消息缓存执行全文搜索。lets-chat 在服务器端使用 MongoDB 文本索引；GungChat 在客户端通过 SQLite FTS5（全文检索）对解密后的消息实现这一能力。

```dart
class MessageSearchService {
  final MessageDatabase _db;

  MessageSearchService(this._db);

  /// 按关键字搜索本地缓存消息。
  /// 只会在加密本地存储中的已解密纯文本上搜索。
  Future<List<Message>> search(String query, {String? contactId}) async {
    final db = await _db.database;
    final where = StringBuffer('content LIKE ?');
    final args = <dynamic>['%$query%'];

    if (contactId != null) {
      where.write(' AND (senderId = ? OR recipientId = ?)');
      args.addAll([contactId, contactId]);
    }

    final results = await db.query(
      'messages',
      where: where.toString(),
      whereArgs: args,
      orderBy: 'timestamp DESC',
      limit: 50,
    );
    return results.map((r) => Message.fromJson(r)).toList();
  }
}
```

#### 步骤 30H：连接韧性与自动重连

在网络中断后自动重连，并进行 WebRTC 会话恢复。灵感来自 lets-chat 的 socket 重连 + 房间重新加入模式，这里改造为适配 P2P 数据通道。

```dart
class ConnectionResilience {
  final WebRTCManager _webrtc;
  final NetworkMonitor _networkMonitor;
  int _retryCount = 0;
  static const int _maxRetries = 10;
  static const Duration _baseDelay = Duration(seconds: 2);

  ConnectionResilience(this._webrtc, this._networkMonitor);

  /// 监控连接状态，并在失败时触发重连。
  void monitorConnection({
    required String peerIp,
    required Function onReconnected,
    required Function onPermanentFailure,
  }) {
    _webrtc.onConnectionStateChange = (state) async {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        await _attemptReconnect(peerIp, onReconnected, onPermanentFailure);
      }
    };
  }

  Future<void> _attemptReconnect(
    String peerIp,
    Function onReconnected,
    Function onPermanentFailure,
  ) async {
    while (_retryCount < _maxRetries) {
      _retryCount++;
      final delay = _baseDelay * _retryCount; // 指数退避
      await Future.delayed(delay);

      final networkType = await _networkMonitor.getNetworkType();
      if (networkType == NetworkType.none) continue;

      try {
        await _webrtc.reconnect(peerIp);
        _retryCount = 0;
        onReconnected();
        return;
      } catch (_) {
        // 继续重试循环
      }
    }
    onPermanentFailure();
  }
}
```

#### 步骤 30I：扩展本地化

将 i18n 支持从 2 种语言扩展到 10+ 种。lets-chat 内置 17 种语言环境；GungChat 采用其中使用最广泛的语言。

**新增 locale 文件**（添加到 `lib/l10n/`）:

**`app_ja.arb`**（日语）:
```json
{
  "appTitle": "GungChat",
  "sendMessage": "送信",
  "voiceCall": "音声通話",
  "videoCall": "ビデオ通話",
  "settings": "設定",
  "privacySettings": "プライバシー設定",
  "ephemeralMessages": "消えるメッセージ",
  "autoDestruct": "閲覧後に自動削除",
  "typing": "入力中...",
  "online": "オンライン",
  "offline": "オフライン",
  "searchMessages": "メッセージを検索"
}
```

**`app_ko.arb`**（韩语）:
```json
{
  "appTitle": "GungChat",
  "sendMessage": "보내기",
  "voiceCall": "음성 통화",
  "videoCall": "영상 통화",
  "settings": "설정",
  "privacySettings": "개인정보 설정",
  "ephemeralMessages": "사라지는 메시지",
  "autoDestruct": "확인 후 자동 삭제",
  "typing": "입력 중...",
  "online": "온라인",
  "offline": "오프라인",
  "searchMessages": "메시지 검색"
}
```

**`app_ru.arb`**（俄语）:
```json
{
  "appTitle": "GungChat",
  "sendMessage": "Отправить",
  "voiceCall": "Голосовой звонок",
  "videoCall": "Видеозвонок",
  "settings": "Настройки",
  "privacySettings": "Конфиденциальность",
  "ephemeralMessages": "Исчезающие сообщения",
  "autoDestruct": "Автоудаление после просмотра",
  "typing": "печатает...",
  "online": "В сети",
  "offline": "Не в сети",
  "searchMessages": "Поиск сообщений"
}
```

#### 步骤 30J：消息分组 UX

在较短时间窗口内，由同一发送者连续发送的消息会被视觉分组（不重复显示头像/名称）。改编自 lets-chat 的“fragment”渲染模式。

```dart
/// 判断一条消息是否应被渲染为“片段”（与上一条分组）。
class MessageGroupingHelper {
  static const Duration _groupingWindow = Duration(minutes: 2);

  /// 如果这条消息应在不显示头部（名称/头像）的情况下渲染，则返回 true。
  static bool isFragment(Message current, Message? previous) {
    if (previous == null) return false;
    if (current.senderId != previous.senderId) return false;
    return current.timestamp.difference(previous.timestamp) <= _groupingWindow;
  }
}
```

#### 验证（第 9.5 阶段）

- [ ] 对等端按键后 500ms 内出现“正在输入”指示
- [ ] 消息中的 URL 可点击；图片 URL 会显示内联预览
- [ ] 代码块（三反引号或多行粘贴）使用等宽字体样式渲染
- [ ] 已读回执开关生效；回执已加密，且在禁用时不会发送
- [ ] 在线状态能反映应用生命周期（前台 = online，后台 = away）
- [ ] 隐身模式会向对等端隐藏在线状态
- [ ] 当应用处于后台且收到消息时，会显示系统通知
- [ ] 应用图标角标显示未读数量
- [ ] 文件校验会在传输前拒绝超大文件和不允许的 MIME 类型
- [ ] 本地搜索能从加密消息缓存中返回结果
- [ ] 在切换 WiFi 后，自动重连可在 30 秒内成功
- [ ] 同一发送者的连续消息会渲染为分组片段
- [ ] 应用在所有 10+ 种受支持语言中都能正确显示

---

### 第 9.6 阶段：高级消息与安全功能（第 26-29 周） - *受 Rocket.Chat 启发*

**目标**: 添加丰富的消息交互、语音消息、应用安全能力以及高级用户功能，并将 Rocket.Chat 成熟的功能集重新设计为适配 P2P 加密架构的实现。

> **来源**: 以下功能灵感来自对 [RocketChat/Rocket.Chat](https://github.com/RocketChat/Rocket.Chat)（MIT 许可证） 的分析，它是一个功能全面的开源通信平台。所有实现都已针对 GungChat 的无服务器、端到端加密、P2P 模型重新设计。

#### 步骤 35A：消息反应（Emoji Reactions）

按消息维度的 emoji 反应，作为加密元数据更新通过数据通道发送。灵感来自 Rocket.Chat 的 `setReaction.ts` 切换模式。

**`lib/features/chat/reaction_service.dart`**:

```dart
/// 管理消息上的 emoji 反应。
/// 反应通过加密的 P2P 数据通道同步。
/// 每个反应都是轻量级元数据更新，而不是新消息。
class ReactionService {
  /// 切换某条消息上的反应。如果用户已经使用该
  /// emoji 做过反应，则移除；否则添加。
  Map<String, dynamic> toggleReaction({
    required String messageId,
    required String emoji,
    required String myUserId,
    required Map<String, List<String>> currentReactions,
  }) {
    final reactions = Map<String, List<String>>.from(currentReactions);
    final users = reactions[emoji] ?? [];

    if (users.contains(myUserId)) {
      users.remove(myUserId);
      if (users.isEmpty) reactions.remove(emoji);
    } else {
      reactions[emoji] = [...users, myUserId];
    }

    return {
      'type': 'reaction',
      'messageId': messageId,
      'reactions': reactions,
    };
  }
}
```

#### 步骤 35B：消息加星（个人书签）

仅在本地保存的重要消息书签，绝不会传输给对等端。灵感来自 Rocket.Chat 对“star”和“pin”的区分。

```dart
/// 加星消息保存在本地加密的 SQLite 中。
/// 星标属于个人数据，对等端不会知道你收藏了哪些消息。
class StarService {
  final MessageDatabase _db;
  StarService(this._db);

  Future<void> toggleStar(String messageId) async {
    final db = await _db.database;
    final existing = await db.query(
      'starred_messages',
      where: 'messageId = ?',
      whereArgs: [messageId],
    );
    if (existing.isNotEmpty) {
      await db.delete('starred_messages', where: 'messageId = ?', whereArgs: [messageId]);
    } else {
      await db.insert('starred_messages', {
        'messageId': messageId,
        'starredAt': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<List<Message>> getStarredMessages() async {
    final db = await _db.database;
    final results = await db.rawQuery(
      'SELECT m.* FROM messages m INNER JOIN starred_messages s ON m.id = s.messageId ORDER BY s.starredAt DESC',
    );
    return results.map((r) => Message.fromJson(r)).toList();
  }
}
```

#### 步骤 35C：消息编辑与删除（带隐私语义）

编辑或删除已发送消息，并支持可配置行为：软删除（墓碑，占位显示“message deleted”）或硬删除（彻底移除）。灵感来自 Rocket.Chat 的 `updateMessage.ts` 和 `deleteMessage.ts` 生命周期实现。

```dart
enum DeleteMode { tombstone, hardDelete }

class MessageEditService {
  /// 编辑一条消息，并通过加密数据通道通知对等端。
  /// 原始内容会被丢弃（为保护隐私，不保留编辑历史）。
  Map<String, dynamic> editMessage(String messageId, String newContent) {
    return {
      'type': 'messageEdit',
      'messageId': messageId,
      'content': newContent,
      'editedAt': DateTime.now().toIso8601String(),
    };
  }

  /// 使用具备隐私意识的语义删除一条消息。
  /// Tombstone 模式：对等端看到 "This message was deleted"
  /// Hard delete 模式：消息会从双方设备上彻底移除
  Map<String, dynamic> deleteMessage(String messageId, DeleteMode mode) {
    return {
      'type': 'messageDelete',
      'messageId': messageId,
      'mode': mode.name,
      'deletedAt': DateTime.now().toIso8601String(),
    };
  }
}
```

#### 步骤 35D：语音消息（录音与播放）

通过 P2P 数据通道录制、加密并发送音频消息，并在聊天中支持波形播放。灵感来自 Rocket.Chat 的音频消息支持。

```dart
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';

class VoiceMessageService {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  static const int maxDurationSeconds = 120; // 最长 2 分钟

  /// 使用 Opus 编解码器开始录音。
  Future<void> startRecording(String tempPath) async {
    if (await _recorder.hasPermission()) {
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.opus,
          bitRate: 32000, // 32 kbps，适合紧凑语音
          sampleRate: 16000,
        ),
        path: tempPath,
      );
    }
  }

  /// 停止录音并返回音频文件路径。
  Future<String?> stopRecording() async {
    return await _recorder.stop();
  }

  /// 从已解密的文件中播放收到的语音消息。
  Future<void> playVoiceMessage(String filePath) async {
    await _player.play(DeviceFileSource(filePath));
  }

  Future<void> stopPlayback() async {
    await _player.stop();
  }

  void dispose() {
    _recorder.dispose();
    _player.dispose();
  }
}
```

#### 步骤 35E：回复/引用消息

回复某条特定消息，并附带被引用上下文。回复中包含原始消息 ID 的引用以及一段预览片段。灵感来自 Rocket.Chat 的线程式回复系统，这里为 1:1 P2P 场景做了简化。

```dart
class ReplyService {
  /// 创建一条引用原始消息的回复消息。
  Map<String, dynamic> createReply({
    required String originalMessageId,
    required String originalPreview, // 截断到 100 个字符
    required String replyContent,
  }) {
    return {
      'type': 'text',
      'replyTo': {
        'messageId': originalMessageId,
        'preview': originalPreview.length > 100
            ? '${originalPreview.substring(0, 100)}...'
            : originalPreview,
      },
      'content': replyContent,
    };
  }
}
```

**消息模型更新** - 添加到 `lib/models/message.dart`:
```dart
// 将这些字段添加到 Message 类中：
final String? replyToMessageId;   // 被回复消息的 ID
final String? replyToPreview;     // 原始消息的截断预览
final Map<String, List<String>>? reactions; // emoji -> userId 列表
final bool isEdited;              // 消息是否已被编辑
final bool isDeleted;             // 软删除消息的墓碑标记
```

#### 步骤 35F：URL 链接预览（客户端）

在客户端抓取 URL 元数据（标题、描述、图片），并提供隐私控制。**仅在用户选择加入（opt-in）时启用**，默认关闭，以防止通过抓取 URL 泄露 IP。灵感来自 Rocket.Chat 的 oEmbed 管线。

```dart
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;

class LinkPreviewService {
  bool enabled; // 用户开关，出于隐私考虑默认关闭

  LinkPreviewService({this.enabled = false});

  /// 从 URL 抓取元数据。仅在用户已选择加入时调用。
  /// 使用超时机制，避免在慢速服务器上长时间挂起。
  Future<LinkPreview?> fetchPreview(String url) async {
    if (!enabled) return null;

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'GungChat/1.0'}, // 最小化指纹特征
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) return null;

      final document = html_parser.parse(response.body);
      final metaTags = document.getElementsByTagName('meta');

      String? title, description, image;
      for (final tag in metaTags) {
        final property = tag.attributes['property'] ?? tag.attributes['name'];
        final content = tag.attributes['content'];
        if (property == 'og:title') title = content;
        if (property == 'og:description') description = content;
        if (property == 'og:image') image = content;
      }

      title ??= document.querySelector('title')?.text;

      return LinkPreview(
        url: url,
        title: title ?? '',
        description: description,
        imageUrl: image,
      );
    } catch (_) {
      return null;
    }
  }
}

class LinkPreview {
  final String url;
  final String title;
  final String? description;
  final String? imageUrl;
  const LinkPreview({
    required this.url,
    required this.title,
    this.description,
    this.imageUrl,
  });
}
```

#### 步骤 35G：剧透消息（Spoiler Messages）

使用 `||spoiler text||` 语法隐藏消息内容，点击后显示。灵感来自 Rocket.Chat 在 `gazzodown` 中对剧透内容的无障碍渲染。

```dart
/// 解析 ||spoiler|| 语法，并将其渲染为模糊/隐藏文本。
/// 点击后显示。支持无障碍，屏幕阅读器会播报“剧透，点按以显示”。
class SpoilerRenderer {
  static final RegExp _spoilerPattern = RegExp(r'\|\|(.+?)\|\|');

  /// 检查消息是否包含剧透片段。
  static bool hasSpoilers(String text) => _spoilerPattern.hasMatch(text);

  /// 将文本拆分为普通片段和剧透片段。
  static List<SpoilerSegment> parse(String text) {
    final segments = <SpoilerSegment>[];
    int lastEnd = 0;

    for (final match in _spoilerPattern.allMatches(text)) {
      if (match.start > lastEnd) {
        segments.add(SpoilerSegment(
          text: text.substring(lastEnd, match.start),
          isSpoiler: false,
        ));
      }
      segments.add(SpoilerSegment(
        text: match.group(1)!,
        isSpoiler: true,
      ));
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      segments.add(SpoilerSegment(
        text: text.substring(lastEnd),
        isSpoiler: false,
      ));
    }
    return segments;
  }
}

class SpoilerSegment {
  final String text;
  final bool isSpoiler;
  const SpoilerSegment({required this.text, required this.isSpoiler});
}
```

#### 步骤 35H：自定义状态文本

自由文本状态消息（例如 “In a meeting”、“Do not disturb”），与在线状态一起共享给对等端。灵感来自 Rocket.Chat 的 `setUserStatus` 系统。

```dart
class CustomStatusService {
  String _statusText = '';
  final int maxLength = 80;

  /// 设置自定义状态文本并广播给对等端。
  Map<String, dynamic> setStatusText(String text) {
    _statusText = text.length > maxLength ? text.substring(0, maxLength) : text;
    return {
      'type': 'statusText',
      'text': _statusText,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  String get statusText => _statusText;
}
```

#### 步骤 35I：斜杠命令（本地命令框架）

面向高级用户的客户端命令系统。命令仅在本地执行，不会向对等端发送任何内容。灵感来自 Rocket.Chat 的斜杠命令注册表。

```dart
typedef CommandHandler = Future<String?> Function(List<String> args);

class SlashCommandRegistry {
  final Map<String, _Command> _commands = {};

  SlashCommandRegistry() {
    // 注册内置命令
    register('clear', 'Clear chat history from view', _clearChat);
    register('export', 'Export chat to encrypted file', _exportChat);
    register('status', 'Set your status text', _setStatus);
    register('destroy', 'Wipe all local data and keys', _destroyData);
    register('help', 'Show available commands', _showHelp);
  }

  void register(String name, String description, CommandHandler handler) {
    _commands[name] = _Command(name: name, description: description, handler: handler);
  }

  /// 解析并执行斜杠命令。如果不是命令，则返回 null。
  Future<String?> execute(String input) async {
    if (!input.startsWith('/')) return null;
    final parts = input.substring(1).split(' ');
    final commandName = parts[0].toLowerCase();
    final args = parts.sublist(1);

    final command = _commands[commandName];
    if (command == null) return 'Unknown command: /$commandName. Type /help for list.';
    return await command.handler(args);
  }

  Future<String?> _clearChat(List<String> args) async => '__clear_view__';
  Future<String?> _exportChat(List<String> args) async => '__export__';
  Future<String?> _setStatus(List<String> args) async => '__status__${args.join(' ')}';
  Future<String?> _destroyData(List<String> args) async => '__destroy__';
  Future<String?> _showHelp(List<String> args) async {
    final help = _commands.values.map((c) => '/${c.name} — ${c.description}').join('\n');
    return help;
  }
}

class _Command {
  final String name;
  final String description;
  final CommandHandler handler;
  const _Command({required this.name, required this.description, required this.handler});
}
```

#### 步骤 35J：聊天数据导出（本地加密导出）

将会话历史导出为加密 ZIP 压缩包。这样用户可以保留个人记录，同时保持隐私。灵感来自 Rocket.Chat 面向 GDPR 的数据导出能力。

```dart
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:share_plus/share_plus.dart';

class ChatExportService {
  final MessageDatabase _db;
  final CryptoService _crypto;

  ChatExportService(this._db, this._crypto);

  /// 将与某个联系人的全部消息导出为加密 JSON 归档。
  Future<File> exportChat(String contactId, String contactName) async {
    final messages = await _db.getMessages(contactId);
    final exportData = {
      'app': 'GungChat',
      'exportedAt': DateTime.now().toIso8601String(),
      'contact': contactName,
      'messageCount': messages.length,
      'messages': messages.map((m) => m.toJson()).toList(),
    };

    final jsonBytes = utf8.encode(jsonEncode(exportData));

    // 压缩
    final archive = Archive();
    archive.addFile(ArchiveFile('chat_export.json', jsonBytes.length, jsonBytes));
    final zipBytes = ZipEncoder().encode(archive);

    // 保存到临时目录并分享
    final tempDir = await getTemporaryDirectory();
    final exportFile = File(
      '${tempDir.path}/gungchat_export_${contactName}_${DateTime.now().millisecondsSinceEpoch}.zip',
    );
    await exportFile.writeAsBytes(zipBytes!);
    return exportFile;
  }

  /// 通过系统分享面板共享导出的文件。
  Future<void> shareExport(File exportFile) async {
    await Share.shareXFiles([XFile(exportFile.path)], text: 'GungChat Export');
  }
}
```

#### 步骤 35K：联系人拉黑

阻止某个对等端建立新的 P2P 连接。被拉黑的联系人保存在本地，并在 WebRTC 信令握手期间进行检查。

```dart
class ContactBlockService {
  final Set<String> _blockedIds = {};
  final SecureStorage _storage;

  ContactBlockService(this._storage);

  Future<void> loadBlockedList() async {
    final stored = await _storage.read(key: 'blocked_contacts');
    if (stored != null) {
      _blockedIds.addAll(stored.split(',').where((s) => s.isNotEmpty));
    }
  }

  Future<void> blockContact(String contactId) async {
    _blockedIds.add(contactId);
    await _persist();
  }

  Future<void> unblockContact(String contactId) async {
    _blockedIds.remove(contactId);
    await _persist();
  }

  bool isBlocked(String contactId) => _blockedIds.contains(contactId);

  List<String> get blockedContacts => _blockedIds.toList();

  Future<void> _persist() async {
    await _storage.write(key: 'blocked_contacts', value: _blockedIds.join(','));
  }
}
```

#### 步骤 35L：应用锁（生物识别 / PIN 认证）

使用生物识别认证（指纹/人脸）或 PIN 码保护应用访问。在启动时，以及应用退到后台后超过可配置超时时间再次返回前台时，都需要认证。

```dart
import 'package:local_auth/local_auth.dart';

class AppLockService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool enabled = false;
  int lockTimeoutSeconds = 60; // 后台 60 秒后重新锁定
  DateTime? _lastAuthenticated;

  /// 检查是否支持生物识别认证。
  Future<bool> isBiometricAvailable() async {
    final canCheck = await _localAuth.canCheckBiometrics;
    final isSupported = await _localAuth.isDeviceSupported();
    return canCheck && isSupported;
  }

  /// 使用生物识别或设备 PIN 进行认证。
  Future<bool> authenticate() async {
    if (!enabled) return true;

    // 如果最近刚通过认证，则跳过
    if (_lastAuthenticated != null &&
        DateTime.now().difference(_lastAuthenticated!).inSeconds < lockTimeoutSeconds) {
      return true;
    }

    try {
      final success = await _localAuth.authenticate(
        localizedReason: 'Unlock GungChat',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // 允许设备 PIN 作为回退方式
        ),
      );
      if (success) _lastAuthenticated = DateTime.now();
      return success;
    } catch (_) {
      return false;
    }
  }

  /// 当应用返回前台时调用，检查是否需要重新认证。
  Future<bool> checkOnResume() async {
    if (!enabled) return true;
    if (_lastAuthenticated == null) return await authenticate();
    if (DateTime.now().difference(_lastAuthenticated!).inSeconds >= lockTimeoutSeconds) {
      return await authenticate();
    }
    return true;
  }
}
```

#### 验证（第 9.6 阶段）

- [ ] 每条消息的 emoji 反应可切换开/关；反应计数显示正确
- [ ] 加星消息在应用重启后仍保留在本地；对等端无法看到星标
- [ ] 已编辑消息显示“edited”指示；对等端能收到更新后的内容
- [ ] 已删除消息根据模式设置显示墓碑，或被彻底移除
- [ ] 语音消息可录制最长 2 分钟；播放时显示进度指示
- [ ] 回复/引用会在回复上方显示原始消息预览
- [ ] 只有在用户选择加入后才抓取链接预览元数据
- [ ] 剧透文本默认隐藏；点击后显示内容
- [ ] 自定义状态文本会与在线状态指示一起显示给对等端
- [ ] 斜杠命令仅在本地执行；`/help` 会列出所有可用命令
- [ ] 聊天导出会生成有效的 ZIP 文件；系统分享面板可正常打开
- [ ] 被拉黑联系人无法建立 WebRTC 连接
- [ ] 应用在启动和后台超时后会提示进行生物识别/PIN 解锁
- [ ] 所有新功能在启用端到端加密时都能正常工作

### 阶段 9.7：UX 打磨与组织功能（第 29-31 周） - *灵感来自 Chatwoot*

**目标**：添加会话组织、快捷回复效率工具、媒体浏览、主题、键盘快捷键和无障碍功能，借鉴 Chatwoot 成熟的 UX 模式，并针对 P2P 加密架构重新设计。

> **来源**：以下功能受对 [chatwoot/chatwoot](https://github.com/chatwoot/chatwoot)（MIT 许可证）这一现代开源客户支持平台的分析启发。所有实现都已针对 GungChat 的无服务器、端到端加密（E2E）、P2P 模式重新设计。

#### 步骤 36A：快捷回复模板（预设回复）

已保存的可复用消息片段，支持按短代码搜索。输入短代码前缀（如 `/hi`），即可从过滤后的模板中选择。灵感来自 Chatwoot 的 `CannedResponse` 模型及其排序搜索。

**`lib/templates/quick_reply_service.dart`**：

```dart
/// 仅本地保存的快捷回复模板，存储于加密的 SQLite 中。
/// 模板属于个人数据，绝不会传输给对端。
class QuickReplyService {
  final MessageDatabase _db;
  QuickReplyService(this._db);

  Future<void> createTemplate(String shortCode, String content) async {
    final db = await _db.database;
    await db.insert('quick_replies', {
      'shortCode': shortCode.toLowerCase(),
      'content': content,
      'usageCount': 0,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  /// 按短代码前缀搜索模板，并按使用频率排序。
  Future<List<QuickReply>> search(String prefix) async {
    final db = await _db.database;
    final results = await db.query(
      'quick_replies',
      where: 'shortCode LIKE ?',
      whereArgs: ['${prefix.toLowerCase()}%'],
      orderBy: 'usageCount DESC',
      limit: 10,
    );
    return results.map((r) => QuickReply.fromJson(r)).toList();
  }

  /// 使用模板并增加其使用计数。
  Future<String> useTemplate(String shortCode) async {
    final db = await _db.database;
    await db.rawUpdate(
      'UPDATE quick_replies SET usageCount = usageCount + 1 WHERE shortCode = ?',
      [shortCode],
    );
    final result = await db.query(
      'quick_replies',
      where: 'shortCode = ?',
      whereArgs: [shortCode],
    );
    return result.first['content'] as String;
  }

  Future<void> deleteTemplate(String shortCode) async {
    final db = await _db.database;
    await db.delete('quick_replies', where: 'shortCode = ?', whereArgs: [shortCode]);
  }

  Future<List<QuickReply>> getAllTemplates() async {
    final db = await _db.database;
    final results = await db.query('quick_replies', orderBy: 'usageCount DESC');
    return results.map((r) => QuickReply.fromJson(r)).toList();
  }
}

class QuickReply {
  final String shortCode;
  final String content;
  final int usageCount;
  const QuickReply({required this.shortCode, required this.content, this.usageCount = 0});

  factory QuickReply.fromJson(Map<String, dynamic> json) => QuickReply(
    shortCode: json['shortCode'],
    content: json['content'],
    usageCount: json['usageCount'] ?? 0,
  );
}
```

#### 步骤 36B：会话标签 / 标记

用于组织联系人会话的彩色标签。标签仅保存在本地，可用于筛选联系人列表。灵感来自 Chatwoot 的标签模型，包括颜色与可见性概念。

```dart
class LabelService {
  final MessageDatabase _db;
  LabelService(this._db);

  Future<void> createLabel(String name, String colorHex) async {
    final db = await _db.database;
    await db.insert('labels', {
      'id': const Uuid().v4(),
      'name': name,
      'color': colorHex,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  /// 将标签分配给某个会话（按联系人 ID）。
  Future<void> addLabelToConversation(String contactId, String labelId) async {
    final db = await _db.database;
    await db.insert('conversation_labels', {
      'contactId': contactId,
      'labelId': labelId,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> removeLabelFromConversation(String contactId, String labelId) async {
    final db = await _db.database;
    await db.delete('conversation_labels',
      where: 'contactId = ? AND labelId = ?',
      whereArgs: [contactId, labelId],
    );
  }

  /// 获取带有指定标签的所有会话。
  Future<List<String>> getConversationsByLabel(String labelId) async {
    final db = await _db.database;
    final results = await db.query('conversation_labels',
      where: 'labelId = ?', whereArgs: [labelId]);
    return results.map((r) => r['contactId'] as String).toList();
  }

  Future<List<Map<String, dynamic>>> getAllLabels() async {
    final db = await _db.database;
    return await db.query('labels', orderBy: 'name ASC');
  }
}
```

#### 步骤 36C：联系人备注（私密注释）

附加到联系人的私密备注，绝不会传输给对端。适合记录与某个联系人的上下文信息。灵感来自 Chatwoot 专门的 `Note` 模型。

```dart
class ContactNotesService {
  final MessageDatabase _db;
  ContactNotesService(this._db);

  Future<void> addNote(String contactId, String noteText) async {
    final db = await _db.database;
    await db.insert('contact_notes', {
      'id': const Uuid().v4(),
      'contactId': contactId,
      'content': noteText,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateNote(String noteId, String newText) async {
    final db = await _db.database;
    await db.update('contact_notes',
      {'content': newText, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?', whereArgs: [noteId],
    );
  }

  Future<void> deleteNote(String noteId) async {
    final db = await _db.database;
    await db.delete('contact_notes', where: 'id = ?', whereArgs: [noteId]);
  }

  Future<List<Map<String, dynamic>>> getNotesForContact(String contactId) async {
    final db = await _db.database;
    return await db.query('contact_notes',
      where: 'contactId = ?', whereArgs: [contactId],
      orderBy: 'updatedAt DESC',
    );
  }
}
```

#### 步骤 36D：多附件消息与位置/联系人分享

支持单条消息包含多个附件（最多 10 个），并为位置共享和联系人卡片提供特殊附件类型。灵感来自 Chatwoot 的附件分类体系。

**消息模型补充** - 添加到 `lib/models/message.dart`：
```dart
// 扩展 MessageType 枚举：
enum MessageType { text, image, audio, video, system, location, contactCard, multiAttachment }

// 添加到 Message 类：
final List<Attachment>? attachments; // 单条消息的多个附件

class Attachment {
  final String id;
  final AttachmentType type;
  final String filePath;    // 本地加密路径
  final String? mimeType;
  final int? sizeBytes;
  final Map<String, dynamic>? metadata; // 位置坐标、联系人信息等

  const Attachment({
    required this.id,
    required this.type,
    required this.filePath,
    this.mimeType,
    this.sizeBytes,
    this.metadata,
  });
}

enum AttachmentType { image, video, audio, document, location, contactCard }
```

**位置共享**：
```dart
import 'package:geolocator/geolocator.dart';

class LocationSharingService {
  /// 获取当前位置，并打包为附件元数据。
  Future<Map<String, dynamic>?> getCurrentLocation() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final requested = await Geolocator.requestPermission();
      if (requested == LocationPermission.denied) return null;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium, // 平衡隐私与精度
    );

    return {
      'type': 'location',
      'latitude': position.latitude,
      'longitude': position.longitude,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
```

#### 步骤 36E：共享媒体图库

浏览某个会话中共享的所有媒体（图片、视频、文档、语音消息），支持网格/列表视图切换，以及全屏图片查看器。灵感来自 Chatwoot 按会话建立的附件索引。

```dart
import 'package:photo_view/photo_view.dart';

class MediaGalleryService {
  final MessageDatabase _db;
  MediaGalleryService(this._db);

  /// 获取某个会话的全部媒体附件，并按类型分类。
  Future<Map<String, List<Message>>> getMediaByType(String contactId) async {
    final db = await _db.database;
    final imageTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
    final videoTypes = ['video/mp4'];
    final audioTypes = ['audio/opus', 'audio/aac'];

    final allMedia = await db.query(
      'messages',
      where: '(senderId = ? OR recipientId = ?) AND type IN (?, ?, ?, ?)',
      whereArgs: [contactId, contactId,
        MessageType.image.index, MessageType.video.index,
        MessageType.audio.index, MessageType.multiAttachment.index],
      orderBy: 'timestamp DESC',
    );

    final messages = allMedia.map((r) => Message.fromJson(r)).toList();

    return {
      'images': messages.where((m) => m.type == MessageType.image).toList(),
      'videos': messages.where((m) => m.type == MessageType.video).toList(),
      'audio': messages.where((m) => m.type == MessageType.audio).toList(),
      'documents': messages.where((m) =>
        m.type == MessageType.multiAttachment).toList(),
    };
  }
}
```

#### 步骤 36F：主题系统（浅色 / 深色 / 自动）

持久化外观模式，并支持跟随系统自动检测。灵感来自 Chatwoot 的 light/dark/auto 外观组合式实现。

```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { light, dark, auto }

class ThemeService extends ChangeNotifier {
  AppThemeMode _mode = AppThemeMode.auto;
  static const String _key = 'theme_mode';

  AppThemeMode get mode => _mode;

  ThemeMode get flutterThemeMode {
    switch (_mode) {
      case AppThemeMode.light: return ThemeMode.light;
      case AppThemeMode.dark: return ThemeMode.dark;
      case AppThemeMode.auto: return ThemeMode.system;
    }
  }

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);
    if (stored != null) {
      _mode = AppThemeMode.values.byName(stored);
      notifyListeners();
    }
  }

  Future<void> setTheme(AppThemeMode mode) async {
    _mode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
    notifyListeners();
  }

  /// 循环切换主题：auto -> light -> dark -> auto
  Future<void> cycleTheme() async {
    final next = AppThemeMode.values[
      (_mode.index + 1) % AppThemeMode.values.length
    ];
    await setTheme(next);
  }
}
```

#### 步骤 36G：键盘快捷键

为高频用户提供快速导航和操作的键盘快捷键。当 GungChat 通过 Flutter 运行在平板或桌面平台时，这项能力尤其有用。灵感来自 Chatwoot 的热键组合式实现。

```dart
import 'package:flutter/services.dart';

class KeyboardShortcutService {
  final Map<ShortcutActivator, VoidCallback> _shortcuts = {};

  KeyboardShortcutService() {
    // 注册默认快捷键
    _register(LogicalKeyboardKey.keyN, control: true, action: () {});
    // Ctrl+N：新建连接
    _register(LogicalKeyboardKey.keyK, control: true, action: () {});
    // Ctrl+K：快速搜索 / 命令面板
    _register(LogicalKeyboardKey.keyE, control: true, action: () {});
    // Ctrl+E：切换加密详情
    _register(LogicalKeyboardKey.keyM, control: true, shift: true, action: () {});
    // Ctrl+Shift+M：静音当前会话
    _register(LogicalKeyboardKey.keyD, control: true, shift: true, action: () {});
    // Ctrl+Shift+D：切换深色模式
    _register(LogicalKeyboardKey.slash, control: false, action: () {});
    // /：聚焦消息输入框（斜杠命令模式）
  }

  void _register(
    LogicalKeyboardKey key, {
    bool control = false,
    bool shift = false,
    required VoidCallback action,
  }) {
    _shortcuts[SingleActivator(key, control: control, shift: shift)] = action;
  }

  /// 将特定快捷键绑定到某个动作。
  void bind(String shortcutId, VoidCallback action) {
    // 允许在运行时重新绑定快捷键
  }

  Map<ShortcutActivator, VoidCallback> get shortcuts => Map.unmodifiable(_shortcuts);
}
```

#### 步骤 36H：会话静音与稍后提醒

临时静默某个特定会话的通知。可选择永久静音，或静音到某个指定时间。灵感来自 Chatwoot 的会话静音机制和 `snoozed_until` 时间戳。

```dart
class ConversationMuteService {
  final MessageDatabase _db;
  ConversationMuteService(this._db);

  /// 永久静音某个会话。
  Future<void> mute(String contactId) async {
    final db = await _db.database;
    await db.insert('conversation_settings', {
      'contactId': contactId,
      'muted': 1,
      'snoozedUntil': null,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// 将通知静音到指定时间。
  Future<void> snoozeUntil(String contactId, DateTime until) async {
    final db = await _db.database;
    await db.insert('conversation_settings', {
      'contactId': contactId,
      'muted': 0,
      'snoozedUntil': until.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// 取消静音 / 取消稍后提醒。
  Future<void> unmute(String contactId) async {
    final db = await _db.database;
    await db.delete('conversation_settings',
      where: 'contactId = ?', whereArgs: [contactId]);
  }

  /// 检查该会话此刻是否应接收通知。
  Future<bool> shouldNotify(String contactId) async {
    final db = await _db.database;
    final result = await db.query('conversation_settings',
      where: 'contactId = ?', whereArgs: [contactId]);
    if (result.isEmpty) return true;

    final settings = result.first;
    if (settings['muted'] == 1) return false;

    final snoozedUntil = settings['snoozedUntil'];
    if (snoozedUntil != null) {
      return DateTime.now().isAfter(DateTime.parse(snoozedUntil as String));
    }
    return true;
  }
}
```

#### 步骤 36I：细粒度通知偏好设置

按事件类型分别控制通知：可单独启用/禁用消息、通话、在线状态变化和连接请求的通知。灵感来自 Chatwoot 的 `NotificationSetting` 按事件切换模型。

```dart
class NotificationPreferencesService {
  final SharedPreferences _prefs;
  NotificationPreferencesService(this._prefs);

  static const Map<String, bool> _defaults = {
    'notify_messages': true,
    'notify_calls': true,
    'notify_presence': false,
    'notify_connection_requests': true,
    'notify_reactions': false,
    'notify_sound': true,
    'notify_vibrate': true,
  };

  bool getPreference(String key) {
    return _prefs.getBool(key) ?? _defaults[key] ?? true;
  }

  Future<void> setPreference(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  Map<String, bool> getAllPreferences() {
    return _defaults.map((key, defaultValue) =>
      MapEntry(key, _prefs.getBool(key) ?? defaultValue));
  }
}
```

#### 步骤 36J：无障碍（A11y）指南

以无障碍优先的设计模式覆盖所有 GungChat 界面。灵感来自 Chatwoot 的 ARIA 标签、开关语义和键盘导航设计。

**实现指南**（适用于所有 UI 组件）：

```dart
/// 所有 GungChat 组件的无障碍指南：
///
/// 1. 语义：用 Semantics() 组件包裹交互元素
///    - 包含 label、hint，以及 button/toggle/textField 角色
///    - 示例：Semantics(label: 'Send message', button: true, child: ...)
///
/// 2. 大尺寸触控目标：所有可点击元素最小为 48x48dp
///
/// 3. 状态变化时进行屏幕阅读器播报：
///    SemanticsService.announce('Message sent', TextDirection.ltr);
///
/// 4. 焦点管理：
///    - 打开聊天时自动聚焦消息输入框
///    - 对话框关闭后返回焦点
///    - 使用 FocusTraversalGroup 提供符合逻辑的 Tab 顺序
///
/// 5. 高对比度支持：
///    - 使用 MediaQuery.highContrast 检测并适配
///    - 文本最小对比度为 4.5:1
///    - 大号文本和 UI 组件最小为 3:1
///
/// 6. 减少动画：
///    - 遵循 MediaQuery.disableAnimations
///    - 为所有动画提供低动态替代方案
///
/// 7. 文字缩放：
///    - 支持系统字体大小放大到 2.0x 且不发生布局溢出
///    - 使用 MediaQuery.textScaleFactor 设为 2.0 进行测试

class A11yHelper {
  /// 检查是否偏好减少动画。
  static bool prefersReducedMotion(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }

  /// 检查是否启用高对比度。
  static bool isHighContrast(BuildContext context) {
    return MediaQuery.of(context).highContrast;
  }

  /// 向屏幕阅读器播报状态变化。
  static void announce(String message) {
    SemanticsService.announce(message, TextDirection.ltr);
  }
}
```

#### 验证清单（阶段 9.7）

- [ ] 快捷回复模板：可创建、按短代码前缀搜索、使用和删除
- [ ] 会话标签：可创建颜色标签、分配/移除标签，并按标签筛选
- [ ] 联系人备注：可新增、编辑、删除；备注对对端永不可见
- [ ] 多附件消息：单条消息最多可发送 10 个文件
- [ ] 位置共享：当前位置坐标作为加密附件发送
- [ ] 联系人卡片分享：可分享联系人的公钥 + 名称
- [ ] 媒体图库：可按会话浏览图片/视频/音频/文档
- [ ] 支持全屏图片查看器和双指缩放
- [ ] 主题可在浅色/深色/自动模式之间正确切换
- [ ] 平板/桌面端键盘快捷键可用（Ctrl+K 搜索、Ctrl+Shift+D 深色模式）
- [ ] 会话静音可阻止通知；稍后提醒会在指定时间恢复
- [ ] 通知偏好：按事件类型切换后可在重启后保持
- [ ] 屏幕阅读器可播报消息发送/接收、连接状态变化
- [ ] 所有触控目标均满足最小 48x48dp
- [ ] 字体缩放到 2.0x 不会破坏布局

---

### 阶段 10：测试与部署（第 32-33 周）

**目标**：完成全面测试并进行开源发布。

#### 步骤 31：测试

**单元测试**（`test/crypto_service_test.dart`）：
```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CryptoService', () {
    test('encrypts and decrypts message correctly', () {
      final plaintext = Uint8List.fromList('Hello GungChat'.codeUnits);
      final sharedKey = RandomBytes.buffer(32);

      final encrypted = CryptoService.encrypt(plaintext, sharedKey);
      final decrypted = CryptoService.decrypt(encrypted, sharedKey);

      expect(decrypted, equals(plaintext));
    });
  });
}
```

**集成测试**（`integration_test/app_test.dart`）：
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('send and receive text message', (WidgetTester tester) async {
    // TODO: 测试完整消息流程
  });
}
```

#### 步骤 32：构建发布版本

**Android**：
```bash
flutter build apk --release --obfuscate --split-debug-info=build/debug-info
flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info
```

**iOS**：
```bash
flutter build ios --release
```

#### 步骤 33：文档

创建：
- **README.md** - 项目概览、功能说明、安装方法
- **CONTRIBUTING.md** - 如何参与贡献（编码规范、PR 流程）
- **USER_GUIDE.md** - 应用使用说明
- **ARCHITECTURE.md** - 技术架构文档

#### 步骤 34：开源发布

1. 选择许可证（面向隐私的应用推荐 GPLv3）
2. 发布到 GitHub/GitLab
3. 提交到 F-Droid（可复现构建）
4. 可选：Google Play / App Store（需要开发者账号）

#### 验证清单（阶段 10）

- [ ] 所有测试通过
- [ ] 发布构建可在测试设备上运行
- [ ] 文档完整
- [ ] 无严重缺陷

---

## 关键架构决策

### 1. 无服务器的手机号发现

**挑战**：传统手机号查找需要中心化目录服务。

**解决方案**：
- **主要方式**：QR 码交换（完全无服务器，保护隐私）
- **次要方式**：面向附近用户的 NFC/Bluetooth 联系人交换
- **未来**：DHT（分布式哈希表）用于去中心化联系人发现

**权衡**：相比 WhatsApp 式的手机号同步，这种方式便利性更低，但能保持“无服务器”原则。

### 2. STUN vs. TURN

- **STUN**：适用于大多数连接的免费公共服务器（成功率 90%）
- **TURN**：面向对称 NAT 的可选自托管中继（覆盖 5-10% 用户）

**决策**：默认使用公共 STUN 服务器，并为高级用户提供 TURN 搭建文档。

### 3. 消息持久化

**规格**：默认采用“阅后即焚”（阅读后销毁）

**实现**：
- 消息默认是临时的
- 可选的本地加密存储（用户可配置：不保存、1 小时、1 天、1 周）
- 卸载应用时自动清除

### 4. iOS 后台限制

**问题**：iOS 会杀掉后台应用，导致来电无法正常接入。

**选项**：
- A) 使用 VoIP 推送通知（需要一个最小化的 APNs 中继服务器）
- B) 接受限制（通话仅在前台可用）

**建议**：从实际可用性出发选择 A（对“无服务器”原则的最小破例）。

---

## 风险与缓解措施

| 风险 | 影响 | 缓解措施 |
|------|--------|-----------|
| **NAT 穿透失败** | P2P 连接失败 | 实现 TURN 中继，采用更激进的 ICE 配置 |
| **iOS 后台限制** | 漏接来电 | 使用 VoIP 推送，或明确记录该限制 |
| **联系人发现 UX** | QR 码不如手机号同步方便 | 优化 QR 扫描体验，支持 NFC |
| **视频带宽** | 移动数据消耗高 | 自适应码率，必要时回退为音频 |
| **加密漏洞** | 安全泄露 | 使用经过审计的库，进行安全评审 |
| **低端设备性能** | 应用崩溃/卡顿 | 优化 Flutter 构建，并在低配设备上测试 |

---

## 成功指标（MVP）

### 功能需求

- ✅ 两位用户可通过 IP 地址或局域网建立连接
- ✅ 文本消息已加密，且送达时间 < 1 秒
- ✅ 小于 5 MB 的图片可成功传输
- ✅ 在 WiFi 环境下语音通话音质清晰
- ✅ 320p 视频通话带宽 < 500 kbps
- ✅ 消息可按配置自毁
- ✅ 设备上不存储明文数据
- ✅ 正在输入提示可在 500ms 内出现
- ✅ 已读回执在启用时可送达（用户主动选择加入）
- ✅ 在线状态可反映实时连接状态
- ✅ 文件传输在发送前完成校验（MIME 类型 + 大小）
- ✅ 本地加密搜索可在 < 200ms 内返回结果
- ✅ 自动重连可在 30 秒内恢复会话
- ✅ 系统通知和角标计数器正常工作
- ✅ 消息上的 Emoji 反应可正确切换
- ✅ 语音消息可录制、加密、发送并播放
- ✅ 消息编辑/删除可正确同步到对端，并保持正确语义
- ✅ 回复/引用可显示原始消息上下文
- ✅ 应用锁可通过生物识别/PIN 防止未授权访问
- ✅ 联系人拉黑可阻止连接建立
- ✅ 聊天数据导出可生成有效的加密归档
- ✅ 快捷回复模板可通过短代码搜索
- ✅ 会话标签和媒体图库功能可用
- ✅ 主题系统（浅色/深色/自动）可持久化保存偏好
- ✅ 会话静音/稍后提醒可正确抑制通知
- ✅ 已在 Android TalkBack 和 iOS VoiceOver 上验证屏幕阅读器兼容性

### 平台支持

- ✅ Android 9+（API level 28+）
- ✅ iOS 13+（iPhone 6s 及更新机型）

### 本地化

- ✅ 10+ 种语言：英语、中文（简体与繁体）、日语、韩语、俄语、西班牙语、法语、德语、葡萄牙语

### 开源

- ✅ 使用 GPL/MIT/Apache 许可证发布源代码
- ✅ 提供 F-Droid 可复现构建

---

## 后续步骤

### 立即行动（本周）

1. **初始化 Flutter 项目**
   ```bash
   flutter create gungchat
   cd gungchat
   ```

2. **设置 Git 仓库**
   ```bash
   git init
   git remote add origin https://github.com/yourusername/gungchat.git
   ```

3. **将依赖添加到 `pubspec.yaml`**
   - 从阶段 1 的步骤 3 复制依赖项

4. **创建目录结构**
   - 创建 `lib/core/`、`lib/features/`、`lib/models/` 目录

5. **实现基础加密测试**
   - 创建 `lib/core/encryption/crypto_service.dart`
   - 编写单元测试，验证加密功能正常工作

### 第 1-3 周目标（阶段 1）

- [ ] Flutter 项目已初始化并可成功构建
- [ ] 加密层已实现并通过测试
- [ ] 两台测试设备之间已建立基础 WebRTC 连接
- [ ] 简单 UI 可显示连接状态

---

## 开放问题

1. **iOS 后台通话**：接受最小化 APNs 中继服务器，还是记录“仅前台可用”的限制？
   - **建议**：为保证可用性，使用 VoIP 推送

2. **应用分发**：仅上 F-Droid，还是同时上 Google Play / App Store？
   - **建议**：先上 F-Droid，有需求时再进入商业应用商店

3. **TURN 服务器**：提供自托管指南，还是在 MVP 中跳过？
   - **建议**：写入高级部署指南，但不作为 MVP 必需项

4. **默认消息保留策略**：始终临时，还是允许可选持久化？
   - **建议**：默认临时，设置中最多允许保留 1 周

---

## 附录

### 参考资源

- **Flutter WebRTC 插件**: https://pub.dev/packages/flutter_webrtc
- **libsodium 文档**: https://libsodium.gitbook.io/
- **WebRTC 示例**: https://webrtc.github.io/samples/
- **Signal 协议**: https://signal.org/docs/specifications/doubleratchet/
- **mDNS 服务发现**: https://pub.dev/packages/multicast_dns
- **F-Droid 构建流程**: https://f-droid.org/docs/

### 预估工作量

- **单人开发者（全职）**：MVP 约需 6-8 个月
- **2-3 人团队（兼职）**：MVP 约需 9-12 个月
- **预估团队（全职）**：MVP 约需 3-4 个月

### 受 lets-chat 启发的功能（开源归因）

以下 GungChat 功能来自对 [sdelements/lets-chat](https://github.com/sdelements/lets-chat)（MIT 许可证）的分析与提炼。lets-chat 是一款自托管团队聊天应用。所有实现都已针对 GungChat 的无服务器、端到端加密、P2P 架构进行**从零重新设计**：

| lets-chat 功能 | GungChat 适配 | 关键差异 |
|---|---|---|
| 输入中提示（socket.io） | 通过加密 WebRTC 数据通道传递输入状态 | 无服务器中继；仅点对点 |
| 消息格式化管线 | 客户端 URL/图片/代码块格式化器 | 所有格式化均在客户端对解密后的明文执行 |
| 在线状态跟踪（由服务器协调） | 带隐身模式的 P2P 在线状态 | 隐私优先：用户主动开启，无服务器跟踪 |
| 桌面通知 + 标签页角标 | 移动端推送通知 + 应用角标 | 通过 Flutter 实现原生移动通知 |
| 带 MIME 校验的文件上传 | 加密传输前在客户端做校验 | 无服务器上传；直接 P2P 加密传输 |
| 聊天记录搜索（MongoDB 文本索引） | 本地加密 SQLite FTS 搜索 | 仅搜索解密缓存；无服务器索引 |
| Socket 重连 + 房间重入 | 带指数退避的 WebRTC 自动重连 | 通过 P2P 恢复会话，而非服务器会话 |
| 消息片段（同发送者分组） | 2 分钟窗口内的消息分组 | 同样的 UX 概念，不同的渲染栈 |
| 17 语言 i18n（服务端） | 10+ 语言的 Flutter ARB 文件 | 仅客户端；无服务端语言检测 |
| Emote/emoji YAML 包 | Emoji 选择器 + 内联 Emoji 渲染 | 使用标准 Unicode Emoji，而非自定义表情包 |
| 已读回执 | **新增**（lets-chat 中没有）- 可选加入的加密已读回执 | 保护隐私；lets-chat 完全没有此功能 |
| OTR 消息透传 | 不需要 - 所有消息默认就是端到端加密 | GungChat 从设计上就是“默认加密” |
| 认证限流 / 速率限制 | 连接尝试速率限制 | 针对 P2P 连接请求进行了适配 |

### 受 Rocket.Chat 启发的功能（开源归因）

以下 GungChat 功能来自对 [RocketChat/Rocket.Chat](https://github.com/RocketChat/Rocket.Chat)（MIT 许可证）这一综合型开源通信平台的分析与提炼。所有实现都已针对 GungChat 的无服务器、端到端加密、P2P 架构进行**从零重新设计**：

| Rocket.Chat 功能 | GungChat 适配 | 关键差异 |
|---|---|---|
| Emoji 反应（`setReaction.ts`） | 通过加密数据通道切换反应 | 无服务器数据库；反应作为 P2P 元数据更新传递 |
| 星标与置顶消息 | 仅本地的星标书签 | 星标绝不离开设备；无服务端置顶 |
| 带历史的消息编辑/删除 | 带隐私优先墓碑语义（tombstone）的编辑/删除 | 不保留编辑历史（保护隐私）；支持硬删除 |
| 语音消息（文件上传） | 使用 Opus 编解码器录音并加密 P2P 传输 | 直接加密传输；无服务器存储 |
| 线程式回复 | 带引用预览的消息回复 | 为 1:1 聊天做了简化；无线程分叉 |
| oEmbed URL 预览管线 | 客户端 OG 元数据抓取（可选加入） | 默认关闭，防止 IP 泄露 |
| 剧透渲染（`gazzodown`） | `\|\|spoiler\|\|` 语法，点击后显示 | 无障碍优先，支持屏幕阅读器 |
| 自定义用户状态文本 | 通过 P2P 通道随在线状态一起发送状态文本 | 仅点对点；无服务器目录 |
| 斜杠命令框架 | 仅本地命令（/clear、/export、/help、/destroy） | 命令在客户端执行；不会发送给对端 |
| GDPR 数据导出 | 通过分享面板导出加密 ZIP | 仅本地；不需要服务器请求 |
| 审核/拉黑 API | 在 WebRTC 握手层进行联系人拉黑 | 在连接建立前本地执行 |
| N/A（企业功能） | 生物识别/PIN 应用锁 | **新增** - Rocket.Chat 开源核心中没有 |
| E2EE 密钥生命周期 API | 调整为双棘轮密钥轮换 | 比 Rocket.Chat 的模型具有更强的前向保密性 |

### 受 Chatwoot 启发的功能（开源归因）

以下 GungChat 功能来自对 [chatwoot/chatwoot](https://github.com/chatwoot/chatwoot)（MIT 许可证）这一现代开源客户支持平台的分析与提炼。所有实现都已针对 GungChat 的无服务器、端到端加密、P2P 架构进行**从零重新设计**：

| Chatwoot 功能 | GungChat 适配 | 关键差异 |
|---|---|---|
| 带短代码搜索的预设回复 | 存储在加密 SQLite 中的快捷回复模板 | 仅本地；不做服务器同步；按使用频率排序 |
| 带颜色的会话标签 | 彩色会话标签 | 仅本地；无团队共享标签 |
| 联系人备注（CRUD） | 私密联系人注释 | 绝不传输；纯本地注释 |
| 多附件消息（最多 15 个） | 单条消息最多 10 个加密附件 | P2P 分块传输；无服务器上传 |
| 附件分类体系（位置、联系人卡片） | 位置共享 + 联系人卡片类型 | 仅客户端；GPS 需用户主动授权以保护隐私 |
| 按会话建立附件索引 | 带分类视图的共享媒体图库 | 按类型查询本地加密缓存 |
| light/dark/auto 外观模式 | 带系统自动检测的主题服务 | Flutter ThemeMode 集成 |
| 键盘快捷键组合式实现 | 快捷键注册表（Ctrl+K、Ctrl+Shift+D 等） | 针对 Flutter 平板/桌面端优化 |
| 会话静音 + snoozed_until | 永久静音或静音到指定时间戳 | 本地抑制通知 |
| 按事件细分的通知设置 | 按事件类型细分开关 | 无服务器；基于 SharedPreferences |
| ARIA 标签、键盘导航、屏幕阅读器 | A11y 辅助工具 + 设计指南 | Flutter Semantics API；48dp 触控目标 |
| Action Cable 实时事件 | **不需要** - WebRTC 数据通道天然就是实时的 | GungChat 本身已是 P2P 实时 |
| 自动化规则 / 宏 | **排除** - 对 1:1 P2P 聊天来说属于过度设计 | 未来可为高级用户斜杠命令再考虑 |
| CSAT 满意度调查 / 反馈 | **排除** - 这是客服台概念，不是点对点聊天 | 不适用于 P2P 模型 |

### 考虑过的技术替代方案

| 类别 | 选型 | 备选方案 | 原因 |
|----------|--------|--------------|--------|
| 框架 | Flutter | React Native, Native | 单一代码库，支持 WebRTC |
| 加密 | libsodium | OpenSSL, BoringSSL | API 简单，广泛可信 |
| P2P | WebRTC | 自定义 TCP/UDP | 行业标准，支持 NAT 穿透 |
| 状态管理 | Riverpod | Bloc, Provider | 更现代，样板代码更少 |

---

**文档版本**：1.0
**最后更新**：2026 年 4 月 13 日
**状态**：可开始实施
