# GungChat

GungChat is a privacy-first peer-to-peer messenger for Flutter.

Platform-specific handoff guides:

- [Windows 11 build and smoke test](WINDOWS_11_BUILD_AND_SMOKE_TEST.md)
- [Phase 9.7 manual test checklist](PHASE_9_7_MANUAL_TEST_CHECKLIST.md)

This repository currently contains the first implementation slice from the implementation plan:

- Flutter package bootstrap files
- Core encryption and key management primitives
- Basic WebRTC and network abstractions
- Local message persistence scaffolding
- An initial app shell for chats, contacts, and settings

## Current status

This Flutter app now includes platform folders for:

- Android
- iOS
- Windows

Current target platforms for the project are:

- Android
- iOS
- Windows 11

The current Linux workspace can validate Dart and Flutter code with analysis and tests, but it cannot produce a Windows executable. Build the Windows desktop app on a Windows 11 machine.

For Windows desktop build steps and a first-pass smoke test, use:

- [Windows 11 build and smoke test](WINDOWS_11_BUILD_AND_SMOKE_TEST.md)

Typical local validation from this directory:

```bash
flutter doctor -v
flutter analyze
flutter test
```

Typical Windows 11 build commands:

```powershell
flutter pub get
flutter run -d windows
flutter build windows
```

The current code is structured to match Phase 1 of the GungChat implementation plan and is ready for the next round of work on signaling, LAN discovery, and encrypted peer messaging.
