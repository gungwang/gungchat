# GungChat Session dev.28 Handoff

Date: 2026-05-28

## Summary

This session focused on user-reported chat UX gaps, missing localization on the chat surface, burn-after-read behavior, and release-surface cleanup.

Main outcomes completed today:

- reconnect UX was improved so the chat composer can surface a direct `Connect` action when a trusted peer is known but the secure channel is offline
- the composer label was simplified from `Send Secure Message` to `Send`
- bundled local sticker support was added without relying on third-party sticker services
- chat auto-scroll was fixed so the newest messages stay visible
- chat-screen localization was completed across English, Simplified Chinese, Traditional Chinese, Spanish, and French
- the untranslated `Idle` label and the connection-details modal were localized
- burn-after-read no longer feels instantaneous; a persisted delay setting was added so deletion can happen after a configurable post-read interval
- a working QR code asset for the GitHub releases page was generated and the broken README QR reference was replaced
- focused validation passed for the touched chat/localization work, and the current context also shows a successful Windows release build

## Issues Raised Today

### 1. Reconnection Was Too Frictional

Problem:

- after an initial trusted exchange, returning to an offline chat still left too much reconnection friction
- the user needed a quick path to reconnect from the existing chat surface instead of navigating through setup again

Resolution:

- the chat composer now detects when a verified contact has a usable known address but no active secure channel
- in that state, the composer action changes to `Connect` with a dedicated connect icon
- the connect action dispatches `PeerConnectIntent` over the existing LAN signaling path
- the behavior works on both sides after the first trust exchange because both peers persist verified contact data and last-known addressing

### 2. Composer Copy Was Too Verbose

Problem:

- `Send Secure Message` was unnecessarily long in the composer and added friction to a frequently used action

Resolution:

- the primary action label was shortened to `Send`

### 3. Burn-After-Read Was Too Aggressive

Problem:

- burn-after-read messages were being removed too quickly for real reading comfort
- the original implementation deleted burn-after-read messages immediately once read events were processed
- a creation-time TTL backstop existed, but that did not provide a user-configurable read-delay experience

Resolution:

- a persisted burn-after-read delay setting was added
- the default delay is `30 seconds`
- supported values are:
	- immediate
	- 5 seconds
	- 10 seconds
	- 30 seconds
	- 1 minute
	- 5 minutes
	- 10 minutes
- when a message is marked read, the controller now reschedules its `expiresAt` instead of deleting immediately
- a local timer is also scheduled so an already open conversation refreshes promptly when the delayed deletion time is reached

### 4. Chat Screen Still Had Translation Gaps

Problem:

- the user reported that `Idle` remained untranslated
- the connection-details modal still contained untranslated UI strings even after broader chat-surface localization work

Resolution:

- state labels, identity/network/session cards, signal labels, and summary mappings in the chat details UI were localized
- ARB catalogs were expanded across all five supported locales
- generated localizations were refreshed and the chat UI now uses `context.l10n` consistently for those surfaces

### 5. Sticker Support Needed To Stay Local

Problem:

- the user wanted sticker support, but without pulling from third-party online sticker packs

Resolution:

- a bundled local sticker pack was added using app-owned assets
- the implementation stayed offline-first and avoided new network dependencies for stickers

### 6. Chat Auto-Scroll Was Not Keeping Up With New Messages

Problem:

- incoming or newly appended messages could leave the latest content out of view

Resolution:

- the chat list was updated so it reliably scrolls to the latest message when appropriate

### 7. Release QR In README Was Not Working

Problem:

- the README QR block used broken Markdown and a non-working image reference

Resolution:

- a new QR asset was generated for `https://github.com/gungwang/gungchat/releases`
- the root README now uses a standard clickable image link pointing to the new SVG asset and the releases page

## Solutions And Technical Details

### Reconnect UX And Composer Changes

Key files:

- `gungchat/lib/features/chat/chat_screen.dart`

Main changes:

- added quick-connect state detection for verified contacts with a known address and no current secure session
- updated the composer action block to switch between `Connect` and `Send` based on session state
- kept the reconnect path on the existing LAN signaling workflow instead of introducing a second connection mechanism

### Burn-After-Read Delay Setting And Deletion Scheduling

Key files:

- `gungchat/lib/features/settings/burn_after_read_delay_preferences.dart`
- `gungchat/lib/app/providers.dart`
- `gungchat/lib/features/settings/settings_screen.dart`
- `gungchat/lib/features/chat/peer_session_controller.dart`
- `gungchat/lib/features/chat/message_service.dart`
- `gungchat/lib/core/storage/message_db.dart`
- `gungchat/test/features/chat/peer_session_controller_test.dart`

