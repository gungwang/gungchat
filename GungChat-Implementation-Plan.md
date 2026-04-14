# GungChat Implementation Plan - Copy & Paste Ready

Here's the complete formatted markdown. You can copy this entire content and save it as `GungChat-Implementation-Plan.md`:

---

```markdown
# GungChat (敢说) - Implementation Plan

**Project**: Peer-to-Peer Encrypted Messaging Application
**Target Platforms**: Android & iOS (Mobile-first)
**Technology Stack**: Flutter (Dart)
**Timeline**: Flexible (~33 weeks for MVP)
**Last Updated**: April 13, 2026

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture Overview](#architecture-overview)
3. [Technology Stack](#technology-stack)
4. [Implementation Phases](#implementation-phases)
5. [Key Architectural Decisions](#key-architectural-decisions)
6. [Risks & Mitigations](#risks--mitigations)
7. [Success Metrics](#success-metrics)
8. [Next Steps](#next-steps)

---

## Project Overview

**GungChat (敢说)** is an open-source, peer-to-peer encrypted messaging application built on the principle of **complete privacy and zero server infrastructure**.

### Core Features

- ✅ **No Registration Required** - Direct P2P connections without accounts
- ✅ **End-to-End Encryption** - All communications encrypted with libsodium
- ✅ **Ephemeral Messages** - "阅后即焚" (Burn after reading) by default
- ✅ **Multi-Modal Communication** - Text, images, voice calls, and video calls
- ✅ **Serverless Architecture** - Connects via IP address or local network discovery
- ✅ **Privacy First** - Screenshot prevention, no message history (optional encrypted local cache)
- ✅ **Anti-Surveillance Guard** - Detects apps/processes attempting to monitor GungChat; warns user and force-disables the offending app
- ✅ **LAN Optimized** - Prioritizes local network over internet routing
- ✅ **Typing Indicators** - Real-time "peer is typing..." status over encrypted data channel
- ✅ **Message Formatting** - URL linkification, inline image preview, code block rendering, emoji/emote support
- ✅ **Read Receipts** - Encrypted delivery/read confirmations (privacy-respecting, opt-in)
- ✅ **Presence Status** - Online/offline/away indicators with privacy controls (hideable)
- ✅ **Unread & Mention Badges** - Notification counters and system-level push alerts
- ✅ **File Transfer with Validation** - MIME type allowlist, size limits, preview before send
- ✅ **Local Encrypted Search** - Full-text search over locally cached message history
- ✅ **Connection Resilience** - Auto-reconnect with session state recovery after network interruptions
- ✅ **Extended i18n** - Localization beyond EN/ZH (Japanese, Korean, Russian, Spanish, French, German, etc.)
- ✅ **Message Reactions** - Emoji reactions on individual messages (sent over encrypted channel)
- ✅ **Message Starring** - Personal bookmarks for important messages (local only, never shared)
- ✅ **Message Edit & Delete** - Edit sent messages or delete with privacy-aware tombstone semantics
- ✅ **Voice Messages** - Record and send encrypted audio messages with in-chat playback
- ✅ **Reply/Quote Messages** - Reply to a specific message with quoted context
- ✅ **URL Link Previews** - Client-side metadata extraction with privacy controls (opt-in fetching)
- ✅ **Spoiler Messages** - Hidden content revealed on tap ("||spoiler||" syntax)
- ✅ **Custom Status Text** - Personal status message beyond online/offline/away
- ✅ **Slash Commands** - Local commands (/clear, /export, /status, /destroy)
- ✅ **Chat Data Export** - Encrypted local export of conversation history (GDPR-style)
- ✅ **Contact Blocking** - Block a peer from initiating connections
- ✅ **App Lock** - Biometric (fingerprint/face) or PIN lock for app access
- ✅ **Quick Reply Templates** - Saved reusable message snippets with shortcode search
- ✅ **Conversation Labels** - Color-coded tags for organizing peer conversations
- ✅ **Contact Notes** - Private annotations on contacts (local-only, never shared)
- ✅ **Multi-Attachment Messages** - Multiple files per message + location sharing + contact cards
- ✅ **Shared Media Gallery** - Browse all media shared in a conversation
- ✅ **Theme System** - Light/dark/auto appearance modes
- ✅ **Keyboard Shortcuts** - Power-user navigation and quick actions
- ✅ **Conversation Mute & Snooze** - Temporarily silence notifications per conversation
- ✅ **Granular Notification Preferences** - Per-event-type notification controls
- ✅ **Accessibility (A11y)** - ARIA semantics, keyboard navigation, screen reader support
- ❌ **No Group Chat** - Strictly peer-to-peer only

### Connection Methods

1. **Manual IP Address** - Direct connection via IPv4/IPv6
2. **LAN Discovery** - Auto-discover devices on local network via mDNS
3. **QR Code Exchange** - Share contact information securely (serverless)
4. **Phone Number/Contacts** - Future: DHT-based discovery (Phase 2+)

---

## Architecture Overview

### High-Level Architecture

```
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

### Core Principles

1. **Zero Server Infrastructure** - All communication is peer-to-peer (except optional STUN/TURN for NAT traversal)
2. **End-to-End Encryption** - Messages encrypted before leaving sender's device
3. **Ephemeral by Default** - Messages self-destruct after viewing/time limit
4. **LAN Prioritization** - Local connections preferred over internet routing
5. **Open Source Everything** - All dependencies must be open source

---

## Technology Stack

### Framework & Language

- **Flutter 3.x** - Cross-platform mobile framework (Android + iOS)
- **Dart** - Primary programming language
- **State Management**: Riverpod or Bloc pattern

### Networking & Communication

- **WebRTC** (`flutter_webrtc` plugin)
  - P2P data channels for text/images
  - Audio/video streams for calls
  - Built-in NAT traversal (ICE)
- **STUN Servers** - Public servers (Google, Cloudflare) for connection setup
- **TURN Server** (Optional) - Self-hosted relay for symmetric NAT cases
- **mDNS/Bonjour** (`multicast_dns` package) - LAN device discovery

### Encryption & Security

- **libsodium** - Cryptography library
  - **Key Exchange**: X25519 (Elliptic Curve Diffie-Hellman)
  - **Encryption**: ChaCha20-Poly1305 (authenticated encryption)
  - **Hashing**: SHA-256 for contact matching
- **Double Ratchet** (Phase 8) - Perfect forward secrecy (Signal Protocol)
- **Flutter Secure Storage** - Secure key persistence

### Data Storage

- **SQLite** (`sqflite` package) - Local database
- **SQLCipher** - Encrypted database (optional implementation)
- **Shared Preferences** - App settings

### Media Codecs

- **Audio**: Opus codec (16-48 kbps, built into WebRTC)
- **Video**: VP8/VP9 codec (100-500 kbps, capped at 320p)
- **Image Compression**: `image` package for Flutter

### Permissions & Platform APIs

- **Camera** (`camera` package)
- **Microphone** - WebRTC audio capture
- **Contacts** (`contacts_service` package)
- **Network State** (`connectivity_plus` package)
- **Notifications** (`flutter_local_notifications`)

### Development Tools

- **Version Control**: Git + GitHub/GitLab
- **CI/CD**: GitHub Actions (optional)
- **Testing**: Flutter test framework (unit, widget, integration tests)
- **Code Obfuscation**: Flutter's built-in obfuscation for release builds

---

## Implementation Phases

### Phase 1: Project Foundation & Core Infrastructure (Weeks 1-3)

**Goal**: Set up project structure, encryption layer, and basic WebRTC P2P connection.

#### Step 1: Initialize Flutter Project
```bash
flutter create gungchat
cd gungchat
```

**Tasks**:
- Configure `.gitignore` for Flutter project
- Set up repository (GitHub/GitLab)
- Add open source license (GPLv3 / MIT / Apache 2.0)
- Create `README.md` with project description

#### Step 2: Project Structure

Create the following folder structure:

