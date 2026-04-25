# Windows 11 Build And Smoke Test

Use this guide to build and do a first-pass smoke test of GungChat on Windows 11.

## Audience

Developers preparing or validating the Windows desktop build.

## Scope

This guide covers:

- local Windows 11 build prerequisites
- building the desktop app
- running a short smoke test pass

This guide does not cover:

- code signing
- MSI or installer packaging
- store distribution
- Android or iOS release workflows

## Preconditions

- Windows 11 machine
- Flutter SDK installed and on `PATH`
- Visual Studio with Windows desktop C++ build tools installed
- Git available in a terminal

Before building, confirm Flutter can see the Windows toolchain:

```powershell
flutter doctor -v
```

Resolve any Windows desktop issues reported by `flutter doctor` before continuing.

## Open The Project

From a terminal on Windows 11:

```powershell
cd <repo-root>\gungchat
flutter pub get
```

If you ever need to regenerate the Windows runner files:

```powershell
flutter create --platforms=windows .
```

## Run The App In Debug

Use this when you want the fastest feedback loop:

```powershell
flutter run -d windows
```

## Build A Release Executable

Use this when you want a distributable desktop build output:

```powershell
flutter build windows
```

Expected output location:

- `build\windows\x64\runner\Release\`

The main executable is typically:

- `build\windows\x64\runner\Release\gungchat.exe`

## Windows-Specific Notes

- Local message storage uses a Windows desktop SQLite path through `sqflite_common_ffi`.
- QR camera scanning is intentionally not exposed on Windows.
- On Windows, import contacts by pasting the contact payload into the import field.

This means the missing `Scan contact QR` action on Windows is expected behavior, not a defect.

## Smoke Test Checklist

After `flutter run -d windows` or after launching the built executable, run this quick pass.

### 1. Launch

- [ ] The app window opens successfully.
- [ ] Navigation between `Chats`, `Contacts`, and `Settings` works.
- [ ] Restarting the app does not immediately fail on startup.

### 2. Contacts

- [ ] Open `Contacts`.
- [ ] Confirm the QR scan button is not shown on Windows.
- [ ] Paste a valid contact payload into the import field.
- [ ] Import the contact.

Expected results:

- The import form is visible.
- The imported contact appears in saved contacts.
- The app does not attempt to open a camera scanner on Windows.

### 3. Chat Basics

- [ ] Open a chat with an imported or existing contact.
- [ ] Send a text message if a peer session is available.
- [ ] Open the chat again after navigating away.

Expected results:

- The chat screen opens normally.
- The composer remains usable.
- Previously stored messages still render after reopening the app.

### 4. Settings

- [ ] Open `Settings`.
- [ ] Confirm quick reply templates render.
- [ ] Create a quick reply template.
- [ ] Delete that template.

Expected results:

- Settings load without errors.
- Quick reply create and delete actions succeed.

### 5. Attachments And Gallery

- [ ] Open a conversation that already contains attachments, if available.
- [ ] Open the media gallery.
- [ ] Check the `Images`, `Audio`, and `Docs` tabs.

Expected results:

- Attachment messages render without layout errors.
- The gallery opens successfully.
- Tabs switch normally.

### 6. Optional Feature Checks

These depend on your local machine configuration and connected peers.

- [ ] File picking works.
- [ ] Location sharing works if Windows location services are enabled.
- [ ] WebRTC session setup succeeds between peers.
- [ ] App unlock works if you are testing desktop local authentication.

## Validation Commands

Before handing off a Windows-ready change, run:

```powershell
flutter analyze
flutter test
flutter build windows
```

## Failure Notes To Capture

If the Windows build or smoke test fails, record:

- Windows 11 version
- Flutter version from `flutter doctor -v`
- Visual Studio and C++ toolchain status
- failing command
- full terminal output
- whether the failure is build-time, launch-time, or feature-specific