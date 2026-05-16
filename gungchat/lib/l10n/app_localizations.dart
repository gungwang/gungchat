import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('zh'),
    Locale('zh', 'TW')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'GungChat'**
  String get appTitle;

  /// No description provided for @chatTab.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chatTab;

  /// No description provided for @contactsTab.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get contactsTab;

  /// No description provided for @settingsTab.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTab;

  /// No description provided for @quickSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick search'**
  String get quickSearchTitle;

  /// No description provided for @searchContactsLabel.
  ///
  /// In en, this message translates to:
  /// **'Search contacts'**
  String get searchContactsLabel;

  /// No description provided for @searchContactsHint.
  ///
  /// In en, this message translates to:
  /// **'Name or fingerprint'**
  String get searchContactsHint;

  /// No description provided for @noContactsMatchSearch.
  ///
  /// In en, this message translates to:
  /// **'No contacts match that search.'**
  String get noContactsMatchSearch;

  /// No description provided for @closeAction.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeAction;

  /// No description provided for @openedChatForLabel.
  ///
  /// In en, this message translates to:
  /// **'Opened chat for'**
  String get openedChatForLabel;

  /// No description provided for @mutedAnnouncementLabel.
  ///
  /// In en, this message translates to:
  /// **'Muted'**
  String get mutedAnnouncementLabel;

  /// No description provided for @unmutedAnnouncementLabel.
  ///
  /// In en, this message translates to:
  /// **'Unmuted'**
  String get unmutedAnnouncementLabel;

  /// No description provided for @themeChangedToLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme changed to'**
  String get themeChangedToLabel;

  /// No description provided for @appLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'GungChat is locked'**
  String get appLockedTitle;

  /// No description provided for @unlockPrompt.
  ///
  /// In en, this message translates to:
  /// **'Unlock with your device credentials to continue.'**
  String get unlockPrompt;

  /// No description provided for @unlockingAction.
  ///
  /// In en, this message translates to:
  /// **'Unlocking...'**
  String get unlockingAction;

  /// No description provided for @unlockAction.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlockAction;

  /// No description provided for @openAction.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openAction;

  /// No description provided for @discoveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Discovery'**
  String get discoveryTitle;

  /// No description provided for @discoverySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scan once to establish trust. After the first QR exchange, both devices can reconnect with one tap.'**
  String get discoverySubtitle;

  /// No description provided for @activeChatTargetLabel.
  ///
  /// In en, this message translates to:
  /// **'Active chat target'**
  String get activeChatTargetLabel;

  /// No description provided for @yourConnectQrTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Connect QR'**
  String get yourConnectQrTitle;

  /// No description provided for @yourConnectQrHelp.
  ///
  /// In en, this message translates to:
  /// **'Open this page on the other device and scan this QR code. GungChat will exchange identities and connect automatically over LAN.'**
  String get yourConnectQrHelp;

  /// No description provided for @displayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayNameLabel;

  /// No description provided for @contactCardUnavailableLabel.
  ///
  /// In en, this message translates to:
  /// **'Contact card unavailable'**
  String get contactCardUnavailableLabel;

  /// No description provided for @identityUnavailableLabel.
  ///
  /// In en, this message translates to:
  /// **'Identity unavailable'**
  String get identityUnavailableLabel;

  /// No description provided for @fingerprintLabel.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint'**
  String get fingerprintLabel;

  /// No description provided for @noLanAddressesDetected.
  ///
  /// In en, this message translates to:
  /// **'No LAN addresses detected yet.'**
  String get noLanAddressesDetected;

  /// No description provided for @lanAddressesLabel.
  ///
  /// In en, this message translates to:
  /// **'LAN addresses'**
  String get lanAddressesLabel;

  /// No description provided for @keepQrVisibleHint.
  ///
  /// In en, this message translates to:
  /// **'Keep this QR visible until the other device finishes scanning and starts connecting.'**
  String get keepQrVisibleHint;

  /// No description provided for @scanPeerQrTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan Peer QR'**
  String get scanPeerQrTitle;

  /// No description provided for @scanPeerQrCameraHelp.
  ///
  /// In en, this message translates to:
  /// **'Use this device camera to scan the other GungChat QR code. The first scan creates a trusted connection automatically.'**
  String get scanPeerQrCameraHelp;

  /// No description provided for @scanPeerQrDesktopHelp.
  ///
  /// In en, this message translates to:
  /// **'This device cannot scan QR codes. Use another GungChat device with a camera to scan this QR code and complete the first trust exchange.'**
  String get scanPeerQrDesktopHelp;

  /// No description provided for @scanQrAndConnectAction.
  ///
  /// In en, this message translates to:
  /// **'Scan QR and Connect'**
  String get scanQrAndConnectAction;

  /// No description provided for @scanOnAnotherDeviceAction.
  ///
  /// In en, this message translates to:
  /// **'Scan on Another Device'**
  String get scanOnAnotherDeviceAction;

  /// No description provided for @savedContactsTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved Contacts'**
  String get savedContactsTitle;

  /// No description provided for @savedContactsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Trusted devices appear here after the first QR scan.'**
  String get savedContactsEmpty;

  /// No description provided for @blockedContactsCannotStartSession.
  ///
  /// In en, this message translates to:
  /// **'Blocked contacts cannot start a peer session.'**
  String get blockedContactsCannotStartSession;

  /// No description provided for @scanQrNotAvailableOnWindows.
  ///
  /// In en, this message translates to:
  /// **'QR scanning is not available on Windows. Use another GungChat device with a camera to scan this code.'**
  String get scanQrNotAvailableOnWindows;

  /// No description provided for @scanDeviceBeforeConnect.
  ///
  /// In en, this message translates to:
  /// **'Scan a GungChat QR code before trying to connect.'**
  String get scanDeviceBeforeConnect;

  /// No description provided for @qrMissingLanAddress.
  ///
  /// In en, this message translates to:
  /// **'This QR code does not include a usable LAN address yet. Open the QR page on the other device again and rescan it.'**
  String get qrMissingLanAddress;

  /// No description provided for @trustedConnectingLabel.
  ///
  /// In en, this message translates to:
  /// **'Trusted. Connecting automatically over LAN:'**
  String get trustedConnectingLabel;

  /// No description provided for @connectingAutomaticallyLabel.
  ///
  /// In en, this message translates to:
  /// **'Connecting automatically to'**
  String get connectingAutomaticallyLabel;

  /// No description provided for @qrConnectionFailedLabel.
  ///
  /// In en, this message translates to:
  /// **'QR connection failed'**
  String get qrConnectionFailedLabel;

  /// No description provided for @organizationTitle.
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get organizationTitle;

  /// No description provided for @organizationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage labels, private notes, and notification state for this contact.'**
  String get organizationSubtitle;

  /// No description provided for @labelsTitle.
  ///
  /// In en, this message translates to:
  /// **'Labels'**
  String get labelsTitle;

  /// No description provided for @noLabelsCreatedYet.
  ///
  /// In en, this message translates to:
  /// **'No labels created yet.'**
  String get noLabelsCreatedYet;

  /// No description provided for @newLabelLabel.
  ///
  /// In en, this message translates to:
  /// **'New label'**
  String get newLabelLabel;

  /// No description provided for @createLabelAction.
  ///
  /// In en, this message translates to:
  /// **'Create label'**
  String get createLabelAction;

  /// No description provided for @privateNotesTitle.
  ///
  /// In en, this message translates to:
  /// **'Private notes'**
  String get privateNotesTitle;

  /// No description provided for @noPrivateNotesYet.
  ///
  /// In en, this message translates to:
  /// **'No private notes for this contact yet.'**
  String get noPrivateNotesYet;

  /// No description provided for @updatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get updatedLabel;

  /// No description provided for @deleteNoteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete note'**
  String get deleteNoteTooltip;

  /// No description provided for @addPrivateNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Add private note'**
  String get addPrivateNoteLabel;

  /// No description provided for @saveNoteAction.
  ///
  /// In en, this message translates to:
  /// **'Save note'**
  String get saveNoteAction;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @mutedUntilManualUnmute.
  ///
  /// In en, this message translates to:
  /// **'Muted until you manually unmute it.'**
  String get mutedUntilManualUnmute;

  /// No description provided for @snoozedUntilLabel.
  ///
  /// In en, this message translates to:
  /// **'Snoozed until'**
  String get snoozedUntilLabel;

  /// No description provided for @notificationsActiveForContact.
  ///
  /// In en, this message translates to:
  /// **'Notifications are active for this contact.'**
  String get notificationsActiveForContact;

  /// No description provided for @muteAction.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get muteAction;

  /// No description provided for @unmuteAction.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get unmuteAction;

  /// No description provided for @snooze1hAction.
  ///
  /// In en, this message translates to:
  /// **'Snooze 1h'**
  String get snooze1hAction;

  /// No description provided for @snooze8hAction.
  ///
  /// In en, this message translates to:
  /// **'Snooze 8h'**
  String get snooze8hAction;

  /// No description provided for @trustedChip.
  ///
  /// In en, this message translates to:
  /// **'Trusted'**
  String get trustedChip;

  /// No description provided for @blockedChip.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get blockedChip;

  /// No description provided for @selectedChip.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selectedChip;

  /// No description provided for @lanDiscoveredChip.
  ///
  /// In en, this message translates to:
  /// **'LAN discovered'**
  String get lanDiscoveredChip;

  /// No description provided for @scanQrFirstChip.
  ///
  /// In en, this message translates to:
  /// **'Scan QR first'**
  String get scanQrFirstChip;

  /// No description provided for @manageAction.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manageAction;

  /// No description provided for @openInChatAction.
  ///
  /// In en, this message translates to:
  /// **'Open In Chat'**
  String get openInChatAction;

  /// No description provided for @connectAction.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connectAction;

  /// No description provided for @needsQrAction.
  ///
  /// In en, this message translates to:
  /// **'Needs QR'**
  String get needsQrAction;

  /// No description provided for @unblockAction.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblockAction;

  /// No description provided for @blockAction.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get blockAction;

  /// No description provided for @seenLabel.
  ///
  /// In en, this message translates to:
  /// **'Seen'**
  String get seenLabel;

  /// No description provided for @blockedLabel.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get blockedLabel;

  /// No description provided for @unblockedLabel.
  ///
  /// In en, this message translates to:
  /// **'Unblocked'**
  String get unblockedLabel;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @appearanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceTitle;

  /// No description provided for @themeModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme mode'**
  String get themeModeLabel;

  /// No description provided for @themeModeAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get themeModeAuto;

  /// No description provided for @themeModeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeModeLight;

  /// No description provided for @themeModeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeModeDark;

  /// No description provided for @keyboardShortcutThemeHint.
  ///
  /// In en, this message translates to:
  /// **'Keyboard shortcut: Ctrl+Shift+D cycles between Auto, Light, and Dark.'**
  String get keyboardShortcutThemeHint;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageChineseSimplified.
  ///
  /// In en, this message translates to:
  /// **'Chinese (Simplified)'**
  String get languageChineseSimplified;

  /// No description provided for @languageChineseTraditional.
  ///
  /// In en, this message translates to:
  /// **'Chinese (Traditional)'**
  String get languageChineseTraditional;

  /// No description provided for @languageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get languageSpanish;

  /// No description provided for @languageFrench.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get languageFrench;

  /// No description provided for @languageChangeHelp.
  ///
  /// In en, this message translates to:
  /// **'Applies immediately. Choose System default to follow your device language.'**
  String get languageChangeHelp;

  /// No description provided for @quickReplyTemplatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick reply templates'**
  String get quickReplyTemplatesTitle;

  /// No description provided for @shortcodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Shortcode'**
  String get shortcodeLabel;

  /// No description provided for @templateTextLabel.
  ///
  /// In en, this message translates to:
  /// **'Template text'**
  String get templateTextLabel;

  /// No description provided for @saveTemplateAction.
  ///
  /// In en, this message translates to:
  /// **'Save template'**
  String get saveTemplateAction;

  /// No description provided for @noQuickRepliesYet.
  ///
  /// In en, this message translates to:
  /// **'No quick replies saved yet. Create one here, then type its shortcode in chat to insert it instantly.'**
  String get noQuickRepliesYet;

  /// No description provided for @usedLabel.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get usedLabel;

  /// No description provided for @timeSingular.
  ///
  /// In en, this message translates to:
  /// **'time'**
  String get timeSingular;

  /// No description provided for @timePlural.
  ///
  /// In en, this message translates to:
  /// **'times'**
  String get timePlural;

  /// No description provided for @deleteTemplateTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete template'**
  String get deleteTemplateTooltip;

  /// No description provided for @quickRepliesLoadFailedLabel.
  ///
  /// In en, this message translates to:
  /// **'Could not load quick replies'**
  String get quickRepliesLoadFailedLabel;

  /// No description provided for @quickReplySavedLabel.
  ///
  /// In en, this message translates to:
  /// **'Quick reply saved'**
  String get quickReplySavedLabel;

  /// No description provided for @quickReplyDeletedLabel.
  ///
  /// In en, this message translates to:
  /// **'Quick reply deleted'**
  String get quickReplyDeletedLabel;

  /// No description provided for @customStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom status'**
  String get customStatusTitle;

  /// No description provided for @statusTextLabel.
  ///
  /// In en, this message translates to:
  /// **'Status text'**
  String get statusTextLabel;

  /// No description provided for @statusTextHint.
  ///
  /// In en, this message translates to:
  /// **'In a meeting, Do not disturb, Available later...'**
  String get statusTextHint;

  /// No description provided for @customStatusHelp.
  ///
  /// In en, this message translates to:
  /// **'This text is shared directly with the active peer session alongside your presence status.'**
  String get customStatusHelp;

  /// No description provided for @screenshotProtectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Screenshot protection'**
  String get screenshotProtectionTitle;

  /// No description provided for @screenshotProtectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Android now enables secure windows. iOS and desktop recording detection still need platform-specific follow-up.'**
  String get screenshotProtectionSubtitle;

  /// No description provided for @readReceiptsTitle.
  ///
  /// In en, this message translates to:
  /// **'Read receipts'**
  String get readReceiptsTitle;

  /// No description provided for @readReceiptsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Opt in to send encrypted read confirmations when you open a conversation and view delivered messages.'**
  String get readReceiptsSubtitle;

  /// No description provided for @linkPreviewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Link previews'**
  String get linkPreviewsTitle;

  /// No description provided for @linkPreviewsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Off by default for privacy. Enabling previews lets your device fetch webpage metadata directly, which can reveal your IP address to those sites.'**
  String get linkPreviewsSubtitle;

  /// No description provided for @presenceStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Presence status'**
  String get presenceStatusTitle;

  /// No description provided for @sharedPresenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Shared presence'**
  String get sharedPresenceLabel;

  /// No description provided for @presenceOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get presenceOnline;

  /// No description provided for @presenceAway.
  ///
  /// In en, this message translates to:
  /// **'Away'**
  String get presenceAway;

  /// No description provided for @presenceHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get presenceHidden;

  /// No description provided for @sharedPresenceHelp.
  ///
  /// In en, this message translates to:
  /// **'Online is shared while the app is in the foreground and automatically falls back to Away in the background. Hidden suppresses your presence updates.'**
  String get sharedPresenceHelp;

  /// No description provided for @notificationPreferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification preferences'**
  String get notificationPreferencesTitle;

  /// No description provided for @notificationMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get notificationMessages;

  /// No description provided for @notificationCalls.
  ///
  /// In en, this message translates to:
  /// **'Calls'**
  String get notificationCalls;

  /// No description provided for @notificationPresenceChanges.
  ///
  /// In en, this message translates to:
  /// **'Presence changes'**
  String get notificationPresenceChanges;

  /// No description provided for @notificationConnectionRequests.
  ///
  /// In en, this message translates to:
  /// **'Connection requests'**
  String get notificationConnectionRequests;

  /// No description provided for @notificationReactions.
  ///
  /// In en, this message translates to:
  /// **'Reactions'**
  String get notificationReactions;

  /// No description provided for @notificationSound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get notificationSound;

  /// No description provided for @notificationVibrate.
  ///
  /// In en, this message translates to:
  /// **'Vibrate'**
  String get notificationVibrate;

  /// No description provided for @keyboardShortcutsTitle.
  ///
  /// In en, this message translates to:
  /// **'Keyboard shortcuts'**
  String get keyboardShortcutsTitle;

  /// No description provided for @shortcutOpenQuickSearch.
  ///
  /// In en, this message translates to:
  /// **'Open quick search'**
  String get shortcutOpenQuickSearch;

  /// No description provided for @shortcutCycleThemeMode.
  ///
  /// In en, this message translates to:
  /// **'Cycle theme mode'**
  String get shortcutCycleThemeMode;

  /// No description provided for @shortcutNextTab.
  ///
  /// In en, this message translates to:
  /// **'Move to the next app tab'**
  String get shortcutNextTab;

  /// No description provided for @shortcutPreviousTab.
  ///
  /// In en, this message translates to:
  /// **'Move to the previous app tab'**
  String get shortcutPreviousTab;

  /// No description provided for @shortcutFocusComposer.
  ///
  /// In en, this message translates to:
  /// **'Focus the active chat composer'**
  String get shortcutFocusComposer;

  /// No description provided for @shortcutMuteConversation.
  ///
  /// In en, this message translates to:
  /// **'Mute the selected conversation'**
  String get shortcutMuteConversation;

  /// No description provided for @appLockTitle.
  ///
  /// In en, this message translates to:
  /// **'App lock'**
  String get appLockTitle;

  /// No description provided for @requireUnlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Require biometric or device unlock'**
  String get requireUnlockTitle;

  /// No description provided for @requireUnlockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When enabled, GungChat prompts for device authentication on launch and after returning from the background.'**
  String get requireUnlockSubtitle;

  /// No description provided for @relockAfterLabel.
  ///
  /// In en, this message translates to:
  /// **'Re-lock after'**
  String get relockAfterLabel;

  /// No description provided for @secondUnit.
  ///
  /// In en, this message translates to:
  /// **'second'**
  String get secondUnit;

  /// No description provided for @secondsUnit.
  ///
  /// In en, this message translates to:
  /// **'seconds'**
  String get secondsUnit;

  /// No description provided for @minuteUnit.
  ///
  /// In en, this message translates to:
  /// **'minute'**
  String get minuteUnit;

  /// No description provided for @minutesUnit.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutesUnit;

  /// No description provided for @accessibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get accessibilityTitle;

  /// No description provided for @reducedMotionLabel.
  ///
  /// In en, this message translates to:
  /// **'Reduced motion'**
  String get reducedMotionLabel;

  /// No description provided for @highContrastLabel.
  ///
  /// In en, this message translates to:
  /// **'High contrast'**
  String get highContrastLabel;

  /// No description provided for @onValue.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get onValue;

  /// No description provided for @offValue.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get offValue;

  /// No description provided for @accessibilitySummary.
  ///
  /// In en, this message translates to:
  /// **'This phase uses 48dp minimum touch targets, screen-reader announcements for key actions, and keyboard shortcut discovery surfaces.'**
  String get accessibilitySummary;

  /// No description provided for @burnAfterReadDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Burn after read default'**
  String get burnAfterReadDefaultTitle;

  /// No description provided for @burnAfterReadDefaultSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The chat bootstrap flow already assumes ephemeral-first messaging.'**
  String get burnAfterReadDefaultSubtitle;

  /// No description provided for @antiSurveillanceGuardTitle.
  ///
  /// In en, this message translates to:
  /// **'Anti-surveillance guard'**
  String get antiSurveillanceGuardTitle;

  /// No description provided for @antiSurveillanceGuardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Transport is in place. Next platform work is expanding recording detection and privacy guard behavior beyond Android secure windows.'**
  String get antiSurveillanceGuardSubtitle;

  /// No description provided for @selectContactToStartVideoCall.
  ///
  /// In en, this message translates to:
  /// **'Select a contact to start a video call'**
  String get selectContactToStartVideoCall;

  /// No description provided for @blockedContactsCannotBeCalled.
  ///
  /// In en, this message translates to:
  /// **'Blocked contacts cannot be called'**
  String get blockedContactsCannotBeCalled;

  /// No description provided for @contactNeedsLanBeforeCall.
  ///
  /// In en, this message translates to:
  /// **'This contact needs a LAN address before you can call them'**
  String get contactNeedsLanBeforeCall;

  /// No description provided for @startVideoCallTooltip.
  ///
  /// In en, this message translates to:
  /// **'Start video call'**
  String get startVideoCallTooltip;

  /// No description provided for @videoCallAlreadyInProgress.
  ///
  /// In en, this message translates to:
  /// **'A video call is already in progress'**
  String get videoCallAlreadyInProgress;

  /// No description provided for @secureChannelOpen.
  ///
  /// In en, this message translates to:
  /// **'Secure channel open'**
  String get secureChannelOpen;

  /// No description provided for @chooseContactFromContacts.
  ///
  /// In en, this message translates to:
  /// **'Choose a contact from Contacts'**
  String get chooseContactFromContacts;

  /// No description provided for @isBlockedSuffix.
  ///
  /// In en, this message translates to:
  /// **'is blocked'**
  String get isBlockedSuffix;

  /// No description provided for @readyToConnect.
  ///
  /// In en, this message translates to:
  /// **'Ready to connect'**
  String get readyToConnect;

  /// No description provided for @connectionDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Connection Details'**
  String get connectionDetailsTitle;

  /// No description provided for @connectionDetailsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Connection details'**
  String get connectionDetailsTooltip;

  /// No description provided for @videoCallCouldNotStartLabel.
  ///
  /// In en, this message translates to:
  /// **'Video call could not start'**
  String get videoCallCouldNotStartLabel;

  /// No description provided for @noMessagesYetBootstrap.
  ///
  /// In en, this message translates to:
  /// **'No messages yet. Save a local bootstrap message or select a peer contact.'**
  String get noMessagesYetBootstrap;

  /// No description provided for @noMessagesYetPeer.
  ///
  /// In en, this message translates to:
  /// **'No messages yet for this peer. Finish signaling to start the secure conversation.'**
  String get noMessagesYetPeer;

  /// No description provided for @messageLoadFailedLabel.
  ///
  /// In en, this message translates to:
  /// **'Message load failed'**
  String get messageLoadFailedLabel;

  /// No description provided for @conversationLabel.
  ///
  /// In en, this message translates to:
  /// **'Conversation'**
  String get conversationLabel;

  /// No description provided for @localBootstrapCache.
  ///
  /// In en, this message translates to:
  /// **'local bootstrap cache'**
  String get localBootstrapCache;

  /// No description provided for @waitingForSecureChannel.
  ///
  /// In en, this message translates to:
  /// **'waiting for secure channel'**
  String get waitingForSecureChannel;

  /// No description provided for @peerCustomStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Peer custom status'**
  String get peerCustomStatusLabel;

  /// No description provided for @yourCustomStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Your custom status'**
  String get yourCustomStatusLabel;

  /// No description provided for @blockedContactWarning.
  ///
  /// In en, this message translates to:
  /// **'This contact is blocked. Unblock them in Contacts before continuing peer messaging.'**
  String get blockedContactWarning;

  /// No description provided for @replyingToYourself.
  ///
  /// In en, this message translates to:
  /// **'Replying to yourself'**
  String get replyingToYourself;

  /// No description provided for @replyingToPeer.
  ///
  /// In en, this message translates to:
  /// **'Replying to peer'**
  String get replyingToPeer;

  /// No description provided for @cancelReplyTooltip.
  ///
  /// In en, this message translates to:
  /// **'Cancel reply'**
  String get cancelReplyTooltip;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'fr', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'TW':
            return AppLocalizationsZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