```
lib/
├── core/
│   ├── encryption/
│   │   ├── crypto_service.dart         # Encryption wrapper
│   │   └── key_manager.dart            # Key generation & storage
│   ├── networking/
│   │   ├── webrtc_manager.dart         # WebRTC connections
│   │   ├── signaling_service.dart      # Peer discovery & signaling
│   │   ├── ice_manager.dart            # STUN/TURN configuration
│   │   └── network_monitor.dart        # Network state detection
│   ├── storage/
│   │   ├── secure_storage.dart         # Encrypted local storage
│   │   └── message_db.dart             # SQLite database wrapper
│   ├── guard/
│   │   ├── surveillance_detector.dart   # Detect spy/monitoring apps & processes
│   │   └── app_shield.dart             # Force-disable or block offending apps
│   └── error/
│       └── error_handler.dart          # Centralized error handling
├── features/
│   ├── chat/
│   │   ├── chat_screen.dart            # Main chat UI
│   │   ├── message_service.dart        # Send/receive messages
│   │   ├── ephemeral_manager.dart      # Self-destruct logic
│   │   └── widgets/
│   │       ├── message_bubble.dart     # Text message widget
│   │       └── image_message_bubble.dart
│   ├── calling/
│   │   ├── call_manager.dart           # Voice/video call logic
│   │   ├── voice_call_screen.dart      # Voice call UI
│   │   ├── video_call_screen.dart      # Video call UI
│   │   └── services/
│   │       ├── call_signaling_service.dart
│   │       └── video_service.dart
│   ├── contacts/
│   │   ├── contacts_screen.dart        # Contacts list UI
│   │   ├── discovery_service.dart      # mDNS & contact lookup
│   │   └── qr_code_screen.dart         # QR code generation/scanning
│   ├── notifications/
│   │   └── notification_service.dart   # Push notifications & badge counters
│   └── settings/
│       └── settings_screen.dart        # App settings UI
├── formatters/
│   ├── message_formatter.dart          # URL linkify, image embed, code blocks
│   ├── emoji_manager.dart              # Emoji/emote rendering & mapping
│   ├── link_preview_service.dart       # Client-side URL metadata extraction
│   └── spoiler_renderer.dart           # Spoiler text parsing & reveal widget
├── commands/
│   └── slash_command_registry.dart     # Local slash command framework
├── security/
│   ├── app_lock_service.dart           # Biometric/PIN app lock
│   └── contact_block_service.dart      # Peer blocking logic
├── templates/
│   └── quick_reply_service.dart        # Canned response / quick reply templates
├── organization/
│   ├── label_service.dart              # Conversation labels/tags
│   ├── contact_notes_service.dart      # Private contact annotations
│   └── conversation_mute_service.dart  # Mute/snooze per conversation
├── media/
│   └── media_gallery_service.dart      # Shared media gallery browser
├── preferences/
│   ├── theme_service.dart              # Light/dark/auto appearance
│   ├── notification_prefs_service.dart # Granular notification controls
│   └── keyboard_shortcut_service.dart  # Keyboard shortcut registry
├── models/
│   ├── message.dart                    # Message data model
│   ├── contact.dart                    # Contact model
│   └── call.dart                       # Call state model
├── ui/
│   ├── screens/                        # Shared screens
│   └── widgets/                        # Reusable widgets
├── l10n/                               # Localization files
│   ├── app_en.arb                      # English strings
│   ├── app_zh.arb                      # Chinese (Simplified) strings
│   ├── app_zh_TW.arb                   # Chinese (Traditional) strings
│   ├── app_ja.arb                      # Japanese strings
│   ├── app_ko.arb                      # Korean strings
│   ├── app_ru.arb                      # Russian strings
│   ├── app_es.arb                      # Spanish strings
│   ├── app_fr.arb                      # French strings
│   ├── app_de.arb                      # German strings
│   └── app_pt.arb                      # Portuguese strings
└── main.dart                           # App entry point
```

#### Step 3: Add Dependencies

**`pubspec.yaml`**:
```yaml
dependencies:
  flutter:
    sdk: flutter

  # WebRTC for P2P communication
  flutter_webrtc: ^0.9.0

  # Encryption
  flutter_sodium: ^0.2.0  # libsodium bindings

  # Storage
  sqflite: ^2.3.0
  flutter_secure_storage: ^9.0.0
  shared_preferences: ^2.2.0

  # State management
  flutter_riverpod: ^2.4.0  # or bloc: ^8.1.0

  # Networking & Discovery
  multicast_dns: ^0.3.2
  connectivity_plus: ^5.0.0

  # Permissions
  permission_handler: ^11.0.0

  # Media
  camera: ^0.10.0
  image_picker: ^1.0.0
  image: ^4.1.0  # Image compression

  # UI
  qr_flutter: ^4.1.0  # QR code generation
  mobile_scanner: ^3.5.0  # QR code scanning

  # Utilities
  path_provider: ^2.1.0
  uuid: ^4.0.0
  linkify: ^5.0.0             # URL detection & linkification
  flutter_linkify: ^6.0.0     # Linkified text widget
  emoji_picker_flutter: ^1.6.0 # Emoji keyboard & picker
  flutter_highlight: ^0.7.0   # Code syntax highlighting
  flutter_local_notifications: ^16.0.0  # System push notifications
  flutter_app_badger: ^1.5.0  # App icon badge counters
  record: ^4.5.0              # Audio recording for voice messages
  audioplayers: ^5.2.0        # Audio playback for voice messages
  local_auth: ^2.1.0          # Biometric authentication (fingerprint/face)
  html: ^0.15.0               # HTML metadata parsing for link previews
  share_plus: ^7.2.0          # Share/export chat data
  archive: ^3.4.0             # ZIP compression for data export
  geolocator: ^10.1.0         # Location sharing in messages
  flutter_contacts: ^1.1.7    # Contact card sharing
  photo_view: ^0.14.0         # Full-screen image viewer for media gallery
  flutter_keyboard_visibility: ^5.4.0  # Keyboard state detection

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  integration_test:
    sdk: flutter
```

Run:
```bash
flutter pub get
```

#### Step 4: Implement Encryption Layer

**`lib/core/encryption/crypto_service.dart`**:

```dart
import 'package:flutter_sodium/flutter_sodium.dart';

class CryptoService {
  // Generate X25519 key pair for this device
  static Future<KeyPair> generateKeyPair() async {
    await Sodium.init();
    return CryptoKx.keyPair();
  }

  // Perform key exchange to derive shared session key
  static Uint8List deriveSharedKey(
    Uint8List mySecretKey,
    Uint8List theirPublicKey,
  ) {
    // X25519 key agreement
    return CryptoBox.beforeNm(theirPublicKey, mySecretKey);
  }

  // Encrypt message with ChaCha20-Poly1305
  static Uint8List encrypt(Uint8List plaintext, Uint8List sharedKey) {
    final nonce = RandomBytes.buffer(CryptoBox.nonceBytes);
    final ciphertext = CryptoBox.easyAfterNm(plaintext, nonce, sharedKey);

    // Prepend nonce to ciphertext
    return Uint8List.fromList([...nonce, ...ciphertext]);
  }

  // Decrypt message
  static Uint8List? decrypt(Uint8List encryptedData, Uint8List sharedKey) {
    final nonce = encryptedData.sublist(0, CryptoBox.nonceBytes);
    final ciphertext = encryptedData.sublist(CryptoBox.nonceBytes);

    try {
      return CryptoBox.openEasyAfterNm(ciphertext, nonce, sharedKey);
    } catch (e) {
      return null; // Decryption failed
    }
  }
}
```

#### Step 5: Set Up Basic WebRTC Connection

**`lib/core/networking/webrtc_manager.dart`**:

```dart
import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCManager {
  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;

  // STUN server configuration
  final Map<String, dynamic> _configuration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ],
  };

  // Initialize P2P connection
  Future<void> createConnection({
    required Function(RTCDataChannelMessage) onMessage,
    required Function(RTCIceCandidate) onIceCandidate,
  }) async {
    _peerConnection = await createPeerConnection(_configuration);

    // Create data channel for messages
    _dataChannel = await _peerConnection!.createDataChannel(
      'messages',
      RTCDataChannelInit()..ordered = true,
    );

    _dataChannel!.onMessage = (message) {
      onMessage(message);
    };

    // ICE candidate callback
    _peerConnection!.onIceCandidate = (candidate) {
      if (candidate != null) {
        onIceCandidate(candidate);
      }
    };
  }

  // Send message over data channel
  void sendMessage(String message) {
    if (_dataChannel != null && _dataChannel!.state == RTCDataChannelState.RTCDataChannelOpen) {
      _dataChannel!.send(RTCDataChannelMessage(message));
    }
  }

  // Create offer (initiator)
  Future<RTCSessionDescription> createOffer() async {
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    return offer;
  }

  // Handle answer (initiator receives this)
  Future<void> setRemoteDescription(RTCSessionDescription description) async {
    await _peerConnection!.setRemoteDescription(description);
  }

  // Handle offer and create answer (receiver)
  Future<RTCSessionDescription> createAnswer(RTCSessionDescription offer) async {
    await _peerConnection!.setRemoteDescription(offer);
    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);
    return answer;
  }

  // Add ICE candidate from peer
  Future<void> addIceCandidate(RTCIceCandidate candidate) async {
    await _peerConnection!.addCandidate(candidate);
  }

  // Close connection
  void close() {
    _dataChannel?.close();
    _peerConnection?.close();
  }
}
```

#### Verification (Phase 1)

- [ ] Flutter app builds and runs on Android/iOS simulator
- [ ] Encryption encrypts/decrypts test messages correctly
- [ ] Two test devices establish WebRTC data channel
- [ ] Basic UI shows connection status

---

### Phase 2: Text Messaging & Ephemeral Messages (Weeks 4-6)

**Goal**: Implement encrypted text messaging with self-destruct capabilities.

#### Step 6: Message Data Model

**`lib/models/message.dart`**:

```dart
import 'package:uuid/uuid.dart';

enum MessageType { text, image, audio, video, system }
enum MessageStatus { sending, sent, delivered, read, failed }

class Message {
  final String id;
  final String senderId;
  final String recipientId;
  final MessageType type;
  final String content; // Encrypted payload
  final DateTime timestamp;
  final MessageStatus status;
  final int? expirySeconds; // Null = no expiry, otherwise self-destruct time
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

  // Check if message should be deleted
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

#### Step 7: Chat UI

**`lib/features/chat/chat_screen.dart`**:

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
      senderId: 'me', // Replace with actual device ID
      recipientId: widget.contactId,
      type: MessageType.text,
      content: _messageController.text,
      expirySeconds: 30, // Self-destruct after 30 seconds
    );

    setState(() {
      _messages.add(message);
    });

    // TODO: Send via WebRTC data channel
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
          // Message list
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
          // Input field
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
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

#### Step 8: Ephemeral Message Manager

**`lib/features/chat/ephemeral_manager.dart`**:

```dart
import 'dart:async';
import 'package:flutter/material.dart';

class EphemeralManager {
  final Map<String, Timer> _timers = {};