Main changes:

- added `BurnAfterReadDelayPreferencesStorage` and `BurnAfterReadDelayPreferenceController`
- persisted the selected delay through `SharedPreferences`
- exposed the setting through Riverpod providers
- added a Settings dropdown so users can configure the delay in-app
- changed `PeerSessionController.markMessagesRead(...)` so inbound burn-after-read messages no longer hard-delete immediately on read
- changed `_handleReceiptEnvelope(...)` so outgoing burn-after-read messages also reschedule expiry instead of hard-deleting immediately when a read receipt arrives
- added timer-based local deletion scheduling so open chats update promptly without waiting for a future manual refresh
- added `updateMessageExpiry(...)` support in both the message database layer and the message service layer
- added focused test coverage to assert that read processing schedules deletion instead of removing the message immediately

Important behavior note:

- the older creation-time TTL backstop still exists as a safety net
- the new read-delay behavior overrides the post-read expiry time with the configured setting

### Chat Localization Completion

Key files:

- `gungchat/lib/features/chat/chat_screen.dart`
- `gungchat/lib/features/chat/widgets/message_bubble.dart`
- `gungchat/lib/features/chat/sticker_picker_sheet.dart`
- `gungchat/lib/models/sticker_pack.dart`
- `gungchat/lib/l10n/app_en.arb`
- `gungchat/lib/l10n/app_zh.arb`
- `gungchat/lib/l10n/app_zh_TW.arb`
- `gungchat/lib/l10n/app_es.arb`
- `gungchat/lib/l10n/app_fr.arb`
- generated localization files under `gungchat/lib/l10n/`

Main changes:

- localized the chat screen surface for five supported locales
- replaced remaining hardcoded chat strings with `context.l10n`
- added missing keys for stickers, chat labels, connection details, and burn-after-read settings
- localized `Idle` and the connection-details modal after the user surfaced the missing strings explicitly

### Sticker Pack And Auto-Scroll

Key files:

- `gungchat/lib/features/chat/chat_screen.dart`
- `gungchat/lib/features/chat/widgets/message_bubble.dart`
- sticker asset files under `gungchat/assets/`

Main changes:

- added a bundled local sticker pack with app-owned assets
- kept the feature local and dependency-light
- adjusted chat list behavior so new content scrolls into view more reliably

### QR Asset And README Fix

Key files:

- `gungchat/assets/gungchat-releases-qr.svg`
- `README.md`

Main changes:

- generated a QR code SVG that points to the GitHub releases page
- replaced the broken README QR block with a working clickable image link
- used repo-relative forward-slash Markdown paths so the image renders correctly on GitHub

## Validation

Completed validation during this work:

- `flutter gen-l10n`
- `flutter analyze lib`
- `flutter test test/features/chat`

Observed passing results from the current session context:

- focused chat tests passed after the burn-after-read delay work, including the new controller test
- Windows release build completed successfully with `flutter build windows --release`

## What We Learned

### 1. Burn-After-Read Needs Two Layers

- persisting only an expiry timestamp is not enough for good UX when the conversation is already open
- the app also needs an active in-memory timer or another refresh trigger so deletion becomes visible at the right moment

### 2. Refresh-Driven UI Can Hide Time-Based Bugs

- `conversationMessagesProvider` refreshes on invalidation rather than on a background clock
- this means time-based behavior needs an explicit refresh strategy, especially for ephemeral content

### 3. Localization Gaps Often Survive In Secondary Surfaces

- top-level screens can look translated while state chips, modals, and UI-layer mappings still contain hardcoded strings
- connection details and presence/state labels are good places to check after the main pass

### 4. Focused Patches Are Safer Than One Large Edit Burst

- a large multi-file patch failed once the local file context drifted
- splitting the change into smaller targeted edits made the work easier to apply and verify cleanly

### 5. Markdown Image Syntax And Path Style Matter

- the broken README QR section was not just an asset problem; the Markdown itself was malformed
- standard clickable image syntax with forward-slash repo-relative paths is the safe default for GitHub rendering

## Final State At End Of Session

- reconnect UX is smoother from the chat surface
- chat send/connect actions are clearer
- bundled stickers are available locally
- chat auto-scroll is fixed
- chat-surface localization is complete for the scoped work, including the connection-details modal
- burn-after-read now has a user-configurable post-read delay and no longer feels unreadably immediate
- the release QR now works in the root README
- the chat-focused validation path is green