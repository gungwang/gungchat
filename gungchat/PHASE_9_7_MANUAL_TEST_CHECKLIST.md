# Phase 9.7 Manual Test Checklist

Use this checklist for a real-device verification pass of the Phase 9.7 UX polish and organization features on Android and iOS.

## Audience

Developers and QA testers validating a release candidate on physical devices.

## Scope

This checklist covers:

- file sharing
- location sharing
- contact mute and snooze controls
- conversation media gallery behavior

This checklist does not cover QR onboarding, LAN discovery, or the earlier chat/session flows.

## Preconditions

- Install the latest build on at least one Android device and one iOS device.
- Make sure each device has at least one saved contact and an open chat route that can send and receive messages.
- Prepare sample files: one image, one PDF, and one short audio clip.
- Start with app notifications enabled at the OS level.
- Clear any stale mute or snooze state for the contact before the pass starts.

## Common Checks

Run the following checks on both Android and iOS.

### 1. File Share

- [ ] Open a chat with a connected contact.
- [ ] Share one image.
- [ ] Share one PDF.
- [ ] If available, share one audio file.

Expected results:

- The send action completes without a crash or stuck loading state.
- The sender sees the new attachment bubble immediately.
- Images render as image content or a safe fallback tile.
- Documents and audio files render with the correct filename and metadata.
- The receiver gets the attachment message and the conversation remains usable.

### 2. Location Share

- [ ] Trigger the location share action from the chat composer.
- [ ] Grant location permission if prompted.
- [ ] Verify the sender bubble after the share completes.
- [ ] Verify the receiver bubble after delivery.

Expected results:

- The app either requests permission once or uses the existing granted permission.
- After success, the chat shows a `Shared location` card with coordinates.
- The conversation does not freeze or lose input focus after the share.
- If permission is denied, the app shows a clear failure path instead of silently failing.

### 3. Mute And Snooze

- [ ] Open the contact organization panel for a saved contact.
- [ ] Tap `Mute` and confirm the muted status text.
- [ ] Tap `Unmute` and confirm notifications return to the active state.
- [ ] Tap `Snooze 1h` and confirm the snoozed status text changes.
- [ ] Tap `Snooze 8h` and confirm the later snooze time replaces the earlier one.
- [ ] Leave the screen and reopen it.

Expected results:

- The mute state updates immediately in the UI.
- The snooze state updates immediately in the UI.
- The latest mute or snooze choice persists after navigation.
- Unmute clears the muted or snoozed state cleanly.

### 4. Media Gallery

- [ ] Open the conversation media gallery for a chat that contains recent shared content.
- [ ] Check the `Images` tab after sending an image.
- [ ] Check the `Audio` tab after sending a voice note or audio file.
- [ ] Check the `Docs` tab after sending a PDF, location, or contact card.
- [ ] Open at least one image from the gallery viewer.

Expected results:

- The gallery opens without a crash.
- Each attachment type appears under the correct tab.
- Empty tabs show placeholder text instead of blank content.
- The image viewer opens and returns to the gallery cleanly.
- Document, location, and contact-card entries show readable metadata.

## Android Notes

- [ ] Confirm the file picker can return content from both local storage and a document provider.
- [ ] Confirm the first location permission prompt returns to GungChat correctly after approval.
- [ ] Confirm back navigation from the gallery and image viewer returns to the same conversation.
- [ ] Confirm notification behavior respects the muted or snoozed state while the app is backgrounded.

## iOS Notes

- [ ] Confirm file selection works from `Files` and any enabled media sources without layout issues.
- [ ] Confirm the iOS location prompt returns to the app cleanly after allow or deny.
- [ ] Confirm safe areas are respected in the gallery and image viewer.
- [ ] Confirm notification behavior respects the muted or snoozed state while the app is backgrounded.

## Failure Notes To Capture

If a check fails, record:

- platform and OS version
- device model
- exact action that triggered the issue
- whether the failure happened on sender, receiver, or both
- screenshot or screen recording if the issue is visible