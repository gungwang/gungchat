# GungChat Session 1 Handoff

Date: 2026-04-16

## Scope Completed

This session created the initial Flutter project scaffold for GungChat under the `gungchat/` directory and brought the local Linux machine to a working Android-capable Flutter setup.

## Project State

Project root created:

- `gungchat/`

Initial implementation slice added:

- App shell and Riverpod wiring
- Core encryption service and key manager
- WebRTC manager, signaling envelope, ICE manager, network monitor
- Local SQLite message database
- Basic chat, contacts, and settings screens
- Initial widget and crypto tests

Important dependency state in `gungchat/pubspec.yaml`:

- `flutter_webrtc` upgraded to `^1.4.1`

Important Android release signing files now present locally:

- `gungchat/android/key.properties`
- `gungchat/android/upload-keystore.jks`

Repository status at the end of the session:

- `gungchat/` is still untracked in the parent repository

## Local Machine Setup Performed

### Flutter SDK

Installed locally at:

- `/home/wang/.local/flutter`

### JDK 17

Installed locally at:

- `/home/wang/.local/jdks/temurin-17`

Configured Flutter to use this JDK with:

- `flutter config --jdk-dir=/home/wang/.local/jdks/temurin-17`

### Android SDK

Installed locally at:

- `/home/wang/.local/android-sdk`

Configured Flutter to use this SDK with:

- `flutter config --android-sdk=/home/wang/.local/android-sdk`

Installed Android SDK components:

- platform-tools
- platforms;android-36
- build-tools;36.0.0
- cmake;3.22.1
- NDK side-by-side 28.2.13676358 was auto-installed during build

### Shell Configuration

Updated `/home/wang/.zshrc` to export:

- `PATH` additions for Flutter and Android tools
- `JAVA_HOME=/home/wang/.local/jdks/temurin-17`
- `ANDROID_HOME=/home/wang/.local/android-sdk`
- `ANDROID_SDK_ROOT=/home/wang/.local/android-sdk`

## Validation Completed

These commands succeeded before ending the session:

- `flutter analyze`
- `flutter test`
- `flutter doctor -v` with Android toolchain healthy when Android environment variables were present
- `flutter build apk --debug --target-platform android-arm64`
- `flutter build apk --debug`
- `flutter build apk --release`
- `flutter build appbundle --release`

Generated APK:

- `gungchat/build/app/outputs/flutter-apk/app-debug.apk`
- `gungchat/build/app/outputs/flutter-apk/app-release.apk`

Generated Android App Bundle:

- `gungchat/build/app/outputs/bundle/release/app-release.aab`

Release signing verification completed:

- The SHA-256 fingerprint of `android/upload-keystore.jks` matches the signer fingerprint of `app-release.apk`

## Problems Found And Fixed

### 1. Flutter command missing

Resolved by installing Flutter locally and adding it to the shell PATH.

### 2. Java mismatch for Android Gradle Plugin

Resolved by installing Temurin JDK 17 locally and configuring Flutter to use it.

### 3. Android SDK missing

Resolved by installing local Android command-line tools and the required SDK packages.

### 4. Old `flutter_webrtc` version failed on Android

Original version:

- `0.11.7`

Issue:

- It referenced the removed Flutter Android v1 embedding API (`PluginRegistry.Registrar`).

Resolved by upgrading to:

- `flutter_webrtc ^1.4.1`

### 5. Android native build missing Ninja

Resolved by installing Android SDK CMake package `3.22.1`.

### 6. Disk space pressure

The Linux filesystem was nearly full during Android packaging.

Observed issue:

- Universal debug APK packaging failed with no space left on device.

Resolved temporarily by:

- Cleaning the Flutter build output
- Removing downloaded installer archives
- Building a smaller single-ABI APK with `--target-platform android-arm64`

### 7. Android release signing configuration

Resolved by:

- Updating `gungchat/android/app/build.gradle.kts` to use a real release signing config from `android/key.properties`
- Generating a local `android/upload-keystore.jks`
- Generating a local ignored `android/key.properties`
- Verifying that `app-release.apk` is signed by the generated keystore

Committed documentation file added:

- `gungchat/android/RELEASE_SIGNING.md`

## Current Known Constraints

- iOS cannot be built from this Linux machine
- The parent repository has not yet staged or committed the new `gungchat/` directory

## Required Backup Now

Back up these two files outside this machine before any reinstall, cleanup, or key rotation:

- `gungchat/android/key.properties`
- `gungchat/android/upload-keystore.jks`

If either file is lost, future Android updates for the same app signing identity may become difficult or impossible to publish.

## Recommended Resume Steps After Reboot And Disk Expansion

Run these after the machine restarts:

1. `source ~/.zshrc`
2. `cd /home/wang/projects/gungchat/gungchat`
3. `flutter doctor -v`
4. `flutter analyze`
5. `flutter test`

If you want to re-verify Android packaging:

6. `flutter build apk --debug`

If you want a release build later:

7. `flutter build apk --release`

If you want a Play Store style bundle:

8. `flutter build appbundle --release`

## Recommended Next Engineering Step

Continue Phase 1 and early Phase 2 implementation work in this order:

1. Manual peer signaling flow for offer, answer, and ICE exchange
2. Real encrypted peer message transport on top of the data channel
3. LAN discovery integration
4. Platform-specific screenshot and recording protection hooks

## Most Relevant Files To Reopen First

- `gungchat/pubspec.yaml`
- `gungchat/android/app/build.gradle.kts`
- `gungchat/android/RELEASE_SIGNING.md`
- `gungchat/lib/app/providers.dart`
- `gungchat/lib/core/networking/webrtc_manager.dart`
- `gungchat/lib/core/networking/signaling_service.dart`
- `gungchat/lib/core/encryption/crypto_service.dart`
- `gungchat/lib/features/chat/chat_screen.dart`
- `/home/wang/.zshrc`

app-release.apk is an Android install package. A user can install it directly by sideloading on Android. This is useful for direct distribution, testing, or sharing outside Google Play.

app-release.aab is the Android App Bundle for Google Play. This is the file you normally upload to Google Play. End users do not install the .aab directly; Google Play turns it into optimized APKs for each device.