# Android Release Signing

This project now expects Android release signing files in the `android/` folder:

- `key.properties`
- `upload-keystore.jks`

These files are intentionally ignored by Git and must be backed up securely.

## Required Backup

Back up both files together:

- `android/key.properties`
- `android/upload-keystore.jks`

If either file is lost, future updates for the same Android app identity may become impossible to publish.

## Build Commands

With the signing files present, these commands should produce signed release artifacts:

```bash
flutter build apk --release
flutter build appbundle --release
```

## Rotation Note

Do not rotate the signing key for an existing production Android application unless you have a planned migration path.