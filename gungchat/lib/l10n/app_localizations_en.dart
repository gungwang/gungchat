// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'GungChat';

  @override
  String get chatTab => 'Chats';

  @override
  String get contactsTab => 'Contacts';

  @override
  String get settingsTab => 'Settings';

  @override
  String get quickSearchTitle => 'Quick search';

  @override
  String get searchContactsLabel => 'Search contacts';

  @override
  String get searchContactsHint => 'Name or fingerprint';

  @override
  String get noContactsMatchSearch => 'No contacts match that search.';

  @override
  String get closeAction => 'Close';

  @override
  String get openedChatForLabel => 'Opened chat for';

  @override
  String get mutedAnnouncementLabel => 'Muted';

  @override
  String get unmutedAnnouncementLabel => 'Unmuted';

  @override
  String get themeChangedToLabel => 'Theme changed to';

  @override
  String get appLockedTitle => 'GungChat is locked';

  @override
  String get unlockPrompt => 'Unlock with your device credentials to continue.';

  @override
  String get unlockingAction => 'Unlocking...';

  @override
  String get unlockAction => 'Unlock';

  @override
  String get openAction => 'Open';

  @override
  String get discoveryTitle => 'Discovery';

  @override
  String get discoverySubtitle =>
      'Scan once to establish trust. After the first QR exchange, both devices can reconnect with one tap.';

  @override
  String get activeChatTargetLabel => 'Active chat target';

  @override
  String get yourConnectQrTitle => 'Your Connect QR';

  @override
  String get yourConnectQrHelp =>
      'Open this page on the other device and scan this QR code. GungChat will exchange identities and connect automatically over LAN.';

  @override
  String get displayNameLabel => 'Display name';

  @override
  String get contactCardUnavailableLabel => 'Contact card unavailable';

  @override
  String get identityUnavailableLabel => 'Identity unavailable';

  @override
  String get fingerprintLabel => 'Fingerprint';

  @override
  String get noLanAddressesDetected => 'No LAN addresses detected yet.';

  @override
  String get lanAddressesLabel => 'LAN addresses';

  @override
  String get keepQrVisibleHint =>
      'Keep this QR visible until the other device finishes scanning and starts connecting.';

  @override
  String get scanPeerQrTitle => 'Scan Peer QR';

  @override
  String get scanPeerQrCameraHelp =>
      'Use this device camera to scan the other GungChat QR code. The first scan creates a trusted connection automatically.';

  @override
  String get scanPeerQrDesktopHelp =>
      'This device cannot scan QR codes. Use another GungChat device with a camera to scan this QR code and complete the first trust exchange.';

  @override
  String get scanQrAndConnectAction => 'Scan QR and Connect';

  @override
  String get scanOnAnotherDeviceAction => 'Scan on Another Device';

  @override
  String get savedContactsTitle => 'Saved Contacts';

  @override
  String get savedContactsEmpty =>
      'Trusted devices appear here after the first QR scan.';

  @override
  String get blockedContactsCannotStartSession =>
      'Blocked contacts cannot start a peer session.';

  @override
  String get scanQrNotAvailableOnWindows =>
      'QR scanning is not available on Windows. Use another GungChat device with a camera to scan this code.';

  @override
  String get scanDeviceBeforeConnect =>
      'Scan a GungChat QR code before trying to connect.';

  @override
  String get qrMissingLanAddress =>
      'This QR code does not include a usable LAN address yet. Open the QR page on the other device again and rescan it.';

  @override
  String get trustedConnectingLabel =>
      'Trusted. Connecting automatically over LAN:';

  @override
  String get connectingAutomaticallyLabel => 'Connecting automatically to';

  @override
  String get qrConnectionFailedLabel => 'QR connection failed';

  @override
  String get organizationTitle => 'Organization';

  @override
  String get organizationSubtitle =>
      'Manage labels, private notes, and notification state for this contact.';

  @override
  String get labelsTitle => 'Labels';

  @override
  String get noLabelsCreatedYet => 'No labels created yet.';

  @override
  String get newLabelLabel => 'New label';

  @override
  String get createLabelAction => 'Create label';

  @override
  String get privateNotesTitle => 'Private notes';

  @override
  String get noPrivateNotesYet => 'No private notes for this contact yet.';

  @override
  String get updatedLabel => 'Updated';

  @override
  String get deleteNoteTooltip => 'Delete note';

  @override
  String get addPrivateNoteLabel => 'Add private note';

  @override
  String get saveNoteAction => 'Save note';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get mutedUntilManualUnmute => 'Muted until you manually unmute it.';

  @override
  String get snoozedUntilLabel => 'Snoozed until';

  @override
  String get notificationsActiveForContact =>
      'Notifications are active for this contact.';

  @override
  String get muteAction => 'Mute';

  @override
  String get unmuteAction => 'Unmute';

  @override
  String get snooze1hAction => 'Snooze 1h';

  @override
  String get snooze8hAction => 'Snooze 8h';

  @override
  String get trustedChip => 'Trusted';

  @override
  String get blockedChip => 'Blocked';

  @override
  String get selectedChip => 'Selected';

  @override
  String get lanDiscoveredChip => 'LAN discovered';

  @override
  String get scanQrFirstChip => 'Scan QR first';

  @override
  String get manageAction => 'Manage';

  @override
  String get openInChatAction => 'Open In Chat';

  @override
  String get connectAction => 'Connect';

  @override
  String get needsQrAction => 'Needs QR';

  @override
  String get unblockAction => 'Unblock';

  @override
  String get blockAction => 'Block';

  @override
  String get seenLabel => 'Seen';

  @override
  String get blockedLabel => 'Blocked';

  @override
  String get unblockedLabel => 'Unblocked';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get appearanceTitle => 'Appearance';

  @override
  String get themeModeLabel => 'Theme mode';

  @override
  String get themeModeAuto => 'Auto';

  @override
  String get themeModeLight => 'Light';

  @override
  String get themeModeDark => 'Dark';

  @override
  String get keyboardShortcutThemeHint =>
      'Keyboard shortcut: Ctrl+Shift+D cycles between Auto, Light, and Dark.';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageChineseSimplified => 'Chinese (Simplified)';

  @override
  String get languageChineseTraditional => 'Chinese (Traditional)';

  @override
  String get languageSpanish => 'Spanish';

  @override
  String get languageFrench => 'French';

  @override
  String get languageChangeHelp =>
      'Applies immediately. Choose System default to follow your device language.';

  @override
  String get quickReplyTemplatesTitle => 'Quick reply templates';

  @override
  String get shortcodeLabel => 'Shortcode';

  @override
  String get templateTextLabel => 'Template text';

  @override
  String get saveTemplateAction => 'Save template';

  @override
  String get noQuickRepliesYet =>
      'No quick replies saved yet. Create one here, then type its shortcode in chat to insert it instantly.';

  @override
  String get usedLabel => 'Used';

  @override
  String get timeSingular => 'time';

  @override
  String get timePlural => 'times';

  @override
  String get deleteTemplateTooltip => 'Delete template';

  @override
  String get quickRepliesLoadFailedLabel => 'Could not load quick replies';

  @override
  String get quickReplySavedLabel => 'Quick reply saved';

  @override
  String get quickReplyDeletedLabel => 'Quick reply deleted';

  @override
  String get customStatusTitle => 'Custom status';

  @override
  String get statusTextLabel => 'Status text';

  @override
  String get statusTextHint =>
      'In a meeting, Do not disturb, Available later...';

  @override
  String get customStatusHelp =>
      'This text is shared directly with the active peer session alongside your presence status.';

  @override
  String get screenshotProtectionTitle => 'Screenshot protection';

  @override
  String get screenshotProtectionSubtitle =>
      'Android now enables secure windows. iOS and desktop recording detection still need platform-specific follow-up.';

  @override
  String get readReceiptsTitle => 'Read receipts';

  @override
  String get readReceiptsSubtitle =>
      'Opt in to send encrypted read confirmations when you open a conversation and view delivered messages.';

  @override
  String get linkPreviewsTitle => 'Link previews';

  @override
  String get linkPreviewsSubtitle =>
      'Off by default for privacy. Enabling previews lets your device fetch webpage metadata directly, which can reveal your IP address to those sites.';

  @override
  String get presenceStatusTitle => 'Presence status';

  @override
  String get sharedPresenceLabel => 'Shared presence';

  @override
  String get presenceOnline => 'Online';

  @override
  String get presenceAway => 'Away';

  @override
  String get presenceHidden => 'Hidden';

  @override
  String get sharedPresenceHelp =>
      'Online is shared while the app is in the foreground and automatically falls back to Away in the background. Hidden suppresses your presence updates.';

  @override
  String get notificationPreferencesTitle => 'Notification preferences';

  @override
  String get notificationMessages => 'Messages';

  @override
  String get notificationCalls => 'Calls';

  @override
  String get notificationPresenceChanges => 'Presence changes';

  @override
  String get notificationConnectionRequests => 'Connection requests';

  @override
  String get notificationReactions => 'Reactions';

  @override
  String get notificationSound => 'Sound';

  @override
  String get notificationVibrate => 'Vibrate';

  @override
  String get keyboardShortcutsTitle => 'Keyboard shortcuts';

  @override
  String get shortcutOpenQuickSearch => 'Open quick search';

  @override
  String get shortcutCycleThemeMode => 'Cycle theme mode';

  @override
  String get shortcutNextTab => 'Move to the next app tab';

  @override
  String get shortcutPreviousTab => 'Move to the previous app tab';

  @override
  String get shortcutFocusComposer => 'Focus the active chat composer';

  @override
  String get shortcutMuteConversation => 'Mute the selected conversation';

  @override
  String get appLockTitle => 'App lock';

  @override
  String get requireUnlockTitle => 'Require biometric or device unlock';

  @override
  String get requireUnlockSubtitle =>
      'When enabled, GungChat prompts for device authentication on launch and after returning from the background.';

  @override
  String get relockAfterLabel => 'Re-lock after';

  @override
  String get secondUnit => 'second';

  @override
  String get secondsUnit => 'seconds';

  @override
  String get minuteUnit => 'minute';

  @override
  String get minutesUnit => 'minutes';

  @override
  String get accessibilityTitle => 'Accessibility';

  @override
  String get reducedMotionLabel => 'Reduced motion';

  @override
  String get highContrastLabel => 'High contrast';

  @override
  String get onValue => 'On';

  @override
  String get offValue => 'Off';

  @override
  String get accessibilitySummary =>
      'This phase uses 48dp minimum touch targets, screen-reader announcements for key actions, and keyboard shortcut discovery surfaces.';

  @override
  String get burnAfterReadDefaultTitle => 'Burn after read default';

  @override
  String get burnAfterReadDefaultSubtitle =>
      'The chat bootstrap flow already assumes ephemeral-first messaging.';

  @override
  String get antiSurveillanceGuardTitle => 'Anti-surveillance guard';

  @override
  String get antiSurveillanceGuardSubtitle =>
      'Transport is in place. Next platform work is expanding recording detection and privacy guard behavior beyond Android secure windows.';

  @override
  String get selectContactToStartVideoCall =>
      'Select a contact to start a video call';

  @override
  String get blockedContactsCannotBeCalled =>
      'Blocked contacts cannot be called';

  @override
  String get contactNeedsLanBeforeCall =>
      'This contact needs a LAN address before you can call them';

  @override
  String get startVideoCallTooltip => 'Start video call';

  @override
  String get videoCallAlreadyInProgress =>
      'A video call is already in progress';

  @override
  String get secureChannelOpen => 'Secure channel open';

  @override
  String get chooseContactFromContacts => 'Choose a contact from Contacts';

  @override
  String get isBlockedSuffix => 'is blocked';

  @override
  String get readyToConnect => 'Ready to connect';

  @override
  String get connectionDetailsTitle => 'Connection Details';

  @override
  String get connectionDetailsTooltip => 'Connection details';

  @override
  String get videoCallCouldNotStartLabel => 'Video call could not start';

  @override
  String get noMessagesYetBootstrap =>
      'No messages yet. Save a local bootstrap message or select a peer contact.';

  @override
  String get noMessagesYetPeer =>
      'No messages yet for this peer. Finish signaling to start the secure conversation.';

  @override
  String get messageLoadFailedLabel => 'Message load failed';

  @override
  String get conversationLabel => 'Conversation';

  @override
  String get localBootstrapCache => 'local bootstrap cache';

  @override
  String get waitingForSecureChannel => 'waiting for secure channel';

  @override
  String get peerCustomStatusLabel => 'Peer custom status';

  @override
  String get yourCustomStatusLabel => 'Your custom status';

  @override
  String get blockedContactWarning =>
      'This contact is blocked. Unblock them in Contacts before continuing peer messaging.';

  @override
  String get replyingToYourself => 'Replying to yourself';

  @override
  String get replyingToPeer => 'Replying to peer';

  @override
  String get cancelReplyTooltip => 'Cancel reply';

  @override
  String get composerSendAction => 'Send';

  @override
  String get composerSaveLocalAction => 'Save Local Message';

  @override
  String get composerWaitForSecureChannel => 'Wait For Secure Channel';

  @override
  String get composerSaveMessageEditAction => 'Save Message Edit';

  @override
  String get composerConnectAction => 'Connect';

  @override
  String get composerBurnAfterReadLabel => 'Burn after read';

  @override
  String get composerRecordVoiceTooltip => 'Record voice';

  @override
  String get composerStopAndSendVoiceTooltip => 'Stop and send voice';

  @override
  String get composerMoreActionsTooltip => 'More actions';

  @override
  String get composerBootstrapHint => 'Type a local encrypted message draft...';

  @override
  String get composerPeerHint =>
      'Type an encrypted message for the active peer session...';

  @override
  String get composerEditHint =>
      'Update your encrypted message for the active peer session...';

  @override
  String get composerHelpHint =>
      'Type /help for local commands, or complete the signal exchange to enable sending.';

  @override
  String get composerBlockedHint =>
      'This contact is blocked. Slash commands still run locally.';

  @override
  String get composerOpenSessionForStickers =>
      'Open a secure session before sending stickers.';

  @override
  String get composerFinishSignalExchangeWarning =>
      'Finish the signal exchange before sending peer messages.';

  @override
  String composerOpenSessionBeforeSend(Object name) {
    return 'Open or answer a session with $name before sending.';
  }

  @override
  String get composerRecordingHint =>
      'Recording voice message... tap Stop & Send when ready. Up to 2 minutes.';

  @override
  String get composerOpenChannelBeforeRecording =>
      'Open the secure channel before recording voice messages.';

  @override
  String get composerMicrophoneError =>
      'Could not access the microphone. Check app permissions and device microphone settings.';

  @override
  String get composerEditLabel => 'Edit secure message';

  @override
  String get composerSecureLabel => 'Secure peer message';

  @override
  String get composerBootstrapLabel => 'Bootstrap message';

  @override
  String get composerPeerLabel => 'Peer message';

  @override
  String composerTypingStatus(Object name) {
    return '$name is typing...';
  }

  @override
  String get attachmentMenuGallery => 'Gallery';

  @override
  String get attachmentMenuFiles => 'Files';

  @override
  String get attachmentMenuLocation => 'Location';

  @override
  String get attachmentMenuContact => 'Contact';

  @override
  String get attachmentMenuSticker => 'Sticker';

  @override
  String get stickerPickerTitle => 'Stickers';

  @override
  String get stickerLabelSmile => 'Smile';

  @override
  String get stickerLabelHeart => 'Heart';

  @override
  String get stickerLabelThumbs => 'Thumbs up';

  @override
  String get stickerLabelParty => 'Party';

  @override
  String get stickerLabelFire => 'Fire';

  @override
  String get stickerLabelSad => 'Sad';

  @override
  String get stickerLabelOk => 'OK';

  @override
  String get stickerLabelClap => 'Clap';

  @override
  String get messageBubbleQuotedMessage => 'Quoted message';

  @override
  String get messageBubbleStarTooltip => 'Star message';

  @override
  String get messageBubbleRemoveStarTooltip => 'Remove star';

  @override
  String get messageBubbleActionsTooltip => 'Message actions';

  @override
  String get messageBubbleEditAction => 'Edit message';

  @override
  String get messageBubbleDeleteForEveryoneAction => 'Delete for everyone';

  @override
  String get messageBubbleErasePermanentlyAction => 'Erase permanently';

  @override
  String get messageBubbleAddReactionTooltip => 'Add reaction';

  @override
  String get messageBubbleMessageDeletedLabel => 'Message deleted';

  @override
  String get messageBubbleBurnAfterReadBadge => 'Burn-after-read';

  @override
  String get messageBubblePersistentBadge => 'Persistent';

  @override
  String get messageBubbleDeletedMarker => 'deleted';

  @override
  String get messageBubbleEditedMarker => 'edited';

  @override
  String get messageBubbleSpoilerLabel => 'Spoiler';

  @override
  String get messageBubbleSpoilerHint => 'Spoiler, tap to reveal';

  @override
  String get messageBubblePlayVoiceTooltip => 'Play voice message';

  @override
  String get messageBubbleStopVoiceTooltip => 'Stop voice message';

  @override
  String get messageBubbleVoiceMessageLabel => 'Voice message';

  @override
  String get messageBubbleSharedLocationLabel => 'Shared location';

  @override
  String get messageBubbleSharedContactLabel => 'Shared contact';

  @override
  String messageBubbleLatLngLabel(Object lat, Object lng) {
    return 'Lat $lat, Lng $lng';
  }

  @override
  String get messageBubbleLoadingLinkPreview => 'Loading link preview...';

  @override
  String get messageBubbleAttachmentSentAnnouncement => 'Attachment sent';

  @override
  String get messageBubbleQuickReplyInsertedAnnouncement =>
      'Quick reply inserted';

  @override
  String get messageBubbleDialogCancel => 'Cancel';

  @override
  String get messageBubbleDialogClose => 'Close';

  @override
  String get messageBubbleDeleteForEveryoneTitle =>
      'Delete message for everyone?';

  @override
  String get messageBubbleDeleteForEveryoneBody =>
      'This replaces the message with a deleted placeholder in the conversation.';

  @override
  String get messageBubbleErasePermanentlyTitle => 'Erase message permanently?';

  @override
  String get messageBubbleErasePermanentlyBody =>
      'This removes the message record instead of showing a deleted placeholder.';

  @override
  String get messageBubbleEraseLabel => 'Erase';

  @override
  String get messageBubbleDeleteLabel => 'Delete';

  @override
  String get messageBubbleOriginalMessageGone =>
      'The original message is no longer available.';
}