  // Start countdown for message self-destruct
  void startTimer(String messageId, int seconds, VoidCallback onExpire) {
    _timers[messageId]?.cancel();
    _timers[messageId] = Timer(Duration(seconds: seconds), () {
      onExpire();
      _timers.remove(messageId);
    });
  }

  // Mark message as viewed and start expiry timer
  void markViewed(Message message, VoidCallback onExpire) {
    if (message.expirySeconds != null) {
      startTimer(message.id, message.expirySeconds!, onExpire);
    }
  }

  // Cancel all timers
  void dispose() {
    for (var timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }
}
```

#### Step 9: Encrypted Local Storage (Optional)

**`lib/core/storage/message_db.dart`**:

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

#### Verification (Phase 2)

- [ ] Send/receive text messages between two devices
- [ ] Messages display in chat UI with timestamps
- [ ] Ephemeral messages self-destruct after configured time
- [ ] Screenshot prevention active (Android: `FLAG_SECURE`)

---

### Phase 3: Image Sharing (Weeks 7-8)

**Goal**: Enable encrypted image capture, transmission, and ephemeral viewing.

#### Step 10: Image Capture & Selection

**Integration**:
```dart
import 'package:image_picker/image_picker.dart';

Future<File?> pickImage(ImageSource source) async {
  final picker = ImagePicker();
  final image = await picker.pickImage(source: source);
  return image != null ? File(image.path) : null;
}
```

#### Step 11: Image Encryption & Chunked Transmission

**`lib/core/networking/file_transfer_manager.dart`**:

```dart
class FileTransferManager {
  static const int chunkSize = 16 * 1024; // 16 KB chunks

  // Encrypt and send image in chunks
  Future<void> sendImage(File imageFile, String recipientId) async {
    final imageBytes = await imageFile.readAsBytes();
    final encrypted = CryptoService.encrypt(imageBytes, sharedKey);

    // Split into chunks
    for (int i = 0; i < encrypted.length; i += chunkSize) {
      final chunk = encrypted.sublist(
        i,
        (i + chunkSize < encrypted.length) ? i + chunkSize : encrypted.length,
      );

      // Send chunk via WebRTC data channel
      webrtcManager.sendData(chunk);
    }
  }

  // Receive and decrypt image chunks
  Future<File> receiveImage(List<Uint8List> chunks) async {
    final combinedData = Uint8List.fromList(chunks.expand((x) => x).toList());
    final decrypted = CryptoService.decrypt(combinedData, sharedKey);

    // Save to temporary encrypted cache
    final tempFile = File('${tempDir}/temp_image_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await tempFile.writeAsBytes(decrypted!);
    return tempFile;
  }
}
```

#### Verification (Phase 3)

- [ ] Send/receive images < 5 MB
- [ ] Images display correctly in chat
- [ ] Ephemeral images self-destruct after viewing
- [ ] No plaintext images stored on disk

---

### Phase 4: Voice Calls (Weeks 9-11)

**Goal**: Implement WebRTC voice calls with Opus codec.

#### Step 12: Voice Call Setup

**`lib/features/calling/call_manager.dart`**:

```dart
class CallManager {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  // Initiate voice call
  Future<void> startVoiceCall(String contactId) async {
    // Get microphone stream
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': false,
    });

    // Add audio track to peer connection
    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });

    // Create offer and send to peer
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    // TODO: Send offer via signaling
  }

  // Accept incoming voice call
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
    // TODO: Send answer to caller
  }

  // End call
  void endCall() {
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();
    _remoteStream?.dispose();
    _peerConnection?.close();
  }
}
```

#### Step 13: Voice Call UI

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
                // Mute button
                IconButton(
                  icon: Icon(_isMuted ? Icons.mic_off : Icons.mic),
                  color: Colors.white,
                  iconSize: 40,
                  onPressed: () {
                    setState(() => _isMuted = !_isMuted);
                    // TODO: Toggle microphone
                  },
                ),
                // End call button
                IconButton(
                  icon: const Icon(Icons.call_end),
                  color: Colors.red,
                  iconSize: 60,
                  onPressed: () {
                    // TODO: End call
                    Navigator.pop(context);
                  },
                ),
                // Speaker button
                IconButton(
                  icon: Icon(_isSpeakerOn ? Icons.volume_up : Icons.volume_down),
                  color: Colors.white,
                  iconSize: 40,
                  onPressed: () {
                    setState(() => _isSpeakerOn = !_isSpeakerOn);
                    // TODO: Toggle speaker
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

#### Verification (Phase 4)

- [ ] Initiate voice call between two devices
- [ ] Audio clear on LAN connections
- [ ] Mute/speaker controls functional
- [ ] Call ends cleanly

---

### Phase 5: Video Calls (Weeks 12-14)

**Goal**: Add video calling with 320p resolution cap.

#### Step 15: Video Call Implementation

**Video constraints (320p max)**:
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

#### Step 16: Video Call UI

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
    // TODO: Set up video streams
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Remote video (full screen)
          RTCVideoView(_remoteRenderer, mirror: false),
          // Local video (small overlay)
          Positioned(
            top: 40,
            right: 20,
            child: SizedBox(
              width: 120,
              height: 160,
              child: RTCVideoView(_localRenderer, mirror: true),
            ),
          ),
          // Controls
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
                    // TODO: Switch camera
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
                    // TODO: Disable video
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

#### Verification (Phase 5)

- [ ] Video call displays at 320p
- [ ] Bandwidth < 500 kbps
- [ ] Camera switching works
- [ ] Fallback to audio-only if bandwidth insufficient

---

### Phase 6: Contact Discovery & Connection (Weeks 15-17)

**Goal**: Implement IP connection, LAN discovery, and QR code exchange.

#### Step 18 & 19: IP Connection + LAN Discovery

**`lib/features/contacts/discovery_service.dart`**:

```dart
import 'package:multicast_dns/multicast_dns.dart';

class DiscoveryService {
  static const String serviceType = '_gungchat._tcp';

  // Broadcast device presence on LAN
  Future<void> startBroadcast(String deviceName, String deviceId) async {
    final mdns = MDnsClient();
    await mdns.start();

    // Register service
    // TODO: Implement mDNS service registration
  }

  // Scan for nearby GungChat devices
  Future<List<Contact>> scanNearbyDevices() async {
    final mdns = MDnsClient();
    await mdns.start();

    final List<Contact> devices = [];

    await for (final PtrResourceRecord ptr in mdns.lookup<PtrResourceRecord>(
      ResourceRecordQuery.serverPointer(serviceType),
    )) {
      // Parse discovered device info
      // TODO: Extract device name, IP, and ID
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

  // Connect via manual IP address
  Future<bool> connectViaIP(String ipAddress) async {
    try {
      // TODO: Attempt WebRTC connection to IP
      return true;
    } catch (e) {
      return false;
    }
  }
}
```

#### Step 20: QR Code Exchange

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
    // Encode contact info as JSON
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
              // TODO: Add contact and verify public key
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

#### Verification (Phase 6)

- [ ] Manual IP connection works
- [ ] LAN devices discovered automatically
- [ ] QR code generates and scans correctly
- [ ] Connection requests require approval

---

### Phase 7: Network Optimization & NAT Traversal (Weeks 18-19)

**Goal**: Optimize for different network conditions and enable internet P2P.

#### Step 22: STUN/TURN Configuration

**`lib/core/networking/ice_manager.dart`**:

```dart
final Map<String, dynamic> iceConfiguration = {
  'iceServers': [
    // Public STUN servers
    {'urls': 'stun:stun.l.google.com:19302'},
    {'urls': 'stun:stun1.l.google.com:19302'},
    {'urls': 'stun:stun.cloudflare.com:3478'},

    // Optional: Self-hosted TURN server
    // {
    //   'urls': 'turn:your-turn-server.com:3478',
    //   'username': 'user',
    //   'credential': 'password'
    // },
  ],
  'iceTransportPolicy': 'all', // or 'relay' to force TURN
};
```

#### Step 23: LAN Prioritization

**`lib/core/networking/network_monitor.dart`**:

```dart
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkMonitor {
  // Detect network type
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

  // Check if peer is on same LAN
  bool isLocalIP(String ipAddress) {
    return ipAddress.startsWith('192.168.') ||
           ipAddress.startsWith('10.') ||
           ipAddress.startsWith('172.');
  }

  // Adjust codec bitrate based on network
  int getOptimalBitrate(NetworkType networkType) {
    switch (networkType) {
      case NetworkType.wifi:
        return 500; // kbps for video
      case NetworkType.mobile:
        return 200; // kbps for video
      default:
        return 100;
    }
  }
}

enum NetworkType { wifi, mobile, none }
```

#### Verification (Phase 7)

- [ ] P2P works across different networks
- [ ] LAN connections prioritized
- [ ] Media quality adjusts to network type
- [ ] TURN relay works as fallback

---

### Phase 8: Security Hardening & Privacy Features (Weeks 20-21)

**Goal**: Enhance privacy and implement perfect forward secrecy.

#### Step 25: Screenshot Prevention

**Android** (`android/app/src/main/kotlin/MainActivity.kt`):
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

**iOS** (Limited - blur on background):
```swift
// In AppDelegate.swift
NotificationCenter.default.addObserver(
    forName: UIApplication.willResignActiveNotification,
    object: nil,
    queue: .main
) { _ in
    // Blur or hide sensitive content
}
```

#### Step 26: Anti-Surveillance Guard (Process & App Detection Defense)

**Goal**: Detect any third-party app, spyware, screen recorder, accessibility-service snooper, or monitoring process that attempts to observe, capture, or inspect GungChat while it is running. Warn the user and forcefully disable/block the offending app.

**`lib/core/guard/surveillance_detector.dart`**:

```dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

/// Monitors the device for apps/processes that may be surveilling GungChat.
/// Checks run on a periodic timer while the app is in the foreground.
class SurveillanceDetector {
  static const _platform = MethodChannel('com.gungchat/guard');
  Timer? _pollTimer;
  final void Function(List<String> threats) onThreatsDetected;

  SurveillanceDetector({required this.onThreatsDetected});

  /// Known package-name patterns and process keywords to flag.
  static const List<String> _suspiciousPatterns = [
    // Screen recorders / screen capture
    'screenrecord', 'screencap', 'screen_record', 'scrcpy',
    // Accessibility-based snoopers
    'accessibilityservice', 'inputmethod',
    // Commercial spyware families
    'mspy', 'flexispy', 'cocospy', 'spyzie', 'hoverwatch',
    'eyezy', 'cerberus', 'xnspy',
    // Remote-access / debug bridges
    'teamviewer', 'anydesk', 'vnc', 'adb', 'frida', 'xposed',
    // Keyloggers / clipboard monitors
    'keylogger', 'clipboard_monitor',
    // Generic surveillance markers
    'spy', 'monitor', 'tracker', 'sniffer', 'logger',
  ];

  void startMonitoring({Duration interval = const Duration(seconds: 5)}) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(interval, (_) => _scan());
  }

  void stopMonitoring() => _pollTimer?.cancel();

  Future<void> _scan() async {
    try {
      // Platform channel calls native code to enumerate:
      //   Android – running services, installed packages, active accessibility services,
      //            MediaProjection sessions, overlay windows.
      //   iOS     – running background audio sessions, screen capture APIs,
      //            MDM profiles (limited by sandbox).
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
      // Platform channel unavailable – degrade gracefully
    }
  }
}
```

**`lib/core/guard/app_shield.dart`**:

```dart
import 'package:flutter/services.dart';

/// Attempts to force-stop or disable a detected surveillance app.
/// On Android this requires Device Admin or accessibility privileges;
/// on iOS the app can only warn and refuse to operate.
class AppShield {
  static const _platform = MethodChannel('com.gungchat/guard');

