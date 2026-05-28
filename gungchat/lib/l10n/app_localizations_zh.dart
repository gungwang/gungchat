// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '敢说';

  @override
  String get chatTab => '聊天';

  @override
  String get contactsTab => '联系人';

  @override
  String get settingsTab => '设置';

  @override
  String get quickSearchTitle => '快速搜索';

  @override
  String get searchContactsLabel => '搜索联系人';

  @override
  String get searchContactsHint => '姓名或指纹';

  @override
  String get noContactsMatchSearch => '没有匹配的联系人。';

  @override
  String get closeAction => '关闭';

  @override
  String get openedChatForLabel => '已打开聊天：';

  @override
  String get mutedAnnouncementLabel => '已静音：';

  @override
  String get unmutedAnnouncementLabel => '已取消静音：';

  @override
  String get themeChangedToLabel => '主题已切换为';

  @override
  String get appLockedTitle => 'GungChat 已锁定';

  @override
  String get unlockPrompt => '使用设备凭据解锁以继续。';

  @override
  String get unlockingAction => '解锁中...';

  @override
  String get unlockAction => '解锁';

  @override
  String get openAction => '打开';

  @override
  String get discoveryTitle => '发现';

  @override
  String get discoverySubtitle => '扫描一次即可建立信任。首次二维码交换完成后，双方都可以一键重新连接。';

  @override
  String get activeChatTargetLabel => '当前聊天目标';

  @override
  String get yourConnectQrTitle => '你的连接二维码';

  @override
  String get yourConnectQrHelp =>
      '在另一台设备上打开此页面并扫描此二维码。GungChat 将自动交换身份并通过局域网连接。';

  @override
  String get displayNameLabel => '显示名称';

  @override
  String get contactCardUnavailableLabel => '联系人卡片不可用';

  @override
  String get identityUnavailableLabel => '身份不可用';

  @override
  String get fingerprintLabel => '指纹';

  @override
  String get noLanAddressesDetected => '尚未检测到局域网地址。';

  @override
  String get lanAddressesLabel => '局域网地址';

  @override
  String get keepQrVisibleHint => '保持此二维码可见，直到另一台设备完成扫描并开始连接。';

  @override
  String get scanPeerQrTitle => '扫描对方二维码';

  @override
  String get scanPeerQrCameraHelp =>
      '使用本设备摄像头扫描另一台 GungChat 设备的二维码。首次扫描会自动建立受信任连接。';

  @override
  String get scanPeerQrDesktopHelp =>
      '此设备无法扫描二维码。请使用另一台带摄像头的 GungChat 设备扫描此二维码以完成首次信任交换。';

  @override
  String get scanQrAndConnectAction => '扫码并连接';

  @override
  String get scanOnAnotherDeviceAction => '在其他设备上扫描';

  @override
  String get savedContactsTitle => '已保存联系人';

  @override
  String get savedContactsEmpty => '首次扫描二维码后，受信任的设备会显示在这里。';

  @override
  String get blockedContactsCannotStartSession => '已屏蔽的联系人无法启动点对点会话。';

  @override
  String get scanQrNotAvailableOnWindows =>
      'Windows 不支持二维码扫描。请使用另一台带摄像头的 GungChat 设备扫描此二维码。';

  @override
  String get scanDeviceBeforeConnect => '连接前请先扫描 GungChat 二维码。';

  @override
  String get qrMissingLanAddress => '此二维码还不包含可用的局域网地址。请在另一台设备上重新打开二维码页面后再扫描一次。';

  @override
  String get trustedConnectingLabel => '已信任，正在通过局域网自动连接：';

  @override
  String get connectingAutomaticallyLabel => '正在自动连接到';

  @override
  String get qrConnectionFailedLabel => '二维码连接失败';

  @override
  String get organizationTitle => '组织管理';

  @override
  String get organizationSubtitle => '管理此联系人的标签、私有备注和通知状态。';

  @override
  String get labelsTitle => '标签';

  @override
  String get noLabelsCreatedYet => '尚未创建标签。';

  @override
  String get newLabelLabel => '新标签';

  @override
  String get createLabelAction => '创建标签';

  @override
  String get privateNotesTitle => '私有备注';

  @override
  String get noPrivateNotesYet => '该联系人还没有私有备注。';

  @override
  String get updatedLabel => '更新于';

  @override
  String get deleteNoteTooltip => '删除备注';

  @override
  String get addPrivateNoteLabel => '添加私有备注';

  @override
  String get saveNoteAction => '保存备注';

  @override
  String get notificationsTitle => '通知';

  @override
  String get mutedUntilManualUnmute => '已静音，直到你手动取消静音。';

  @override
  String get snoozedUntilLabel => '暂停提醒至';

  @override
  String get notificationsActiveForContact => '此联系人的通知当前处于开启状态。';

  @override
  String get muteAction => '静音';

  @override
  String get unmuteAction => '取消静音';

  @override
  String get snooze1hAction => '暂停 1 小时';

  @override
  String get snooze8hAction => '暂停 8 小时';

  @override
  String get trustedChip => '已信任';

  @override
  String get blockedChip => '已屏蔽';

  @override
  String get selectedChip => '已选中';

  @override
  String get lanDiscoveredChip => '已通过局域网发现';

  @override
  String get scanQrFirstChip => '先扫描二维码';

  @override
  String get manageAction => '管理';

  @override
  String get openInChatAction => '在聊天中打开';

  @override
  String get connectAction => '连接';

  @override
  String get needsQrAction => '需要二维码';

  @override
  String get unblockAction => '取消屏蔽';

  @override
  String get blockAction => '屏蔽';

  @override
  String get seenLabel => '最近看到';

  @override
  String get blockedLabel => '已屏蔽';

  @override
  String get unblockedLabel => '已取消屏蔽';

  @override
  String get settingsTitle => '设置';

  @override
  String get appearanceTitle => '外观';

  @override
  String get themeModeLabel => '主题模式';

  @override
  String get themeModeAuto => '跟随系统';

  @override
  String get themeModeLight => '浅色';

  @override
  String get themeModeDark => '深色';

  @override
  String get keyboardShortcutThemeHint =>
      '键盘快捷键：Ctrl+Shift+D 可在跟随系统、浅色和深色之间切换。';

  @override
  String get languageLabel => '语言';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get languageEnglish => '英语';

  @override
  String get languageChineseSimplified => '简体中文';

  @override
  String get languageChineseTraditional => '繁体中文';

  @override
  String get languageSpanish => '西班牙语';

  @override
  String get languageFrench => '法语';

  @override
  String get languageChangeHelp => '立即生效。选择“跟随系统”可使用设备语言。';

  @override
  String get quickReplyTemplatesTitle => '快捷回复模板';

  @override
  String get shortcodeLabel => '短代码';

  @override
  String get templateTextLabel => '模板文本';

  @override
  String get saveTemplateAction => '保存模板';

  @override
  String get noQuickRepliesYet => '尚未保存快捷回复。在这里创建后，在聊天中输入其短代码即可立即插入。';

  @override
  String get usedLabel => '已使用';

  @override
  String get timeSingular => '次';

  @override
  String get timePlural => '次';

  @override
  String get deleteTemplateTooltip => '删除模板';

  @override
  String get quickRepliesLoadFailedLabel => '无法加载快捷回复';

  @override
  String get quickReplySavedLabel => '快捷回复已保存';

  @override
  String get quickReplyDeletedLabel => '快捷回复已删除';

  @override
  String get customStatusTitle => '自定义状态';

  @override
  String get statusTextLabel => '状态文本';

  @override
  String get statusTextHint => '开会中、请勿打扰、稍后可用...';

  @override
  String get customStatusHelp => '此文本会和你的在线状态一起直接共享给当前活跃的点对点会话。';

  @override
  String get screenshotProtectionTitle => '截图保护';

  @override
  String get screenshotProtectionSubtitle =>
      'Android 现已启用安全窗口。iOS 和桌面端的录屏检测仍需后续平台适配。';

  @override
  String get readReceiptsTitle => '已读回执';

  @override
  String get readReceiptsSubtitle => '开启后，当你打开会话并查看已送达消息时，会发送加密的已读确认。';

  @override
  String get linkPreviewsTitle => '链接预览';

  @override
  String get linkPreviewsSubtitle =>
      '为了隐私默认关闭。启用后，设备会直接抓取网页元数据，这可能会向目标网站暴露你的 IP 地址。';

  @override
  String get presenceStatusTitle => '在线状态';

  @override
  String get sharedPresenceLabel => '共享状态';

  @override
  String get presenceOnline => '在线';

  @override
  String get presenceAway => '离开';

  @override
  String get presenceHidden => '隐身';

  @override
  String get sharedPresenceHelp =>
      '当应用位于前台时会共享“在线”，切到后台时会自动变为“离开”。“隐身”会停止发送在线状态更新。';

  @override
  String get notificationPreferencesTitle => '通知偏好';

  @override
  String get notificationMessages => '消息';

  @override
  String get notificationCalls => '通话';

  @override
  String get notificationPresenceChanges => '在线状态变化';

  @override
  String get notificationConnectionRequests => '连接请求';

  @override
  String get notificationReactions => '表情回应';

  @override
  String get notificationSound => '声音';

  @override
  String get notificationVibrate => '震动';

  @override
  String get keyboardShortcutsTitle => '键盘快捷键';

  @override
  String get shortcutOpenQuickSearch => '打开快速搜索';

  @override
  String get shortcutCycleThemeMode => '切换主题模式';

  @override
  String get shortcutNextTab => '切换到下一个标签页';

  @override
  String get shortcutPreviousTab => '切换到上一个标签页';

  @override
  String get shortcutFocusComposer => '聚焦当前聊天输入框';

  @override
  String get shortcutMuteConversation => '将所选会话静音';

  @override
  String get appLockTitle => '应用锁';

  @override
  String get requireUnlockTitle => '需要生物识别或设备解锁';

  @override
  String get requireUnlockSubtitle => '启用后，GungChat 会在启动时以及从后台返回时请求设备身份验证。';

  @override
  String get relockAfterLabel => '重新锁定时间';

  @override
  String get secondUnit => '秒';

  @override
  String get secondsUnit => '秒';

  @override
  String get minuteUnit => '分钟';

  @override
  String get minutesUnit => '分钟';

  @override
  String get accessibilityTitle => '无障碍';

  @override
  String get reducedMotionLabel => '减少动画';

  @override
  String get highContrastLabel => '高对比度';

  @override
  String get onValue => '开';

  @override
  String get offValue => '关';

  @override
  String get accessibilitySummary =>
      '当前阶段已采用 48dp 最小触控目标、关键操作的屏幕阅读器播报，以及键盘快捷键发现入口。';

  @override
  String get burnAfterReadDefaultTitle => '默认阅后即焚';

  @override
  String get burnAfterReadDefaultSubtitle => '聊天引导流程已经默认采用“先阅后焚”的消息方式。';

  @override
  String get antiSurveillanceGuardTitle => '反监控保护';

  @override
  String get antiSurveillanceGuardSubtitle =>
      '传输层已就绪。下一步的平台工作是把录屏检测和隐私保护行为扩展到 Android 安全窗口之外。';

  @override
  String get selectContactToStartVideoCall => '请选择联系人以发起视频通话';

  @override
  String get blockedContactsCannotBeCalled => '已屏蔽的联系人无法呼叫';

  @override
  String get contactNeedsLanBeforeCall => '该联系人需要先有局域网地址后才能呼叫';

  @override
  String get startVideoCallTooltip => '发起视频通话';

  @override
  String get videoCallAlreadyInProgress => '当前已有视频通话正在进行';

  @override
  String get secureChannelOpen => '安全通道已打开';

  @override
  String get chooseContactFromContacts => '从联系人中选择一个联系人';

  @override
  String get isBlockedSuffix => '已被屏蔽';

  @override
  String get readyToConnect => '准备连接';

  @override
  String get connectionDetailsTitle => '连接详情';

  @override
  String get connectionDetailsTooltip => '连接详情';

  @override
  String get videoCallCouldNotStartLabel => '无法发起视频通话';

  @override
  String get noMessagesYetBootstrap => '还没有消息。保存一条本地引导消息，或选择一个联系人。';

  @override
  String get noMessagesYetPeer => '该联系人还没有消息。完成信令交换后即可开始安全会话。';

  @override
  String get messageLoadFailedLabel => '加载消息失败';

  @override
  String get conversationLabel => '会话';

  @override
  String get localBootstrapCache => '本地引导缓存';

  @override
  String get waitingForSecureChannel => '等待安全通道';

  @override
  String get peerCustomStatusLabel => '对方自定义状态';

  @override
  String get yourCustomStatusLabel => '你的自定义状态';

  @override
  String get blockedContactWarning => '该联系人已被屏蔽。继续点对点消息前，请先在联系人中取消屏蔽。';

  @override
  String get replyingToYourself => '正在回复自己';

  @override
  String get replyingToPeer => '正在回复对方';

  @override
  String get cancelReplyTooltip => '取消回复';

  @override
  String get composerSendAction => '发送';

  @override
  String get composerSaveLocalAction => '保存本地消息';

  @override
  String get composerWaitForSecureChannel => '等待安全通道';

  @override
  String get composerSaveMessageEditAction => '保存修改';

  @override
  String get composerConnectAction => '连接';

  @override
  String get composerBurnAfterReadLabel => '阅后即焚';

  @override
  String get composerRecordVoiceTooltip => '录制语音';

  @override
  String get composerStopAndSendVoiceTooltip => '停止并发送语音';

  @override
  String get composerMoreActionsTooltip => '更多操作';

  @override
  String get composerBootstrapHint => '输入本地加密消息草稿...';

  @override
  String get composerPeerHint => '输入要发送给对方的加密消息...';

  @override
  String get composerEditHint => '修改这条加密消息...';

  @override
  String get composerHelpHint => '输入 /help 查看本地命令，或完成信令交换后即可发送。';

  @override
  String get composerBlockedHint => '该联系人已被屏蔽。斜杠命令仍可本地执行。';

  @override
  String get composerOpenSessionForStickers => '发送贴纸前请先建立安全会话。';

  @override
  String get composerFinishSignalExchangeWarning => '发送点对点消息前请先完成信令交换。';

  @override
  String composerOpenSessionBeforeSend(Object name) {
    return '发送前请先与 $name 建立或接受会话。';
  }

  @override
  String get composerRecordingHint => '正在录制语音...准备好后点击 停止并发送。最长 2 分钟。';

  @override
  String get composerOpenChannelBeforeRecording => '录制语音前请先打开安全通道。';

  @override
  String get composerMicrophoneError => '无法访问麦克风。请检查应用权限和设备麦克风设置。';

  @override
  String get composerEditLabel => '编辑安全消息';

  @override
  String get composerSecureLabel => '安全对端消息';

  @override
  String get composerBootstrapLabel => '引导消息';

  @override
  String get composerPeerLabel => '对端消息';

  @override
  String composerTypingStatus(Object name) {
    return '$name 正在输入...';
  }

  @override
  String get attachmentMenuGallery => '图库';

  @override
  String get attachmentMenuFiles => '文件';

  @override
  String get attachmentMenuLocation => '位置';

  @override
  String get attachmentMenuContact => '联系人';

  @override
  String get attachmentMenuSticker => '贴纸';

  @override
  String get stickerPickerTitle => '贴纸';

  @override
  String get stickerLabelSmile => '微笑';

  @override
  String get stickerLabelHeart => '爱心';

  @override
  String get stickerLabelThumbs => '点赞';

  @override
  String get stickerLabelParty => '庆祝';

  @override
  String get stickerLabelFire => '火';

  @override
  String get stickerLabelSad => '难过';

  @override
  String get stickerLabelOk => 'OK';

  @override
  String get stickerLabelClap => '鼓掌';

  @override
  String get messageBubbleQuotedMessage => '引用消息';

  @override
  String get messageBubbleStarTooltip => '标星消息';

  @override
  String get messageBubbleRemoveStarTooltip => '取消标星';

  @override
  String get messageBubbleActionsTooltip => '消息操作';

  @override
  String get messageBubbleEditAction => '编辑消息';

  @override
  String get messageBubbleDeleteForEveryoneAction => '为所有人删除';

  @override
  String get messageBubbleErasePermanentlyAction => '永久抹除';

  @override
  String get messageBubbleAddReactionTooltip => '添加反应';

  @override
  String get messageBubbleMessageDeletedLabel => '消息已删除';

  @override
  String get messageBubbleBurnAfterReadBadge => '阅后即焚';

  @override
  String get messageBubblePersistentBadge => '持久保存';

  @override
  String get messageBubbleDeletedMarker => '已删除';

  @override
  String get messageBubbleEditedMarker => '已编辑';

  @override
  String get messageBubbleSpoilerLabel => '剧透';

  @override
  String get messageBubbleSpoilerHint => '剧透内容，点击显示';

  @override
  String get messageBubblePlayVoiceTooltip => '播放语音消息';

  @override
  String get messageBubbleStopVoiceTooltip => '停止语音消息';

  @override
  String get messageBubbleVoiceMessageLabel => '语音消息';

  @override
  String get messageBubbleSharedLocationLabel => '共享位置';

  @override
  String get messageBubbleSharedContactLabel => '共享联系人';

  @override
  String messageBubbleLatLngLabel(Object lat, Object lng) {
    return '纬度 $lat，经度 $lng';
  }

  @override
  String get messageBubbleLoadingLinkPreview => '正在加载链接预览...';

  @override
  String get messageBubbleAttachmentSentAnnouncement => '附件已发送';

  @override
  String get messageBubbleQuickReplyInsertedAnnouncement => '已插入快捷回复';

  @override
  String get messageBubbleDialogCancel => '取消';

  @override
  String get messageBubbleDialogClose => '关闭';

  @override
  String get messageBubbleDeleteForEveryoneTitle => '为所有人删除这条消息？';

  @override
  String get messageBubbleDeleteForEveryoneBody => '会话中会显示一个已删除占位符替代该消息。';

  @override
  String get messageBubbleErasePermanentlyTitle => '永久抹除这条消息？';

  @override
  String get messageBubbleErasePermanentlyBody => '将完全删除该消息记录，而不会显示已删除占位符。';

  @override
  String get messageBubbleEraseLabel => '抹除';

  @override
  String get messageBubbleDeleteLabel => '删除';

  @override
  String get messageBubbleOriginalMessageGone => '原消息已不可用。';
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw() : super('zh_TW');

  @override
  String get appTitle => '敢說';

  @override
  String get chatTab => '聊天';

  @override
  String get contactsTab => '聯絡人';

  @override
  String get settingsTab => '設定';

  @override
  String get quickSearchTitle => '快速搜尋';

  @override
  String get searchContactsLabel => '搜尋聯絡人';

  @override
  String get searchContactsHint => '姓名或指紋';

  @override
  String get noContactsMatchSearch => '沒有符合的聯絡人。';

  @override
  String get closeAction => '關閉';

  @override
  String get openedChatForLabel => '已開啟聊天：';

  @override
  String get mutedAnnouncementLabel => '已靜音：';

  @override
  String get unmutedAnnouncementLabel => '已取消靜音：';

  @override
  String get themeChangedToLabel => '主題已切換為';

  @override
  String get appLockedTitle => 'GungChat 已鎖定';

  @override
  String get unlockPrompt => '使用裝置憑證解鎖以繼續。';

  @override
  String get unlockingAction => '解鎖中...';

  @override
  String get unlockAction => '解鎖';

  @override
  String get openAction => '開啟';

  @override
  String get discoveryTitle => '探索';

  @override
  String get discoverySubtitle => '掃描一次即可建立信任。首次 QR 交換完成後，雙方都可以一鍵重新連線。';

  @override
  String get activeChatTargetLabel => '目前聊天對象';

  @override
  String get yourConnectQrTitle => '你的連線 QR 碼';

  @override
  String get yourConnectQrHelp =>
      '在另一台裝置上開啟此頁面並掃描此 QR 碼。GungChat 會自動交換身分並透過區域網路連線。';

  @override
  String get displayNameLabel => '顯示名稱';

  @override
  String get contactCardUnavailableLabel => '聯絡人卡片不可用';

  @override
  String get identityUnavailableLabel => '身分不可用';

  @override
  String get fingerprintLabel => '指紋';

  @override
  String get noLanAddressesDetected => '尚未偵測到區域網路位址。';

  @override
  String get lanAddressesLabel => '區域網路位址';

  @override
  String get keepQrVisibleHint => '請保持此 QR 碼可見，直到另一台裝置完成掃描並開始連線。';

  @override
  String get scanPeerQrTitle => '掃描對方 QR 碼';

  @override
  String get scanPeerQrCameraHelp =>
      '使用本裝置相機掃描另一台 GungChat 裝置的 QR 碼。首次掃描會自動建立受信任連線。';

  @override
  String get scanPeerQrDesktopHelp =>
      '此裝置無法掃描 QR 碼。請使用另一台具備相機的 GungChat 裝置掃描此 QR 碼以完成首次信任交換。';

  @override
  String get scanQrAndConnectAction => '掃碼並連線';

  @override
  String get scanOnAnotherDeviceAction => '在其他裝置上掃描';

  @override
  String get savedContactsTitle => '已儲存聯絡人';

  @override
  String get savedContactsEmpty => '首次掃描 QR 碼後，受信任裝置會顯示在這裡。';

  @override
  String get blockedContactsCannotStartSession => '已封鎖的聯絡人無法啟動點對點工作階段。';

  @override
  String get scanQrNotAvailableOnWindows =>
      'Windows 不支援 QR 掃描。請使用另一台具備相機的 GungChat 裝置掃描此代碼。';

  @override
  String get scanDeviceBeforeConnect => '連線前請先掃描 GungChat QR 碼。';

  @override
  String get qrMissingLanAddress =>
      '此 QR 碼尚未包含可用的區域網路位址。請在另一台裝置上重新開啟 QR 頁面後再掃描一次。';

  @override
  String get trustedConnectingLabel => '已信任，正在透過區域網路自動連線：';

  @override
  String get connectingAutomaticallyLabel => '正在自動連線到';

  @override
  String get qrConnectionFailedLabel => 'QR 連線失敗';

  @override
  String get organizationTitle => '整理';

  @override
  String get organizationSubtitle => '管理此聯絡人的標籤、私人筆記與通知狀態。';

  @override
  String get labelsTitle => '標籤';

  @override
  String get noLabelsCreatedYet => '尚未建立標籤。';

  @override
  String get newLabelLabel => '新標籤';

  @override
  String get createLabelAction => '建立標籤';

  @override
  String get privateNotesTitle => '私人筆記';

  @override
  String get noPrivateNotesYet => '此聯絡人尚無私人筆記。';

  @override
  String get updatedLabel => '更新於';

  @override
  String get deleteNoteTooltip => '刪除筆記';

  @override
  String get addPrivateNoteLabel => '新增私人筆記';

  @override
  String get saveNoteAction => '儲存筆記';

  @override
  String get notificationsTitle => '通知';

  @override
  String get mutedUntilManualUnmute => '已靜音，直到你手動取消靜音。';

  @override
  String get snoozedUntilLabel => '暫停通知至';

  @override
  String get notificationsActiveForContact => '此聯絡人的通知目前已啟用。';

  @override
  String get muteAction => '靜音';

  @override
  String get unmuteAction => '取消靜音';

  @override
  String get snooze1hAction => '暫停 1 小時';

  @override
  String get snooze8hAction => '暫停 8 小時';

  @override
  String get trustedChip => '已信任';

  @override
  String get blockedChip => '已封鎖';

  @override
  String get selectedChip => '已選取';

  @override
  String get lanDiscoveredChip => '已於區域網路發現';

  @override
  String get scanQrFirstChip => '先掃描 QR 碼';

  @override
  String get manageAction => '管理';

  @override
  String get openInChatAction => '在聊天中開啟';

  @override
  String get connectAction => '連線';

  @override
  String get needsQrAction => '需要 QR';

  @override
  String get unblockAction => '解除封鎖';

  @override
  String get blockAction => '封鎖';

  @override
  String get seenLabel => '最近看到';

  @override
  String get blockedLabel => '已封鎖';

  @override
  String get unblockedLabel => '已解除封鎖';

  @override
  String get settingsTitle => '設定';

  @override
  String get appearanceTitle => '外觀';

  @override
  String get themeModeLabel => '主題模式';

  @override
  String get themeModeAuto => '跟隨系統';

  @override
  String get themeModeLight => '淺色';

  @override
  String get themeModeDark => '深色';

  @override
  String get keyboardShortcutThemeHint =>
      '鍵盤快捷鍵：Ctrl+Shift+D 可在跟隨系統、淺色與深色之間切換。';

  @override
  String get languageLabel => '語言';

  @override
  String get languageSystem => '跟隨系統';

  @override
  String get languageEnglish => '英語';

  @override
  String get languageChineseSimplified => '簡體中文';

  @override
  String get languageChineseTraditional => '繁體中文';

  @override
  String get languageSpanish => '西班牙語';

  @override
  String get languageFrench => '法語';

  @override
  String get languageChangeHelp => '立即生效。選擇「跟隨系統」可使用裝置語言。';

  @override
  String get quickReplyTemplatesTitle => '快速回覆範本';

  @override
  String get shortcodeLabel => '短碼';

  @override
  String get templateTextLabel => '範本文字';

  @override
  String get saveTemplateAction => '儲存範本';

  @override
  String get noQuickRepliesYet => '尚未儲存快速回覆。在這裡建立後，在聊天中輸入其短碼即可立即插入。';

  @override
  String get usedLabel => '已使用';

  @override
  String get timeSingular => '次';

  @override
  String get timePlural => '次';

  @override
  String get deleteTemplateTooltip => '刪除範本';

  @override
  String get quickRepliesLoadFailedLabel => '無法載入快速回覆';

  @override
  String get quickReplySavedLabel => '快速回覆已儲存';

  @override
  String get quickReplyDeletedLabel => '快速回覆已刪除';

  @override
  String get customStatusTitle => '自訂狀態';

  @override
  String get statusTextLabel => '狀態文字';

  @override
  String get statusTextHint => '開會中、請勿打擾、稍後可用...';

  @override
  String get customStatusHelp => '此文字會與你的在線狀態一起直接分享給目前啟用的點對點工作階段。';

  @override
  String get screenshotProtectionTitle => '截圖保護';

  @override
  String get screenshotProtectionSubtitle =>
      'Android 已啟用安全視窗。iOS 與桌面端的錄影偵測仍需後續平台適配。';

  @override
  String get readReceiptsTitle => '已讀回條';

  @override
  String get readReceiptsSubtitle => '啟用後，當你打開對話並查看已送達訊息時，會傳送加密的已讀確認。';

  @override
  String get linkPreviewsTitle => '連結預覽';

  @override
  String get linkPreviewsSubtitle =>
      '為了隱私預設為關閉。啟用預覽後，裝置會直接抓取網頁中繼資料，這可能會向網站暴露你的 IP 位址。';

  @override
  String get presenceStatusTitle => '在線狀態';

  @override
  String get sharedPresenceLabel => '共享狀態';

  @override
  String get presenceOnline => '在線';

  @override
  String get presenceAway => '離開';

  @override
  String get presenceHidden => '隱身';

  @override
  String get sharedPresenceHelp =>
      '當應用程式位於前景時會共享「在線」，切到背景時會自動變為「離開」。「隱身」會停止傳送在線狀態更新。';

  @override
  String get notificationPreferencesTitle => '通知偏好';

  @override
  String get notificationMessages => '訊息';

  @override
  String get notificationCalls => '通話';

  @override
  String get notificationPresenceChanges => '狀態變更';

  @override
  String get notificationConnectionRequests => '連線請求';

  @override
  String get notificationReactions => '表情回應';

  @override
  String get notificationSound => '聲音';

  @override
  String get notificationVibrate => '震動';

  @override
  String get keyboardShortcutsTitle => '鍵盤快捷鍵';

  @override
  String get shortcutOpenQuickSearch => '開啟快速搜尋';

  @override
  String get shortcutCycleThemeMode => '切換主題模式';

  @override
  String get shortcutNextTab => '切換到下一個分頁';

  @override
  String get shortcutPreviousTab => '切換到上一個分頁';

  @override
  String get shortcutFocusComposer => '聚焦目前聊天輸入框';

  @override
  String get shortcutMuteConversation => '將所選對話靜音';

  @override
  String get appLockTitle => '應用程式鎖定';

  @override
  String get requireUnlockTitle => '要求生物辨識或裝置解鎖';

  @override
  String get requireUnlockSubtitle => '啟用後，GungChat 會在啟動以及從背景返回時要求裝置驗證。';

  @override
  String get relockAfterLabel => '重新鎖定時間';

  @override
  String get secondUnit => '秒';

  @override
  String get secondsUnit => '秒';

  @override
  String get minuteUnit => '分鐘';

  @override
  String get minutesUnit => '分鐘';

  @override
  String get accessibilityTitle => '無障礙';

  @override
  String get reducedMotionLabel => '減少動畫';

  @override
  String get highContrastLabel => '高對比';

  @override
  String get onValue => '開';

  @override
  String get offValue => '關';

  @override
  String get accessibilitySummary =>
      '目前階段已採用 48dp 最小觸控目標、關鍵操作的螢幕閱讀器播報，以及鍵盤快捷鍵發現入口。';

  @override
  String get burnAfterReadDefaultTitle => '預設閱後即焚';

  @override
  String get burnAfterReadDefaultSubtitle => '聊天引導流程已預設採用「先閱後焚」的訊息方式。';

  @override
  String get antiSurveillanceGuardTitle => '反監控防護';

  @override
  String get antiSurveillanceGuardSubtitle =>
      '傳輸層已就緒。下一步的平台工作是把錄影偵測與隱私保護行為擴展到 Android 安全視窗之外。';

  @override
  String get selectContactToStartVideoCall => '請選擇聯絡人以發起視訊通話';

  @override
  String get blockedContactsCannotBeCalled => '已封鎖的聯絡人無法撥打';

  @override
  String get contactNeedsLanBeforeCall => '此聯絡人需要先有區域網路位址後才能通話';

  @override
  String get startVideoCallTooltip => '開始視訊通話';

  @override
  String get videoCallAlreadyInProgress => '目前已有視訊通話正在進行';

  @override
  String get secureChannelOpen => '安全通道已開啟';

  @override
  String get chooseContactFromContacts => '從聯絡人中選擇一位聯絡人';

  @override
  String get isBlockedSuffix => '已被封鎖';

  @override
  String get readyToConnect => '準備連線';

  @override
  String get connectionDetailsTitle => '連線詳情';

  @override
  String get connectionDetailsTooltip => '連線詳情';

  @override
  String get videoCallCouldNotStartLabel => '無法開始視訊通話';

  @override
  String get noMessagesYetBootstrap => '目前沒有訊息。請儲存一則本地引導訊息，或選擇一位聯絡人。';

  @override
  String get noMessagesYetPeer => '此聯絡人目前沒有訊息。完成訊號交換後即可開始安全對話。';

  @override
  String get messageLoadFailedLabel => '載入訊息失敗';

  @override
  String get conversationLabel => '對話';

  @override
  String get localBootstrapCache => '本地引導快取';

  @override
  String get waitingForSecureChannel => '等待安全通道';

  @override
  String get peerCustomStatusLabel => '對方自訂狀態';

  @override
  String get yourCustomStatusLabel => '你的自訂狀態';

  @override
  String get blockedContactWarning => '此聯絡人已被封鎖。繼續點對點訊息前，請先在聯絡人中解除封鎖。';

  @override
  String get replyingToYourself => '正在回覆自己';

  @override
  String get replyingToPeer => '正在回覆對方';

  @override
  String get cancelReplyTooltip => '取消回覆';

  @override
  String get composerSendAction => '傳送';

  @override
  String get composerSaveLocalAction => '儲存本地訊息';

  @override
  String get composerWaitForSecureChannel => '等待安全通道';

  @override
  String get composerSaveMessageEditAction => '儲存修改';

  @override
  String get composerConnectAction => '連接';

  @override
  String get composerBurnAfterReadLabel => '閱後即焚';

  @override
  String get composerRecordVoiceTooltip => '錄製語音';

  @override
  String get composerStopAndSendVoiceTooltip => '停止並傳送語音';

  @override
  String get composerMoreActionsTooltip => '更多操作';

  @override
  String get composerBootstrapHint => '輸入本地加密訊息草稿...';

  @override
  String get composerPeerHint => '輸入要傳送給對方的加密訊息...';

  @override
  String get composerEditHint => '修改這條加密訊息...';

  @override
  String get composerHelpHint => '輸入 /help 查看本地指令，或完成信號交換後即可傳送。';

  @override
  String get composerBlockedHint => '該聯絡人已被封鎖。斜線指令仍可本地執行。';

  @override
  String get composerOpenSessionForStickers => '傳送貼圖前請先建立安全會話。';

  @override
  String get composerFinishSignalExchangeWarning => '傳送點對點訊息前請先完成信號交換。';

  @override
  String composerOpenSessionBeforeSend(Object name) {
    return '傳送前請先與 $name 建立或接受會話。';
  }

  @override
  String get composerRecordingHint => '正在錄製語音...準備好後點選 停止並傳送。最長 2 分鐘。';

  @override
  String get composerOpenChannelBeforeRecording => '錄製語音前請先開啟安全通道。';

  @override
  String get composerMicrophoneError => '無法存取麥克風。請檢查應用權限與裝置麥克風設定。';

  @override
  String get composerEditLabel => '編輯安全訊息';

  @override
  String get composerSecureLabel => '安全對端訊息';

  @override
  String get composerBootstrapLabel => '引導訊息';

  @override
  String get composerPeerLabel => '對端訊息';

  @override
  String composerTypingStatus(Object name) {
    return '$name 正在輸入...';
  }

  @override
  String get attachmentMenuGallery => '圖庫';

  @override
  String get attachmentMenuFiles => '檔案';

  @override
  String get attachmentMenuLocation => '位置';

  @override
  String get attachmentMenuContact => '聯絡人';

  @override
  String get attachmentMenuSticker => '貼圖';

  @override
  String get stickerPickerTitle => '貼圖';

  @override
  String get stickerLabelSmile => '微笑';

  @override
  String get stickerLabelHeart => '愛心';

  @override
  String get stickerLabelThumbs => '點讚';

  @override
  String get stickerLabelParty => '慶祝';

  @override
  String get stickerLabelFire => '火';

  @override
  String get stickerLabelSad => '難過';

  @override
  String get stickerLabelOk => 'OK';

  @override
  String get stickerLabelClap => '鼓掌';

  @override
  String get messageBubbleQuotedMessage => '引用訊息';

  @override
  String get messageBubbleStarTooltip => '標記星號';

  @override
  String get messageBubbleRemoveStarTooltip => '取消星號';

  @override
  String get messageBubbleActionsTooltip => '訊息操作';

  @override
  String get messageBubbleEditAction => '編輯訊息';

  @override
  String get messageBubbleDeleteForEveryoneAction => '為所有人刪除';

  @override
  String get messageBubbleErasePermanentlyAction => '永久抹除';

  @override
  String get messageBubbleAddReactionTooltip => '新增反應';

  @override
  String get messageBubbleMessageDeletedLabel => '訊息已刪除';

  @override
  String get messageBubbleBurnAfterReadBadge => '閱後即焚';

  @override
  String get messageBubblePersistentBadge => '持久保存';

  @override
  String get messageBubbleDeletedMarker => '已刪除';

  @override
  String get messageBubbleEditedMarker => '已編輯';

  @override
  String get messageBubbleSpoilerLabel => '雷點';

  @override
  String get messageBubbleSpoilerHint => '雷點內容，點選顯示';

  @override
  String get messageBubblePlayVoiceTooltip => '播放語音訊息';

  @override
  String get messageBubbleStopVoiceTooltip => '停止語音訊息';

  @override
  String get messageBubbleVoiceMessageLabel => '語音訊息';

  @override
  String get messageBubbleSharedLocationLabel => '分享位置';

  @override
  String get messageBubbleSharedContactLabel => '分享聯絡人';

  @override
  String messageBubbleLatLngLabel(Object lat, Object lng) {
    return '緯度 $lat，經度 $lng';
  }

  @override
  String get messageBubbleLoadingLinkPreview => '正在載入連結預覽...';

  @override
  String get messageBubbleAttachmentSentAnnouncement => '附件已傳送';

  @override
  String get messageBubbleQuickReplyInsertedAnnouncement => '已插入快捷回覆';

  @override
  String get messageBubbleDialogCancel => '取消';

  @override
  String get messageBubbleDialogClose => '關閉';

  @override
  String get messageBubbleDeleteForEveryoneTitle => '為所有人刪除這條訊息？';

  @override
  String get messageBubbleDeleteForEveryoneBody => '會話中會顯示一個已刪除佔位符代替該訊息。';

  @override
  String get messageBubbleErasePermanentlyTitle => '永久抹除這條訊息？';

  @override
  String get messageBubbleErasePermanentlyBody => '將完全刪除該訊息記錄，而不會顯示已刪除佔位符。';

  @override
  String get messageBubbleEraseLabel => '抹除';

  @override
  String get messageBubbleDeleteLabel => '刪除';

  @override
  String get messageBubbleOriginalMessageGone => '原訊息已不可用。';
}
