# GungChat

GungChat is a privacy-first peer-to-peer messenger for Flutter.

This repository currently contains the first implementation slice from the implementation plan:

- Flutter package bootstrap files
- Core encryption and key management primitives
- Basic WebRTC and network abstractions
- Local message persistence scaffolding
- An initial app shell for chats, contacts, and settings

## Current status

The Flutter SDK is not installed in this workspace, so the Android/iOS platform wrappers were not generated yet. Once Flutter is available, run the following from this directory to create the platform folders:

```bash
flutter create --platforms=android,ios .
flutter pub get
flutter run
```

The current code is structured to match Phase 1 of the GungChat implementation plan and is ready for the next round of work on signaling, LAN discovery, and encrypted peer messaging.