  /// Request the OS to force-stop the given package (Android only).
  /// Returns true if the platform confirmed the kill.
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

  /// Show a system-level warning dialog and, if the threat cannot be
  /// neutralised, lock GungChat itself to prevent data leakage.
  static Future<void> lockdownIfNeeded(List<String> unresolvedThreats) async {
    if (unresolvedThreats.isNotEmpty) {
      await _platform.invokeMethod('enterLockdown');
    }
  }
}
```

**Android native helper** (`android/app/src/main/kotlin/.../GuardMethodChannel.kt`):
```kotlin
// Registered in MainActivity via MethodChannel("com.gungchat/guard")
// getRunningApps  → ActivityManager.getRunningServices() +
//                   PackageManager.getInstalledApplications() +
//                   AccessibilityManager.getEnabledAccessibilityServiceList()
// forceStopApp    → Runtime.exec("am force-stop $pkg") (requires root or
//                   Device Owner) OR prompt user to Settings > Apps > Force Stop
// enterLockdown   → Finish all activities, clear task, wipe ephemeral keys
```

**Integration in `main.dart`**:
```dart
final detector = SurveillanceDetector(
  onThreatsDetected: (threats) {
    // 1. Show full-screen warning overlay listing detected threats
    // 2. Attempt AppShield.forceStopApp() for each threat
    // 3. If any threat persists after retry:
    //    - Display "Unsafe environment – GungChat locked" screen
    //    - Wipe ephemeral session keys from memory
    //    - Refuse to send/receive until threats are cleared
  },
);
detector.startMonitoring();
```

**Behaviour Summary**:
| Situation | Action |
|---|---|
| Suspicious app detected at launch | Block GungChat from opening; show warning with app name |
| Suspicious app starts while GungChat is running | Immediately show overlay warning; attempt force-stop |
| Force-stop succeeds | Dismiss warning; resume normal operation |
| Force-stop fails (no root / iOS) | Lock GungChat, wipe session keys, guide user to manually uninstall |
| Screen recording / MediaProjection active | Treat as critical threat; instant lockdown |
| Accessibility snooper enabled | Warn and refuse to display message content |

---

#### Step 27: Double Ratchet (Perfect Forward Secrecy)

**`lib/core/encryption/double_ratchet.dart`**:

```dart
// Implement Signal Protocol's Double Ratchet
// Reference: https://signal.org/docs/specifications/doubleratchet/

class DoubleRatchet {
  // Simplified implementation - use existing library in production

  // Root key and chain keys
  Uint8List rootKey;
  Uint8List sendChainKey;
  Uint8List receiveChainKey;

  DoubleRatchet(this.rootKey, this.sendChainKey, this.receiveChainKey);

  // Ratchet step on send
  Uint8List encryptMessage(Uint8List plaintext) {
    // Derive message key from chain key
    final messageKey = _deriveMessageKey(sendChainKey);
    sendChainKey = _deriveNextChainKey(sendChainKey);

    return CryptoService.encrypt(plaintext, messageKey);
  }

  // Ratchet step on receive
  Uint8List? decryptMessage(Uint8List ciphertext) {
    final messageKey = _deriveMessageKey(receiveChainKey);
    receiveChainKey = _deriveNextChainKey(receiveChainKey);

    return CryptoService.decrypt(ciphertext, messageKey);
  }

  Uint8List _deriveMessageKey(Uint8List chainKey) {
    // HMAC-based key derivation
    return Sodium.cryptoAuth(chainKey, Uint8List.fromList('MessageKey'.codeUnits));
  }

  Uint8List _deriveNextChainKey(Uint8List chainKey) {
    return Sodium.cryptoAuth(chainKey, Uint8List.fromList('ChainKey'.codeUnits));
  }
}
```

#### Verification (Phase 8)

- [ ] Screenshots blocked on Android
- [ ] Anti-surveillance guard detects known spy/screen-recorder apps
- [ ] Force-stop or lockdown triggers correctly on threat detection
- [ ] GungChat refuses to operate when unresolved threats remain
- [ ] Forward secrecy implemented
- [ ] No sensitive data in logs
- [ ] Memory leaks checked

---

### Phase 9: Polish & User Experience (Weeks 22-24)

**Goal**: Improve usability and localization.

#### Step 28: Dark Mode & Localization

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

#### Step 29: Settings Screen

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

#### Verification (Phase 9)

- [ ] Dark mode toggles correctly
- [ ] App works in English and Chinese
- [ ] Settings persist across restarts
- [ ] Smooth animations

---

### Phase 9.5: Enhanced UX Features (Weeks 24-26) — *Inspired by lets-chat*

**Goal**: Add chat UX polish features adapted from the lets-chat open source project, re-engineered for P2P encrypted architecture.

> **Source**: Features below are inspired by analysis of [sdelements/lets-chat](https://github.com/sdelements/lets-chat), a self-hosted team chat app. All implementations are redesigned for GungChat's serverless, E2E-encrypted, P2P model.

#### Step 30A: Typing Indicators

Real-time "typing..." status sent over the encrypted WebRTC data channel.

**`lib/features/chat/typing_indicator_service.dart`**:

```dart
import 'dart:async';

/// Sends/receives typing status over the encrypted P2P data channel.
/// Typing signals are ephemeral metadata — never persisted or logged.
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

  /// Called on every keystroke in the message input.
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

  /// Called when a typing status message arrives from the peer.
  void onRemoteTypingReceived(bool peerIsTyping) {
    onPeerTypingChanged(peerIsTyping);
  }

