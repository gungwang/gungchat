// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'GungChat';

  @override
  String get chatTab => 'Discussions';

  @override
  String get contactsTab => 'Contacts';

  @override
  String get settingsTab => 'Paramètres';

  @override
  String get quickSearchTitle => 'Recherche rapide';

  @override
  String get searchContactsLabel => 'Rechercher des contacts';

  @override
  String get searchContactsHint => 'Nom ou empreinte';

  @override
  String get noContactsMatchSearch =>
      'Aucun contact ne correspond à la recherche.';

  @override
  String get closeAction => 'Fermer';

  @override
  String get openedChatForLabel => 'Discussion ouverte pour';

  @override
  String get mutedAnnouncementLabel => 'Muet';

  @override
  String get unmutedAnnouncementLabel => 'Réactivé';

  @override
  String get themeChangedToLabel => 'Thème changé en';

  @override
  String get appLockedTitle => 'GungChat est verrouillé';

  @override
  String get unlockPrompt =>
      'Déverrouillez avec les identifiants de votre appareil pour continuer.';

  @override
  String get unlockingAction => 'Déverrouillage...';

  @override
  String get unlockAction => 'Déverrouiller';

  @override
  String get openAction => 'Ouvrir';

  @override
  String get discoveryTitle => 'Découverte';

  @override
  String get discoverySubtitle =>
      'Scannez une fois pour établir la confiance. Après le premier échange QR, les deux appareils pourront se reconnecter en un seul geste.';

  @override
  String get activeChatTargetLabel => 'Discussion active';

  @override
  String get yourConnectQrTitle => 'Votre QR de connexion';

  @override
  String get yourConnectQrHelp =>
      'Ouvrez cette page sur l\'autre appareil et scannez ce code QR. GungChat échangera les identités et se connectera automatiquement sur le LAN.';

  @override
  String get displayNameLabel => 'Nom affiché';

  @override
  String get contactCardUnavailableLabel => 'Carte de contact indisponible';

  @override
  String get identityUnavailableLabel => 'Identité indisponible';

  @override
  String get fingerprintLabel => 'Empreinte';

  @override
  String get noLanAddressesDetected =>
      'Aucune adresse LAN détectée pour le moment.';

  @override
  String get lanAddressesLabel => 'Adresses LAN';

  @override
  String get keepQrVisibleHint =>
      'Gardez ce QR visible jusqu\'à ce que l\'autre appareil termine le scan et commence à se connecter.';

  @override
  String get scanPeerQrTitle => 'Scanner le QR du pair';

  @override
  String get scanPeerQrCameraHelp =>
      'Utilisez la caméra de cet appareil pour scanner le QR de l\'autre GungChat. Le premier scan crée automatiquement une connexion de confiance.';

  @override
  String get scanPeerQrDesktopHelp =>
      'Cet appareil ne peut pas scanner les codes QR. Utilisez un autre appareil GungChat avec caméra pour scanner ce QR et terminer le premier échange de confiance.';

  @override
  String get scanQrAndConnectAction => 'Scanner le QR et se connecter';

  @override
  String get scanOnAnotherDeviceAction => 'Scanner sur un autre appareil';

  @override
  String get savedContactsTitle => 'Contacts enregistrés';

  @override
  String get savedContactsEmpty =>
      'Les appareils de confiance apparaîtront ici après le premier scan QR.';

  @override
  String get blockedContactsCannotStartSession =>
      'Les contacts bloqués ne peuvent pas démarrer une session pair à pair.';

  @override
  String get scanQrNotAvailableOnWindows =>
      'Le scan QR n\'est pas disponible sur Windows. Utilisez un autre appareil GungChat avec caméra pour scanner ce code.';

  @override
  String get scanDeviceBeforeConnect =>
      'Scannez un QR GungChat avant d\'essayer de vous connecter.';

  @override
  String get qrMissingLanAddress =>
      'Ce QR ne contient pas encore d\'adresse LAN utilisable. Rouvrez la page QR sur l\'autre appareil puis rescannez.';

  @override
  String get trustedConnectingLabel =>
      'Appareil approuvé. Connexion automatique sur le LAN :';

  @override
  String get connectingAutomaticallyLabel => 'Connexion automatique à';

  @override
  String get qrConnectionFailedLabel => 'Échec de la connexion QR';

  @override
  String get organizationTitle => 'Organisation';

  @override
  String get organizationSubtitle =>
      'Gérez les étiquettes, les notes privées et l\'état des notifications pour ce contact.';

  @override
  String get labelsTitle => 'Étiquettes';

  @override
  String get noLabelsCreatedYet => 'Aucune étiquette créée pour le moment.';

  @override
  String get newLabelLabel => 'Nouvelle étiquette';

  @override
  String get createLabelAction => 'Créer l\'étiquette';

  @override
  String get privateNotesTitle => 'Notes privées';

  @override
  String get noPrivateNotesYet =>
      'Aucune note privée pour ce contact pour le moment.';

  @override
  String get updatedLabel => 'Mis à jour';

  @override
  String get deleteNoteTooltip => 'Supprimer la note';

  @override
  String get addPrivateNoteLabel => 'Ajouter une note privée';

  @override
  String get saveNoteAction => 'Enregistrer la note';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get mutedUntilManualUnmute =>
      'En sourdine jusqu\'à réactivation manuelle.';

  @override
  String get snoozedUntilLabel => 'Suspendu jusqu\'à';

  @override
  String get notificationsActiveForContact =>
      'Les notifications sont actives pour ce contact.';

  @override
  String get muteAction => 'Mettre en sourdine';

  @override
  String get unmuteAction => 'Réactiver';

  @override
  String get snooze1hAction => 'Suspendre 1 h';

  @override
  String get snooze8hAction => 'Suspendre 8 h';

  @override
  String get trustedChip => 'Approuvé';

  @override
  String get blockedChip => 'Bloqué';

  @override
  String get selectedChip => 'Sélectionné';

  @override
  String get lanDiscoveredChip => 'Découvert sur le LAN';

  @override
  String get scanQrFirstChip => 'Scannez le QR d\'abord';

  @override
  String get manageAction => 'Gérer';

  @override
  String get openInChatAction => 'Ouvrir dans la discussion';

  @override
  String get connectAction => 'Connecter';

  @override
  String get needsQrAction => 'QR requis';

  @override
  String get unblockAction => 'Débloquer';

  @override
  String get blockAction => 'Bloquer';

  @override
  String get seenLabel => 'Vu';

  @override
  String get blockedLabel => 'Bloqué';

  @override
  String get unblockedLabel => 'Débloqué';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get appearanceTitle => 'Apparence';

  @override
  String get themeModeLabel => 'Mode de thème';

  @override
  String get themeModeAuto => 'Automatique';

  @override
  String get themeModeLight => 'Clair';

  @override
  String get themeModeDark => 'Sombre';

  @override
  String get keyboardShortcutThemeHint =>
      'Raccourci clavier : Ctrl+Shift+D fait défiler Automatique, Clair et Sombre.';

  @override
  String get languageLabel => 'Langue';

  @override
  String get languageSystem => 'Par défaut du système';

  @override
  String get languageEnglish => 'Anglais';

  @override
  String get languageChineseSimplified => 'Chinois simplifié';

  @override
  String get languageChineseTraditional => 'Chinois traditionnel';

  @override
  String get languageSpanish => 'Espagnol';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageChangeHelp =>
      'Le changement s\'applique immédiatement. Choisissez Par défaut du système pour suivre la langue de l\'appareil.';

  @override
  String get quickReplyTemplatesTitle => 'Modèles de réponse rapide';

  @override
  String get shortcodeLabel => 'Code court';

  @override
  String get templateTextLabel => 'Texte du modèle';

  @override
  String get saveTemplateAction => 'Enregistrer le modèle';

  @override
  String get noQuickRepliesYet =>
      'Aucune réponse rapide enregistrée pour le moment. Créez-en une ici puis tapez son code court dans le chat pour l\'insérer instantanément.';

  @override
  String get usedLabel => 'Utilisé';

  @override
  String get timeSingular => 'fois';

  @override
  String get timePlural => 'fois';

  @override
  String get deleteTemplateTooltip => 'Supprimer le modèle';

  @override
  String get quickRepliesLoadFailedLabel =>
      'Impossible de charger les réponses rapides';

  @override
  String get quickReplySavedLabel => 'Réponse rapide enregistrée';

  @override
  String get quickReplyDeletedLabel => 'Réponse rapide supprimée';

  @override
  String get customStatusTitle => 'Statut personnalisé';

  @override
  String get statusTextLabel => 'Texte du statut';

  @override
  String get statusTextHint =>
      'En réunion, Ne pas déranger, Disponible plus tard...';

  @override
  String get customStatusHelp =>
      'Ce texte est partagé directement avec la session pair à pair active en même temps que votre statut de présence.';

  @override
  String get screenshotProtectionTitle => 'Protection des captures d\'écran';

  @override
  String get screenshotProtectionSubtitle =>
      'Android active désormais les fenêtres sécurisées. La détection d\'enregistrement sur iOS et bureau nécessite encore un suivi spécifique par plateforme.';

  @override
  String get readReceiptsTitle => 'Accusés de lecture';

  @override
  String get readReceiptsSubtitle =>
      'Activez l\'envoi d\'accusés de lecture chiffrés lorsque vous ouvrez une conversation et consultez des messages livrés.';

  @override
  String get linkPreviewsTitle => 'Aperçus de liens';

  @override
  String get linkPreviewsSubtitle =>
      'Désactivés par défaut pour la confidentialité. Les activer permet à votre appareil de récupérer directement les métadonnées des pages web, ce qui peut révéler votre adresse IP à ces sites.';

  @override
  String get presenceStatusTitle => 'Statut de présence';

  @override
  String get sharedPresenceLabel => 'Présence partagée';

  @override
  String get presenceOnline => 'En ligne';

  @override
  String get presenceAway => 'Absent';

  @override
  String get presenceHidden => 'Masqué';

  @override
  String get sharedPresenceHelp =>
      'Le statut En ligne est partagé lorsque l\'application est au premier plan et repasse automatiquement sur Absent en arrière-plan. Masqué supprime les mises à jour de présence.';

  @override
  String get notificationPreferencesTitle => 'Préférences de notification';

  @override
  String get notificationMessages => 'Messages';

  @override
  String get notificationCalls => 'Appels';

  @override
  String get notificationPresenceChanges => 'Changements de présence';

  @override
  String get notificationConnectionRequests => 'Demandes de connexion';

  @override
  String get notificationReactions => 'Réactions';

  @override
  String get notificationSound => 'Son';

  @override
  String get notificationVibrate => 'Vibration';

  @override
  String get keyboardShortcutsTitle => 'Raccourcis clavier';

  @override
  String get shortcutOpenQuickSearch => 'Ouvrir la recherche rapide';

  @override
  String get shortcutCycleThemeMode => 'Faire défiler les thèmes';

  @override
  String get shortcutNextTab => 'Aller à l\'onglet suivant';

  @override
  String get shortcutPreviousTab => 'Aller à l\'onglet précédent';

  @override
  String get shortcutFocusComposer =>
      'Mettre le champ de saisie actif au focus';

  @override
  String get shortcutMuteConversation =>
      'Mettre la conversation sélectionnée en sourdine';

  @override
  String get appLockTitle => 'Verrouillage de l\'application';

  @override
  String get requireUnlockTitle =>
      'Exiger le déverrouillage biométrique ou de l\'appareil';

  @override
  String get requireUnlockSubtitle =>
      'Lorsqu\'il est activé, GungChat demande l\'authentification de l\'appareil au lancement et après un retour depuis l\'arrière-plan.';

  @override
  String get relockAfterLabel => 'Reverrouiller après';

  @override
  String get secondUnit => 'seconde';

  @override
  String get secondsUnit => 'secondes';

  @override
  String get minuteUnit => 'minute';

  @override
  String get minutesUnit => 'minutes';

  @override
  String get accessibilityTitle => 'Accessibilité';

  @override
  String get reducedMotionLabel => 'Animations réduites';

  @override
  String get highContrastLabel => 'Contraste élevé';

  @override
  String get onValue => 'Activé';

  @override
  String get offValue => 'Désactivé';

  @override
  String get accessibilitySummary =>
      'Cette phase utilise des cibles tactiles minimales de 48 dp, des annonces de lecteur d\'écran pour les actions clés et des surfaces de découverte pour les raccourcis clavier.';

  @override
  String get burnAfterReadDefaultTitle => 'Effacement après lecture par défaut';

  @override
  String get burnAfterReadDefaultSubtitle =>
      'Le flux d\'amorçage du chat suppose déjà une messagerie éphémère par défaut.';

  @override
  String get antiSurveillanceGuardTitle => 'Bouclier anti-surveillance';

  @override
  String get antiSurveillanceGuardSubtitle =>
      'Le transport est en place. Le prochain travail de plateforme étendra la détection d\'enregistrement et la protection de la confidentialité au-delà des fenêtres sécurisées d\'Android.';

  @override
  String get selectContactToStartVideoCall =>
      'Sélectionnez un contact pour démarrer un appel vidéo';

  @override
  String get blockedContactsCannotBeCalled =>
      'Impossible d\'appeler un contact bloqué';

  @override
  String get contactNeedsLanBeforeCall =>
      'Ce contact a besoin d\'une adresse LAN avant de pouvoir être appelé';

  @override
  String get startVideoCallTooltip => 'Démarrer un appel vidéo';

  @override
  String get videoCallAlreadyInProgress => 'Un appel vidéo est déjà en cours';

  @override
  String get secureChannelOpen => 'Canal sécurisé ouvert';

  @override
  String get chooseContactFromContacts => 'Choisissez un contact dans Contacts';

  @override
  String get isBlockedSuffix => 'est bloqué';

  @override
  String get readyToConnect => 'Prêt à se connecter';

  @override
  String get connectionDetailsTitle => 'Détails de connexion';

  @override
  String get connectionDetailsTooltip => 'Détails de connexion';

  @override
  String get videoCallCouldNotStartLabel =>
      'L\'appel vidéo n\'a pas pu démarrer';

  @override
  String get noMessagesYetBootstrap =>
      'Aucun message pour le moment. Enregistrez un message local d\'amorçage ou sélectionnez un contact pair.';

  @override
  String get noMessagesYetPeer =>
      'Aucun message pour ce pair pour le moment. Terminez l\'échange de signalisation pour démarrer la conversation sécurisée.';

  @override
  String get messageLoadFailedLabel => 'Échec du chargement des messages';

  @override
  String get conversationLabel => 'Conversation';

  @override
  String get localBootstrapCache => 'cache d\'amorçage local';

  @override
  String get waitingForSecureChannel => 'en attente du canal sécurisé';

  @override
  String get peerCustomStatusLabel => 'Statut personnalisé du pair';

  @override
  String get yourCustomStatusLabel => 'Votre statut personnalisé';

  @override
  String get blockedContactWarning =>
      'Ce contact est bloqué. Débloquez-le dans Contacts avant de poursuivre la messagerie pair à pair.';

  @override
  String get replyingToYourself => 'Réponse à vous-même';

  @override
  String get replyingToPeer => 'Réponse au pair';

  @override
  String get cancelReplyTooltip => 'Annuler la réponse';
}
