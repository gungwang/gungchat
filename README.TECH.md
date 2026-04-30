# GungChat Technical Notes

This file is the short developer handoff for the current repository state.

## Current Status

- Repo root: `C:\AI\intel-ai\gungchat`
- Flutter app root: `C:\AI\intel-ai\gungchat\gungchat`
- Current app version: `2.0.3+3`
- Active desktop packaging flow: Windows Release folder plus Inno Setup installer
- Active mobile packaging flow: signed Android release APK
- iOS source tree exists, but real build and device validation still need macOS and Xcode

## Main App Surfaces

- `lib/app` - app shell and Riverpod providers
- `lib/features/chat` - chat UI, peer session control, LAN signaling, emulator bridge
- `lib/features/contacts` - contact book, QR/contact import, discovery flows
- `lib/features/settings` - preferences, privacy controls, app lock settings
- `lib/core` - encryption, storage, networking, accessibility, error handling
- `media` and `models` - gallery views, attachments, persisted app models

## Verified Build And Test Paths

Run these from `gungchat/`.

### Local Validation

```bash
flutter pub get
flutter analyze
flutter test
```

### Windows Desktop

```powershell
flutter run -d windows
flutter build windows
```

Output:

- `build/windows/x64/runner/Release/gungchat.exe`

### Windows Installer

```powershell
& "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe" ".\installer\gungchat.iss"
```

Output:

- `installer/output/gungchat-setup-2.0.3.exe`

### Android Release APK

```powershell
flutter build apk --release
```

Output:

- `build/app/outputs/flutter-apk/`

## Packaging Notes

- Windows installer version is controlled by `installer/gungchat.iss`.
- Windows EXE version strings are driven from `pubspec.yaml` through Flutter build generation.
- Windows branding strings live in `windows/runner/Runner.rc`.
- Android release signing expects local `android/key.properties` and `android/upload-keystore.jks`.
- The Windows app must be distributed as the full Release directory or through the generated installer, not as a bare EXE.

## Important Recent Changes

- Chat screen was simplified for Windows and desktop use, with details moved behind a secondary UI surface.
- LAN signaling was added so QR/contact handoff can trigger real peer signaling instead of manual copy-paste only.
- Contact import now prefers usable private LAN addresses over poor Windows virtual adapter addresses.
- An emulator-specific ADB bridge was added for Android emulator guest addresses such as `10.0.2.x`.
- Android version was updated to `2.0.3+3` and Windows installer naming now follows the app version.
- Root GitHub docs were refreshed for English and Chinese readers.

## Known Gaps

- iOS build, signing, and real-device testing still need an Apple developer with macOS and Xcode.
- Cross-device Windows to iPhone validation is still incomplete.
- Release signing materials should remain local and must not be committed.
- End-to-end regression coverage is still lighter than the feature surface.

## Help Wanted

The highest-value contributions right now are:

- iOS build and device testing
- WebRTC connection debugging across real devices
- Windows, Android, and iOS interoperability testing
- release hardening and QA automation

## Recommended Next Checks For Contributors

1. Run `flutter analyze` and `flutter test` from `gungchat/`.
2. Verify Windows desktop launch with `flutter run -d windows`.
3. Verify installer generation with `installer/gungchat.iss`.
4. If you have macOS, attempt `flutter build ios` and test on real hardware.

## Related Docs

- `README.md` - GitHub homepage overview
- `README.zh-CN.md` - Chinese overview
- `gungchat/WINDOWS_11_BUILD_AND_SMOKE_TEST.md` - Windows build and smoke test guide
- `gungchat/PHASE_9_7_MANUAL_TEST_CHECKLIST.md` - manual feature validation guide
- `SESSION_GungChat_*.md` - detailed historical handoff notes