  void dispose() {
    _debounceTimer?.cancel();
  }
}
```

#### Step 30B: Message Formatting Pipeline

Client-side formatter that processes plaintext messages into rich display — URL linkification, inline image previews, code block detection, and emoji rendering. Inspired by lets-chat's `media/js/util/message.js` formatter chain.

**`lib/formatters/message_formatter.dart`**:

```dart
/// Processes raw message text into structured display segments.
/// All formatting is client-side only — the encrypted payload is always plaintext.
class MessageFormatter {
  /// Detect and segment message content into typed parts.
  static List<MessageSegment> format(String rawText) {
    final segments = <MessageSegment>[];

    // 1. Code block detection (triple backtick or multiline paste)
    if (rawText.contains('```') || _isMultilinePaste(rawText)) {
      segments.add(MessageSegment(type: SegmentType.codeBlock, content: rawText));
      return segments;
    }

    // 2. URL detection and linkification
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

#### Step 30C: Read Receipts (Privacy-Respecting)

Encrypted delivery and read confirmations sent over the data channel. **Opt-in only** — disabled by default to respect privacy. Lets-chat lacked this feature entirely; GungChat adds it with privacy controls.

```dart
enum ReceiptType { delivered, read }

class ReadReceiptService {
  bool enabled; // User-configurable, off by default

  ReadReceiptService({this.enabled = false});

  /// Generate an encrypted receipt to send back to the peer.
  Map<String, dynamic> createReceipt(String messageId, ReceiptType type) {
    return {
      'type': 'receipt',
      'messageId': messageId,
      'receipt': type.name,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Process incoming receipt from peer and update message status.
  void handleReceipt(Map<String, dynamic> data, Function(String, ReceiptType) onReceiptReceived) {
    if (!enabled) return;
    final messageId = data['messageId'] as String;
    final type = ReceiptType.values.byName(data['receipt']);
    onReceiptReceived(messageId, type);
  }
}
```

#### Step 30D: Presence Status with Privacy Controls

Online/offline/away indicators transmitted over the P2P channel. Unlike lets-chat's server-tracked presence, GungChat's presence is direct peer-to-peer with an option to appear invisible.

```dart
enum PresenceStatus { online, away, offline, invisible }

class PresenceService {
  PresenceStatus _currentStatus = PresenceStatus.online;
  bool showPresence; // User toggle — if false, always appear offline to peers

  PresenceService({this.showPresence = true});

  PresenceStatus get currentStatus => _currentStatus;

  /// Broadcast presence change to connected peer.
  Map<String, dynamic> setStatus(PresenceStatus status) {
    _currentStatus = status;
    return {
      'type': 'presence',
      'status': showPresence ? status.name : PresenceStatus.offline.name,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Auto-detect away status based on app lifecycle.
  PresenceStatus detectFromAppState(bool isInForeground) {
    if (!isInForeground && _currentStatus == PresenceStatus.online) {
      return PresenceStatus.away;
    }
    return _currentStatus;
  }
}
```

#### Step 30E: Notification Badges & Push Alerts

Unread message counters and system notifications, inspired by lets-chat's tab badge/favicon/desktop notification system. Adapted for mobile with Flutter local notifications.

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

  /// Show a notification for an incoming message while app is backgrounded.
  Future<void> showMessageNotification({
    required String contactName,
    required String preview, // Truncated or "Encrypted message" if privacy mode
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

#### Step 30F: File Transfer Validation & Preview

MIME type allowlisting and file size limits before encrypted transmission over the data channel. Adapts lets-chat's server-side Multer validation for client-side P2P use.

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

  /// Validate file before encryption and transfer.
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

#### Step 30G: Local Encrypted Message Search

Full-text search over the optional encrypted local message cache. Lets-chat uses MongoDB text indexes on the server; GungChat implements this client-side using SQLite FTS5 over decrypted messages.

```dart
class MessageSearchService {
  final MessageDatabase _db;

  MessageSearchService(this._db);

  /// Search locally cached messages by keyword.
  /// Only searches decrypted plaintext in the encrypted local store.
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

#### Step 30H: Connection Resilience & Auto-Reconnect

Automatic reconnection with WebRTC session recovery after network interruptions. Inspired by lets-chat's socket reconnect + room rejoin pattern, adapted for P2P data channels.

```dart
class ConnectionResilience {
  final WebRTCManager _webrtc;
  final NetworkMonitor _networkMonitor;
  int _retryCount = 0;
  static const int _maxRetries = 10;
  static const Duration _baseDelay = Duration(seconds: 2);

  ConnectionResilience(this._webrtc, this._networkMonitor);

  /// Monitor connection state and trigger reconnection on failure.
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
      final delay = _baseDelay * _retryCount; // Exponential backoff
      await Future.delayed(delay);

      final networkType = await _networkMonitor.getNetworkType();
      if (networkType == NetworkType.none) continue;

      try {
        await _webrtc.reconnect(peerIp);
        _retryCount = 0;
        onReconnected();
        return;
      } catch (_) {
        // Continue retry loop
      }
    }
    onPermanentFailure();
  }
}
```

#### Step 30I: Extended Localization

Expand i18n support from 2 to 10+ languages. Lets-chat ships with 17 locales; GungChat adopts the most widely-used ones.

**Additional locale files** (add to `lib/l10n/`):

**`app_ja.arb`** (Japanese):
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

**`app_ko.arb`** (Korean):
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

**`app_ru.arb`** (Russian):
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

#### Step 30J: Message Grouping UX

Consecutive messages from the same sender within a short time window are visually grouped (no repeated avatar/name). Adapted from lets-chat's "fragment" rendering pattern.

```dart
/// Determines if a message should render as a "fragment" (grouped with previous).
class MessageGroupingHelper {
  static const Duration _groupingWindow = Duration(minutes: 2);

  /// Returns true if this message should be rendered without header (name/avatar).
  static bool isFragment(Message current, Message? previous) {
    if (previous == null) return false;
    if (current.senderId != previous.senderId) return false;
    return current.timestamp.difference(previous.timestamp) <= _groupingWindow;
  }
}
```

#### Verification (Phase 9.5)

- [ ] Typing indicator appears within 500ms of peer keystroke
- [ ] URLs in messages are clickable; image URLs render inline preview
- [ ] Code blocks (triple backtick or multiline paste) render with monospace styling
- [ ] Read receipts toggle works; receipts encrypted and not sent when disabled
- [ ] Presence status reflects app lifecycle (foreground=online, background=away)
- [ ] Invisible mode hides presence from peer
- [ ] System notification shown when message arrives while app is backgrounded
- [ ] App icon badge shows unread count
- [ ] File validation rejects oversized and disallowed MIME types before transfer
- [ ] Local search returns results from encrypted message cache
- [ ] Auto-reconnect succeeds after WiFi toggle within 30 seconds
- [ ] Consecutive same-sender messages render as grouped fragments
- [ ] App displays correctly in all 10+ supported languages

---

### Phase 9.6: Advanced Messaging & Security Features (Weeks 26-29) — *Inspired by Rocket.Chat*

**Goal**: Add rich messaging interactions, voice messages, app security, and power-user features adapted from Rocket.Chat's mature feature set, re-engineered for P2P encrypted architecture.

> **Source**: Features below are inspired by analysis of [RocketChat/Rocket.Chat](https://github.com/RocketChat/Rocket.Chat) (MIT License), a comprehensive open-source communications platform. All implementations are redesigned for GungChat's serverless, E2E-encrypted, P2P model.

#### Step 35A: Message Reactions (Emoji Reactions)

Per-message emoji reactions sent as encrypted metadata updates over the data channel. Inspired by Rocket.Chat's `setReaction.ts` toggle pattern.

**`lib/features/chat/reaction_service.dart`**:

```dart
/// Manages emoji reactions on messages.
/// Reactions are synced over the encrypted P2P data channel.
/// Each reaction is a lightweight metadata update, not a new message.
class ReactionService {
  /// Toggle a reaction on a message. If user already reacted with this
  /// emoji, remove it; otherwise add it.
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

#### Step 35B: Message Starring (Personal Bookmarks)

Local-only bookmarks for important messages — never transmitted to the peer. Inspired by Rocket.Chat's star vs. pin distinction.

```dart
/// Starred messages are stored locally in encrypted SQLite.
/// Stars are personal — the peer never knows which messages you bookmarked.
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

#### Step 35C: Message Edit & Delete with Privacy Semantics

Edit or delete sent messages with configurable behavior: soft-delete (tombstone showing "message deleted") or hard-delete (complete removal). Inspired by Rocket.Chat's `updateMessage.ts` and `deleteMessage.ts` lifecycle.

```dart
enum DeleteMode { tombstone, hardDelete }

class MessageEditService {
  /// Edit a message and notify peer over encrypted data channel.
  /// Original content is discarded (no edit history for privacy).
  Map<String, dynamic> editMessage(String messageId, String newContent) {
    return {
      'type': 'messageEdit',
      'messageId': messageId,
      'content': newContent,
      'editedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Delete a message with privacy-aware semantics.
  /// Tombstone mode: peer sees "This message was deleted"
  /// Hard delete mode: message removed from both sides entirely
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

#### Step 35D: Voice Messages (Audio Recording & Playback)

Record, encrypt, and send audio messages over the P2P data channel with in-chat waveform playback. Inspired by Rocket.Chat's audio message support.

```dart
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';

class VoiceMessageService {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  static const int maxDurationSeconds = 120; // 2 minute max

  /// Start recording audio with Opus codec.
  Future<void> startRecording(String tempPath) async {
    if (await _recorder.hasPermission()) {
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.opus,
          bitRate: 32000, // 32 kbps for compact voice
          sampleRate: 16000,
        ),
        path: tempPath,
      );
    }
  }

  /// Stop recording and return the audio file path.
  Future<String?> stopRecording() async {
    return await _recorder.stop();
  }

  /// Play a received voice message from decrypted bytes.
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

#### Step 35E: Reply/Quote Messages

Reply to a specific message with quoted context. The reply includes a reference to the original message ID and a preview snippet. Inspired by Rocket.Chat's threaded reply system, simplified for 1:1 P2P.

```dart
class ReplyService {
  /// Create a reply message that references an original message.
  Map<String, dynamic> createReply({
    required String originalMessageId,
    required String originalPreview, // Truncated to 100 chars
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

**Message model update** — add to `lib/models/message.dart`:
```dart
// Add these fields to the Message class:
final String? replyToMessageId;   // ID of message being replied to
final String? replyToPreview;     // Truncated preview of original message
final Map<String, List<String>>? reactions; // emoji -> list of userIds
final bool isEdited;              // Whether message has been edited
final bool isDeleted;             // Tombstone flag for soft-deleted messages
```

#### Step 35F: URL Link Preview (Client-Side)

Fetch URL metadata (title, description, image) client-side with privacy controls. **Opt-in only** — disabled by default to prevent IP leakage through URL fetching. Inspired by Rocket.Chat's oEmbed pipeline.

```dart
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;

class LinkPreviewService {
  bool enabled; // User toggle — off by default for privacy

  LinkPreviewService({this.enabled = false});

  /// Fetch metadata from a URL. Only called if user has opted in.
  /// Uses a timeout to prevent hanging on slow servers.
  Future<LinkPreview?> fetchPreview(String url) async {
    if (!enabled) return null;

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'GungChat/1.0'}, // Minimal fingerprint
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

#### Step 35G: Spoiler Messages

Hidden message content revealed on tap, using `||spoiler text||` syntax. Inspired by Rocket.Chat's accessible spoiler rendering in `gazzodown`.

```dart
/// Parses ||spoiler|| syntax and renders as blurred/hidden text.
/// Tap to reveal. Accessible — screen readers announce "spoiler, tap to reveal".
class SpoilerRenderer {
  static final RegExp _spoilerPattern = RegExp(r'\|\|(.+?)\|\|');

  /// Check if message contains spoiler segments.
  static bool hasSpoilers(String text) => _spoilerPattern.hasMatch(text);

  /// Split text into normal and spoiler segments.
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

#### Step 35H: Custom Status Text

Free-text status message (e.g., "In a meeting", "Do not disturb") shared with the peer alongside presence status. Inspired by Rocket.Chat's `setUserStatus` system.

```dart
class CustomStatusService {
  String _statusText = '';
  final int maxLength = 80;

  /// Set custom status text and broadcast to peer.
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

#### Step 35I: Slash Commands (Local Command Framework)

Client-side command system for power users. Commands execute locally — nothing sent to the peer. Inspired by Rocket.Chat's slash command registry.

```dart
typedef CommandHandler = Future<String?> Function(List<String> args);

class SlashCommandRegistry {
  final Map<String, _Command> _commands = {};

  SlashCommandRegistry() {
    // Register built-in commands
    register('clear', 'Clear chat history from view', _clearChat);
    register('export', 'Export chat to encrypted file', _exportChat);
    register('status', 'Set your status text', _setStatus);
    register('destroy', 'Wipe all local data and keys', _destroyData);
    register('help', 'Show available commands', _showHelp);
  }

  void register(String name, String description, CommandHandler handler) {
    _commands[name] = _Command(name: name, description: description, handler: handler);
  }

  /// Parse and execute a slash command. Returns null if not a command.
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

#### Step 35J: Chat Data Export (Encrypted Local Export)

Export conversation history as an encrypted ZIP archive. Lets users maintain personal records while preserving privacy. Inspired by Rocket.Chat's GDPR-style data export.

```dart
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:share_plus/share_plus.dart';

class ChatExportService {
  final MessageDatabase _db;
  final CryptoService _crypto;

  ChatExportService(this._db, this._crypto);

  /// Export all messages with a contact as an encrypted JSON archive.
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

    // Compress
    final archive = Archive();
    archive.addFile(ArchiveFile('chat_export.json', jsonBytes.length, jsonBytes));
    final zipBytes = ZipEncoder().encode(archive);

    // Save to temp and share
    final tempDir = await getTemporaryDirectory();
    final exportFile = File(
      '${tempDir.path}/gungchat_export_${contactName}_${DateTime.now().millisecondsSinceEpoch}.zip',
    );
    await exportFile.writeAsBytes(zipBytes!);
    return exportFile;
  }

  /// Share the exported file via system share sheet.
  Future<void> shareExport(File exportFile) async {
    await Share.shareXFiles([XFile(exportFile.path)], text: 'GungChat Export');
  }
}
```

#### Step 35K: Contact Blocking

Block a peer from establishing new P2P connections. Blocked contacts are stored locally and checked during the WebRTC signaling handshake.

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

#### Step 35L: App Lock (Biometric / PIN Authentication)

Secure app access with biometric authentication (fingerprint/face) or PIN code. Required on launch and when returning from background after configurable timeout.

```dart
import 'package:local_auth/local_auth.dart';

class AppLockService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool enabled = false;
  int lockTimeoutSeconds = 60; // Re-lock after 60s in background
  DateTime? _lastAuthenticated;

  /// Check if biometric authentication is available.
  Future<bool> isBiometricAvailable() async {
    final canCheck = await _localAuth.canCheckBiometrics;
    final isSupported = await _localAuth.isDeviceSupported();
    return canCheck && isSupported;
  }

  /// Authenticate using biometrics or device PIN.
  Future<bool> authenticate() async {
    if (!enabled) return true;

    // Skip if recently authenticated
    if (_lastAuthenticated != null &&
        DateTime.now().difference(_lastAuthenticated!).inSeconds < lockTimeoutSeconds) {
      return true;
    }

    try {
      final success = await _localAuth.authenticate(
        localizedReason: 'Unlock GungChat',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allow device PIN as fallback
        ),
      );
      if (success) _lastAuthenticated = DateTime.now();
      return success;
    } catch (_) {
      return false;
    }
  }

  /// Called when app returns to foreground — check if re-auth needed.
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

#### Verification (Phase 9.6)

- [ ] Emoji reactions toggle on/off per message; reaction counts display correctly
- [ ] Starred messages persist locally across app restarts; peer cannot see stars
- [ ] Edited messages show "edited" indicator; peer receives updated content
- [ ] Deleted messages show tombstone or are fully removed based on mode setting
- [ ] Voice messages record up to 2 minutes; playback with progress indicator
- [ ] Reply/quote shows original message preview above the reply
- [ ] Link previews fetch metadata only when user has opted in
- [ ] Spoiler text is hidden by default; tap reveals content
- [ ] Custom status text visible to peer alongside presence indicator
- [ ] Slash commands execute locally; /help lists all available commands
- [ ] Chat export produces a valid ZIP file; share sheet opens
- [ ] Blocked contacts cannot establish WebRTC connections
- [ ] App lock prompts biometric/PIN on launch and after background timeout
- [ ] All new features work with E2E encryption enabled

---

### Phase 9.7: UX Polish & Organization Features (Weeks 29-31) — *Inspired by Chatwoot*

**Goal**: Add conversation organization, quick-reply productivity tools, media browsing, theming, keyboard shortcuts, and accessibility features adapted from Chatwoot's mature UX patterns, re-engineered for P2P encrypted architecture.

> **Source**: Features below are inspired by analysis of [chatwoot/chatwoot](https://github.com/chatwoot/chatwoot) (MIT License), a modern open-source customer support platform. All implementations are redesigned for GungChat's serverless, E2E-encrypted, P2P model.

#### Step 36A: Quick Reply Templates (Canned Responses)

Saved reusable message snippets with shortcode search. Type a shortcode prefix (e.g., `/hi`) and select from filtered templates. Inspired by Chatwoot's `CannedResponse` model with ranked search.

**`lib/templates/quick_reply_service.dart`**:

```dart
/// Local-only quick reply templates stored in encrypted SQLite.
/// Templates are personal and never transmitted to the peer.
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

  /// Search templates by shortcode prefix, ranked by usage frequency.
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

  /// Use a template and increment its usage counter.
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

#### Step 36B: Conversation Labels / Tags

Color-coded tags for organizing peer conversations. Labels are local-only and can be used to filter the contact list. Inspired by Chatwoot's label model with color and visibility.

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

  /// Assign a label to a conversation (by contact ID).
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

  /// Get all conversations with a specific label.
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

#### Step 36C: Contact Notes (Private Annotations)

Private notes attached to contacts — never transmitted to the peer. Useful for remembering context about a contact. Inspired by Chatwoot's dedicated `Note` model.

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

#### Step 36D: Multi-Attachment Messages & Location/Contact Sharing

Support multiple attachments per message (up to 10), plus special attachment types for location sharing and contact cards. Inspired by Chatwoot's attachment taxonomy.

**Message model additions** — add to `lib/models/message.dart`:
```dart
// Extend MessageType enum:
enum MessageType { text, image, audio, video, system, location, contactCard, multiAttachment }

// Add to Message class:
final List<Attachment>? attachments; // Multiple attachments per message

class Attachment {
  final String id;
  final AttachmentType type;
  final String filePath;    // Local encrypted path
  final String? mimeType;
  final int? sizeBytes;
  final Map<String, dynamic>? metadata; // Location coords, contact info, etc.

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

**Location sharing**:
```dart
import 'package:geolocator/geolocator.dart';

class LocationSharingService {
  /// Get current location and package as attachment metadata.
  Future<Map<String, dynamic>?> getCurrentLocation() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final requested = await Geolocator.requestPermission();
      if (requested == LocationPermission.denied) return null;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium, // Balance privacy vs accuracy
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

#### Step 36E: Shared Media Gallery

Browse all media (images, videos, documents, voice messages) shared in a conversation, with grid/list view toggle and full-screen image viewer. Inspired by Chatwoot's per-conversation attachment index.

```dart
import 'package:photo_view/photo_view.dart';

class MediaGalleryService {
  final MessageDatabase _db;
  MediaGalleryService(this._db);

  /// Fetch all media attachments for a conversation, categorized by type.
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

#### Step 36F: Theme System (Light / Dark / Auto)

Persisted appearance mode with system-auto detection. Inspired by Chatwoot's light/dark/auto appearance composable.

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

  /// Cycle through themes: auto -> light -> dark -> auto
  Future<void> cycleTheme() async {
    final next = AppThemeMode.values[
      (_mode.index + 1) % AppThemeMode.values.length
    ];
    await setTheme(next);
  }
}
```

#### Step 36G: Keyboard Shortcuts

Power-user keyboard shortcuts for quick navigation and actions. Primarily useful when GungChat is run on tablets or desktop platforms via Flutter. Inspired by Chatwoot's hotkey composables.

```dart
import 'package:flutter/services.dart';

class KeyboardShortcutService {
  final Map<ShortcutActivator, VoidCallback> _shortcuts = {};

  KeyboardShortcutService() {
    // Register default shortcuts
    _register(LogicalKeyboardKey.keyN, control: true, action: () {});
    // Ctrl+N: New connection
    _register(LogicalKeyboardKey.keyK, control: true, action: () {});
    // Ctrl+K: Quick search / command palette
    _register(LogicalKeyboardKey.keyE, control: true, action: () {});
    // Ctrl+E: Toggle encryption details
    _register(LogicalKeyboardKey.keyM, control: true, shift: true, action: () {});
    // Ctrl+Shift+M: Mute current conversation
    _register(LogicalKeyboardKey.keyD, control: true, shift: true, action: () {});
    // Ctrl+Shift+D: Toggle dark mode
    _register(LogicalKeyboardKey.slash, control: false, action: () {});
    // /: Focus message input (slash command mode)
  }

  void _register(
    LogicalKeyboardKey key, {
    bool control = false,
    bool shift = false,
    required VoidCallback action,
  }) {
    _shortcuts[SingleActivator(key, control: control, shift: shift)] = action;
  }

  /// Bind a specific shortcut to an action.
  void bind(String shortcutId, VoidCallback action) {
    // Allow runtime rebinding of shortcuts
  }

  Map<ShortcutActivator, VoidCallback> get shortcuts => Map.unmodifiable(_shortcuts);
}
```

#### Step 36H: Conversation Mute & Snooze

Temporarily silence notifications for a specific conversation. Mute indefinitely or snooze until a specific time. Inspired by Chatwoot's conversation muting and snoozed_until timestamp.

```dart
class ConversationMuteService {
  final MessageDatabase _db;
  ConversationMuteService(this._db);

  /// Mute a conversation indefinitely.
  Future<void> mute(String contactId) async {
    final db = await _db.database;
    await db.insert('conversation_settings', {
      'contactId': contactId,
      'muted': 1,
      'snoozedUntil': null,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Snooze notifications until a specific time.
  Future<void> snoozeUntil(String contactId, DateTime until) async {
    final db = await _db.database;
    await db.insert('conversation_settings', {
      'contactId': contactId,
      'muted': 0,
      'snoozedUntil': until.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Unmute / cancel snooze.
  Future<void> unmute(String contactId) async {
    final db = await _db.database;
    await db.delete('conversation_settings',
      where: 'contactId = ?', whereArgs: [contactId]);
  }

  /// Check if a conversation should receive notifications right now.
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

#### Step 36I: Granular Notification Preferences

Per-event-type notification controls: separately enable/disable notifications for messages, calls, presence changes, and connection requests. Inspired by Chatwoot's `NotificationSetting` per-event toggle model.

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

#### Step 36J: Accessibility (A11y) Guidelines

Accessibility-first design patterns applied across all GungChat screens. Inspired by Chatwoot's ARIA labels, switch semantics, and keyboard navigation.

**Implementation guidelines** (apply across all UI widgets):

```dart
/// Accessibility guidelines for all GungChat widgets:
///
/// 1. Semantics: Wrap interactive elements with Semantics() widget
///    - Include label, hint, and button/toggle/textField roles
///    - Example: Semantics(label: 'Send message', button: true, child: ...)
///
/// 2. Large touch targets: Minimum 48x48dp for all tappable elements
///
/// 3. Screen reader announcements for state changes:
///    SemanticsService.announce('Message sent', TextDirection.ltr);
///
/// 4. Focus management:
///    - Auto-focus message input on chat open
///    - Return focus after dialogs close
///    - FocusTraversalGroup for logical tab order
///
/// 5. High contrast support:
///    - Use MediaQuery.highContrast to detect and adapt
///    - Minimum 4.5:1 contrast ratio for text
///    - 3:1 for large text and UI components
///
/// 6. Motion reduction:
///    - Respect MediaQuery.disableAnimations
///    - Provide reduced-motion alternatives for all animations
///
/// 7. Text scaling:
///    - Support system font size up to 2.0x without layout overflow
///    - Test with MediaQuery.textScaleFactor set to 2.0

class A11yHelper {
  /// Check if reduced motion is preferred.
  static bool prefersReducedMotion(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }

  /// Check if high contrast is active.
  static bool isHighContrast(BuildContext context) {
    return MediaQuery.of(context).highContrast;
  }

  /// Announce a state change to screen readers.
  static void announce(String message) {
    SemanticsService.announce(message, TextDirection.ltr);
  }
}
```

#### Verification (Phase 9.7)

- [ ] Quick reply templates: create, search by shortcode prefix, use, and delete
- [ ] Conversation labels: create with color, assign/remove from conversations, filter by label
- [ ] Contact notes: add, edit, delete; notes never visible to peer
- [ ] Multi-attachment messages: send up to 10 files in one message
- [ ] Location sharing: current coordinates sent as encrypted attachment
- [ ] Contact card sharing: share a contact's public key + name
- [ ] Media gallery: browse images/videos/audio/documents per conversation
- [ ] Full-screen image viewer with pinch-to-zoom
- [ ] Theme toggles correctly between light/dark/auto modes
- [ ] Keyboard shortcuts functional on tablet/desktop (Ctrl+K search, Ctrl+Shift+D dark mode)
- [ ] Conversation mute stops notifications; snooze resumes at specified time
- [ ] Notification preferences: toggle per event type persists across restarts
- [ ] Screen reader announces message sent/received, connection status changes
- [ ] All touch targets meet 48x48dp minimum
- [ ] Font scaling to 2.0x does not break layout

---

### Phase 10: Testing & Deployment (Weeks 32-33)

**Goal**: Comprehensive testing and open source release.

#### Step 31: Testing

**Unit tests** (`test/crypto_service_test.dart`):
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

**Integration tests** (`integration_test/app_test.dart`):
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('send and receive text message', (WidgetTester tester) async {
    // TODO: Test full message flow
  });
}
```

#### Step 32: Build Release

**Android**:
```bash
flutter build apk --release --obfuscate --split-debug-info=build/debug-info
flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info
```

**iOS**:
```bash
flutter build ios --release
```

#### Step 33: Documentation

Create:
- **README.md** - Project overview, features, installation
- **CONTRIBUTING.md** - How to contribute (coding standards, PR process)
- **USER_GUIDE.md** - How to use the app
- **ARCHITECTURE.md** - Technical architecture documentation

#### Step 34: Open Source Release

1. Choose license (GPLv3 recommended for privacy-focused app)
2. Publish to GitHub/GitLab
3. Submit to F-Droid (reproducible build)
4. Optional: Google Play / App Store (requires accounts)

#### Verification (Phase 10)

- [ ] All tests passing
- [ ] Release builds run on test devices
- [ ] Documentation complete
- [ ] No critical bugs

---

## Key Architectural Decisions

### 1. Phone Number Discovery Without Server

**Challenge**: Traditional phone number lookup requires a central directory.

**Solution**:
- **Primary**: QR code exchange (fully serverless, privacy-preserving)
- **Secondary**: NFC/Bluetooth contact exchange for nearby users
- **Future**: DHT (Distributed Hash Table) for decentralized contact discovery

**Trade-off**: Less convenient than WhatsApp-style phone sync, but maintains "no server" principle.

### 2. STUN vs. TURN

- **STUN**: Free public servers for most connections (90% success rate)
- **TURN**: Optional self-hosted relay for symmetric NAT (5-10% of users)

**Decision**: Use public STUN servers by default, document TURN setup for advanced users.

### 3. Message Persistence

**Spec**: "阅后即焚" (burn after reading) by default

**Implementation**:
- Messages ephemeral by default
- Optional encrypted local storage (user-configurable: none, 1 hour, 1 day, 1 week)
- Auto-wipe on app uninstall

### 4. iOS Background Limitations

**Problem**: iOS kills background apps, breaking incoming calls.

**Options**:
- A) Use VoIP push notifications (requires minimal APNs relay server)
- B) Accept limitation (calls only work in foreground)

**Recommendation**: Option A for practical usability (minimal server violation)

---

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|-----------|
| **NAT Traversal Failure** | P2P connection fails | Implement TURN relay, aggressive ICE |
| **iOS Background Restrictions** | Missed calls | Use VoIP push or document limitation |
| **Contact Discovery UX** | QR codes less convenient | Smooth QR scanning, NFC support |
| **Video Bandwidth** | High mobile data usage | Adaptive bitrate, audio fallback |
| **Encryption Vulnerabilities** | Security breach | Use audited libraries, security review |
| **Low-end Device Performance** | App crashes/lag | Optimize Flutter build, test on budget devices |

---

## Success Metrics (MVP)

### Functional Requirements

- ✅ Two users connect via IP address or LAN
- ✅ Text messages encrypted and delivered < 1 second
- ✅ Images < 5 MB transfer successfully
- ✅ Voice calls with clear audio on WiFi
- ✅ Video calls at 320p with < 500 kbps bandwidth
- ✅ Messages self-destruct per configuration
- ✅ No plaintext data stored on device
- ✅ Typing indicators appear within 500ms
- ✅ Read receipts delivered when enabled (opt-in)
- ✅ Presence status reflects real-time connection state
- ✅ File transfers validated (MIME type + size) before send
- ✅ Local encrypted search returns results in < 200ms
- ✅ Auto-reconnect recovers session within 30 seconds
- ✅ System notifications and badge counters functional
- ✅ Emoji reactions toggle correctly on messages
- ✅ Voice messages record, encrypt, send, and play back
- ✅ Message edit/delete propagates to peer with correct semantics
- ✅ Reply/quote displays original message context
- ✅ App lock prevents unauthorized access via biometric/PIN
- ✅ Contact blocking prevents connection establishment
- ✅ Chat data export produces valid encrypted archive
- ✅ Quick reply templates searchable by shortcode
- ✅ Conversation labels and media gallery functional
- ✅ Theme system (light/dark/auto) persists preference
- ✅ Conversation mute/snooze suppresses notifications correctly
- ✅ Screen reader compatibility verified on Android TalkBack and iOS VoiceOver

### Platform Support

- ✅ Android 9+ (API level 28+)
- ✅ iOS 13+ (iPhone 6s and newer)

### Localization

- ✅ 10+ languages: English, Chinese (Simplified & Traditional), Japanese, Korean, Russian, Spanish, French, German, Portuguese

### Open Source

- ✅ Source code published with GPL/MIT/Apache license
- ✅ F-Droid reproducible build available

---

## Next Steps

### Immediate Actions (This Week)

1. **Initialize Flutter project**
   ```bash
   flutter create gungchat
   cd gungchat
   ```

2. **Set up Git repository**
   ```bash
   git init
   git remote add origin https://github.com/yourusername/gungchat.git
   ```

3. **Add dependencies to `pubspec.yaml`**
   - Copy dependencies from Phase 1, Step 3

4. **Create folder structure**
   - Create `lib/core/`, `lib/features/`, `lib/models/` directories

5. **Implement basic encryption test**
   - Create `lib/core/encryption/crypto_service.dart`
   - Write unit test to verify encryption works

### Week 1-3 Goals (Phase 1)

- [ ] Flutter project initialized and building
- [ ] Encryption layer implemented and tested
- [ ] Basic WebRTC connection established between two test devices
- [ ] Simple UI showing connection status

---

## Open Questions

1. **iOS Background Calls**: Accept minimal APNs relay server or document foreground-only limitation?
   - **Recommendation**: Use VoIP push for usability

2. **App Distribution**: F-Droid only or also Google Play / App Store?
   - **Recommendation**: Start with F-Droid, add commercial stores if demand exists

3. **TURN Server**: Include self-hosting guide or skip for MVP?
   - **Recommendation**: Document in advanced setup guide, not required for MVP

4. **Message Retention Default**: Always ephemeral or optional persistence?
   - **Recommendation**: Ephemeral by default, allow 1-week max retention in settings

---

## Appendix

### Useful Resources

- **Flutter WebRTC Plugin**: https://pub.dev/packages/flutter_webrtc
- **libsodium Documentation**: https://libsodium.gitbook.io/
- **WebRTC Samples**: https://webrtc.github.io/samples/
- **Signal Protocol**: https://signal.org/docs/specifications/doubleratchet/
- **mDNS Service Discovery**: https://pub.dev/packages/multicast_dns
- **F-Droid Build Process**: https://f-droid.org/docs/

### Estimated Effort

- **Solo Developer (Full-time)**: ~6-8 months for MVP
- **Team of 2-3 (Part-time)**: ~9-12 months for MVP
- **Estimated Team (Full-time)**: ~3-4 months for MVP

### Features Inspired by lets-chat (Open Source Attribution)

The following GungChat features were identified and adapted from analysis of [sdelements/lets-chat](https://github.com/sdelements/lets-chat) (MIT License), a self-hosted team chat app. All implementations are **redesigned from scratch** for GungChat's serverless, E2E-encrypted, P2P architecture:

| lets-chat Feature | GungChat Adaptation | Key Difference |
|---|---|---|
| Typing indicators (socket.io) | Typing over encrypted WebRTC data channel | No server relay; peer-to-peer only |
| Message formatting pipeline | Client-side URL/image/code block formatter | All formatting on decrypted plaintext client-side |
| Presence tracking (server-mediated) | P2P presence with invisible mode | Privacy-first: opt-in, no server tracking |
| Desktop notifications + tab badges | Mobile push notifications + app badges | Native mobile notifications via Flutter |
| File upload with MIME validation | Client-side validation before encrypted transfer | No server upload; direct P2P with encryption |
| Transcript search (MongoDB text index) | Local encrypted SQLite FTS search | Searches decrypted cache only; no server index |
| Socket reconnect + room rejoin | WebRTC auto-reconnect with exponential backoff | Session recovery over P2P, not server sessions |
| Message fragments (same-sender grouping) | Message grouping within 2-min window | Same UX concept, different rendering stack |
| 17-locale i18n (server-side) | 10+ locale Flutter ARB files | Client-only; no server-side locale detection |
| Emote/emoji YAML packs | Emoji picker + inline emoji rendering | Standard Unicode emoji instead of custom packs |
| Read receipts | **New** (not in lets-chat) — opt-in encrypted receipts | Privacy-respecting; lets-chat lacked this entirely |
| OTR message pass-through | Not needed — all messages are E2E encrypted by default | GungChat is encrypted-first by design |
| Auth throttling / rate limiting | Connection attempt rate limiting | Adapted for P2P connection requests |

### Features Inspired by Rocket.Chat (Open Source Attribution)

The following GungChat features were identified and adapted from analysis of [RocketChat/Rocket.Chat](https://github.com/RocketChat/Rocket.Chat) (MIT License), a comprehensive open-source communications platform. All implementations are **redesigned from scratch** for GungChat's serverless, E2E-encrypted, P2P architecture:

| Rocket.Chat Feature | GungChat Adaptation | Key Difference |
|---|---|---|
| Emoji reactions (`setReaction.ts`) | Reaction toggles over encrypted data channel | No server DB; reactions are P2P metadata updates |
| Star & pin messages | Local-only starred bookmarks | Stars never leave device; no server-side pin |
| Message edit/delete with history | Edit/delete with privacy-first tombstone semantics | No edit history retained (privacy); hard-delete option |
| Audio messages (file upload) | Voice recording with Opus codec + encrypted P2P transfer | Direct encrypted transfer; no server storage |
| Threaded replies | Reply-to-message with quoted preview | Simplified for 1:1; no thread branching |
| oEmbed URL preview pipeline | Client-side OG metadata fetch (opt-in) | Disabled by default to prevent IP leakage |
| Spoiler rendering (`gazzodown`) | `\|\|spoiler\|\|` syntax with tap-to-reveal | Accessibility-first with screen reader support |
| Custom user status text | Status text over P2P channel alongside presence | Peer-to-peer only; no server directory |
| Slash command framework | Local-only commands (/clear, /export, /help, /destroy) | Commands execute client-side; nothing sent to peer |
| GDPR data export | Encrypted ZIP export via share sheet | Local-only; no server request needed |
| Moderation/blocking APIs | Contact blocking at WebRTC handshake level | Enforced locally before connection established |
| N/A (enterprise feature) | Biometric/PIN app lock | **New** — not in Rocket.Chat open source core |
| E2EE key lifecycle APIs | Adapted for double-ratchet key rotation | Stronger forward secrecy than Rocket.Chat's model |

### Features Inspired by Chatwoot (Open Source Attribution)

The following GungChat features were identified and adapted from analysis of [chatwoot/chatwoot](https://github.com/chatwoot/chatwoot) (MIT License), a modern open-source customer support platform. All implementations are **redesigned from scratch** for GungChat's serverless, E2E-encrypted, P2P architecture:

| Chatwoot Feature | GungChat Adaptation | Key Difference |
|---|---|---|
| Canned responses with shortcode search | Quick reply templates stored in encrypted SQLite | Local-only; no server sync; ranked by usage |
| Conversation labels with color | Color-coded conversation tags | Local-only; no team-shared labels |
| Contact notes (CRUD) | Private contact annotations | Never transmitted; purely local annotations |
| Multi-attachment messages (15 max) | Up to 10 encrypted attachments per message | P2P chunked transfer; no server upload |
| Attachment taxonomy (location, contact card) | Location sharing + contact card type | Client-side only; GPS opt-in for privacy |
| Per-conversation attachment index | Shared media gallery with categorized view | Queries local encrypted cache by type |
| Light/dark/auto appearance modes | Theme service with system auto-detection | Flutter ThemeMode integration |
| Keyboard shortcut composables | Shortcut registry (Ctrl+K, Ctrl+Shift+D, etc.) | Optimized for tablet/desktop Flutter |
| Conversation mute + snoozed_until | Mute indefinitely or snooze until timestamp | Local notification suppression |
| Per-event notification settings | Granular toggle per event type | No server; SharedPreferences-based |
| ARIA labels, keyboard nav, screen reader | A11y helper + design guidelines | Flutter Semantics API; 48dp touch targets |
| Action Cable realtime events | **Not needed** — WebRTC data channel is inherently realtime | GungChat is already P2P realtime |
| Automation rules / macros | **Excluded** — over-engineered for 1:1 P2P chat | May revisit for power-user slash commands |
| CSAT survey / feedback | **Excluded** — helpdesk concept, not peer chat | Not applicable to P2P model |

### Technology Alternatives Considered

| Category | Chosen | Alternatives | Reason |
|----------|--------|--------------|--------|
| Framework | Flutter | React Native, Native | Single codebase, WebRTC support |
| Encryption | libsodium | OpenSSL, BoringSSL | Simple API, widely trusted |
| P2P | WebRTC | Custom TCP/UDP | Industry standard, NAT traversal |
| State Mgmt | Riverpod | Bloc, Provider | Modern, less boilerplate |

---

**Document Version**: 1.0
**Last Updated**: April 13, 2026
**Status**: Ready for Implementation
```

---

**Copy everything above** (starting from `# GungChat Implementation Plan`) and save it as `GungChat-Implementation-Plan.md` in your project directory. The document is ready to use as your development roadmap!---

**Copy everything above** (starting from `# GungChat Implementation Plan`) and save it as `GungChat-Implementation-Plan.md` in your project directory. The document is ready to use as your development roadmap!