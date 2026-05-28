// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'GungChat';

  @override
  String get chatTab => 'Chats';

  @override
  String get contactsTab => 'Contactos';

  @override
  String get settingsTab => 'Ajustes';

  @override
  String get quickSearchTitle => 'Búsqueda rápida';

  @override
  String get searchContactsLabel => 'Buscar contactos';

  @override
  String get searchContactsHint => 'Nombre o huella';

  @override
  String get noContactsMatchSearch =>
      'Ningún contacto coincide con la búsqueda.';

  @override
  String get closeAction => 'Cerrar';

  @override
  String get openedChatForLabel => 'Chat abierto para';

  @override
  String get mutedAnnouncementLabel => 'Silenciado';

  @override
  String get unmutedAnnouncementLabel => 'Silencio quitado';

  @override
  String get themeChangedToLabel => 'Tema cambiado a';

  @override
  String get appLockedTitle => 'GungChat está bloqueado';

  @override
  String get unlockPrompt =>
      'Desbloquea con las credenciales de tu dispositivo para continuar.';

  @override
  String get unlockingAction => 'Desbloqueando...';

  @override
  String get unlockAction => 'Desbloquear';

  @override
  String get openAction => 'Abrir';

  @override
  String get discoveryTitle => 'Descubrimiento';

  @override
  String get discoverySubtitle =>
      'Escanea una vez para establecer confianza. Después del primer intercambio por QR, ambos dispositivos podrán reconectarse con un toque.';

  @override
  String get activeChatTargetLabel => 'Chat activo';

  @override
  String get yourConnectQrTitle => 'Tu QR de conexión';

  @override
  String get yourConnectQrHelp =>
      'Abre esta página en el otro dispositivo y escanea este código QR. GungChat intercambiará identidades y se conectará automáticamente por LAN.';

  @override
  String get displayNameLabel => 'Nombre visible';

  @override
  String get contactCardUnavailableLabel => 'Tarjeta de contacto no disponible';

  @override
  String get identityUnavailableLabel => 'Identidad no disponible';

  @override
  String get fingerprintLabel => 'Huella';

  @override
  String get noLanAddressesDetected =>
      'Todavía no se detectaron direcciones LAN.';

  @override
  String get lanAddressesLabel => 'Direcciones LAN';

  @override
  String get keepQrVisibleHint =>
      'Mantén este QR visible hasta que el otro dispositivo termine de escanear y empiece a conectarse.';

  @override
  String get scanPeerQrTitle => 'Escanear QR del otro dispositivo';

  @override
  String get scanPeerQrCameraHelp =>
      'Usa la cámara de este dispositivo para escanear el QR del otro GungChat. El primer escaneo crea una conexión de confianza automáticamente.';

  @override
  String get scanPeerQrDesktopHelp =>
      'Este dispositivo no puede escanear códigos QR. Usa otro dispositivo GungChat con cámara para escanear este QR y completar el primer intercambio de confianza.';

  @override
  String get scanQrAndConnectAction => 'Escanear QR y conectar';

  @override
  String get scanOnAnotherDeviceAction => 'Escanear en otro dispositivo';

  @override
  String get savedContactsTitle => 'Contactos guardados';

  @override
  String get savedContactsEmpty =>
      'Los dispositivos de confianza aparecerán aquí después del primer escaneo QR.';

  @override
  String get blockedContactsCannotStartSession =>
      'Los contactos bloqueados no pueden iniciar una sesión entre pares.';

  @override
  String get scanQrNotAvailableOnWindows =>
      'El escaneo QR no está disponible en Windows. Usa otro dispositivo GungChat con cámara para escanear este código.';

  @override
  String get scanDeviceBeforeConnect =>
      'Escanea un código QR de GungChat antes de intentar conectar.';

  @override
  String get qrMissingLanAddress =>
      'Este código QR todavía no incluye una dirección LAN utilizable. Abre de nuevo la página QR en el otro dispositivo y vuelve a escanear.';

  @override
  String get trustedConnectingLabel =>
      'Confiable. Conectando automáticamente por LAN:';

  @override
  String get connectingAutomaticallyLabel => 'Conectando automáticamente con';

  @override
  String get qrConnectionFailedLabel => 'Falló la conexión por QR';

  @override
  String get organizationTitle => 'Organización';

  @override
  String get organizationSubtitle =>
      'Administra etiquetas, notas privadas y el estado de notificaciones de este contacto.';

  @override
  String get labelsTitle => 'Etiquetas';

  @override
  String get noLabelsCreatedYet => 'Todavía no hay etiquetas creadas.';

  @override
  String get newLabelLabel => 'Nueva etiqueta';

  @override
  String get createLabelAction => 'Crear etiqueta';

  @override
  String get privateNotesTitle => 'Notas privadas';

  @override
  String get noPrivateNotesYet =>
      'Todavía no hay notas privadas para este contacto.';

  @override
  String get updatedLabel => 'Actualizado';

  @override
  String get deleteNoteTooltip => 'Eliminar nota';

  @override
  String get addPrivateNoteLabel => 'Agregar nota privada';

  @override
  String get saveNoteAction => 'Guardar nota';

  @override
  String get notificationsTitle => 'Notificaciones';

  @override
  String get mutedUntilManualUnmute =>
      'Silenciado hasta que lo actives manualmente.';

  @override
  String get snoozedUntilLabel => 'Pospuesto hasta';

  @override
  String get notificationsActiveForContact =>
      'Las notificaciones están activas para este contacto.';

  @override
  String get muteAction => 'Silenciar';

  @override
  String get unmuteAction => 'Activar sonido';

  @override
  String get snooze1hAction => 'Posponer 1 h';

  @override
  String get snooze8hAction => 'Posponer 8 h';

  @override
  String get trustedChip => 'Confiable';

  @override
  String get blockedChip => 'Bloqueado';

  @override
  String get selectedChip => 'Seleccionado';

  @override
  String get lanDiscoveredChip => 'Descubierto en LAN';

  @override
  String get scanQrFirstChip => 'Escanea QR primero';

  @override
  String get manageAction => 'Gestionar';

  @override
  String get openInChatAction => 'Abrir en chat';

  @override
  String get connectAction => 'Conectar';

  @override
  String get needsQrAction => 'Necesita QR';

  @override
  String get unblockAction => 'Desbloquear';

  @override
  String get blockAction => 'Bloquear';

  @override
  String get seenLabel => 'Visto';

  @override
  String get blockedLabel => 'Bloqueado';

  @override
  String get unblockedLabel => 'Desbloqueado';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get appearanceTitle => 'Apariencia';

  @override
  String get themeModeLabel => 'Modo de tema';

  @override
  String get themeModeAuto => 'Automático';

  @override
  String get themeModeLight => 'Claro';

  @override
  String get themeModeDark => 'Oscuro';

  @override
  String get keyboardShortcutThemeHint =>
      'Atajo de teclado: Ctrl+Shift+D alterna entre Automático, Claro y Oscuro.';

  @override
  String get languageLabel => 'Idioma';

  @override
  String get languageSystem => 'Predeterminado del sistema';

  @override
  String get languageEnglish => 'Inglés';

  @override
  String get languageChineseSimplified => 'Chino simplificado';

  @override
  String get languageChineseTraditional => 'Chino tradicional';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageFrench => 'Francés';

  @override
  String get languageChangeHelp =>
      'Se aplica de inmediato. Elige Predeterminado del sistema para seguir el idioma del dispositivo.';

  @override
  String get quickReplyTemplatesTitle => 'Plantillas de respuesta rápida';

  @override
  String get shortcodeLabel => 'Código corto';

  @override
  String get templateTextLabel => 'Texto de plantilla';

  @override
  String get saveTemplateAction => 'Guardar plantilla';

  @override
  String get noQuickRepliesYet =>
      'Todavía no hay respuestas rápidas guardadas. Crea una aquí y luego escribe su código corto en el chat para insertarla al instante.';

  @override
  String get usedLabel => 'Usado';

  @override
  String get timeSingular => 'vez';

  @override
  String get timePlural => 'veces';

  @override
  String get deleteTemplateTooltip => 'Eliminar plantilla';

  @override
  String get quickRepliesLoadFailedLabel =>
      'No se pudieron cargar las respuestas rápidas';

  @override
  String get quickReplySavedLabel => 'Respuesta rápida guardada';

  @override
  String get quickReplyDeletedLabel => 'Respuesta rápida eliminada';

  @override
  String get customStatusTitle => 'Estado personalizado';

  @override
  String get statusTextLabel => 'Texto de estado';

  @override
  String get statusTextHint =>
      'En una reunión, No molestar, Disponible más tarde...';

  @override
  String get customStatusHelp =>
      'Este texto se comparte directamente con la sesión entre pares activa junto con tu estado de presencia.';

  @override
  String get screenshotProtectionTitle => 'Protección contra capturas';

  @override
  String get screenshotProtectionSubtitle =>
      'Android ya habilita ventanas seguras. La detección de grabación en iOS y escritorio todavía requiere seguimiento específico por plataforma.';

  @override
  String get readReceiptsTitle => 'Confirmaciones de lectura';

  @override
  String get readReceiptsSubtitle =>
      'Activa el envío de confirmaciones de lectura cifradas cuando abras una conversación y veas mensajes entregados.';

  @override
  String get linkPreviewsTitle => 'Vistas previas de enlaces';

  @override
  String get linkPreviewsSubtitle =>
      'Desactivadas por defecto por privacidad. Activarlas permite que tu dispositivo obtenga metadatos de páginas web directamente, lo que puede revelar tu IP a esos sitios.';

  @override
  String get presenceStatusTitle => 'Estado de presencia';

  @override
  String get sharedPresenceLabel => 'Presencia compartida';

  @override
  String get presenceOnline => 'En línea';

  @override
  String get presenceAway => 'Ausente';

  @override
  String get presenceHidden => 'Oculto';

  @override
  String get sharedPresenceHelp =>
      'El estado En línea se comparte mientras la app está en primer plano y vuelve automáticamente a Ausente en segundo plano. Oculto suprime las actualizaciones de presencia.';

  @override
  String get notificationPreferencesTitle => 'Preferencias de notificación';

  @override
  String get notificationMessages => 'Mensajes';

  @override
  String get notificationCalls => 'Llamadas';

  @override
  String get notificationPresenceChanges => 'Cambios de presencia';

  @override
  String get notificationConnectionRequests => 'Solicitudes de conexión';

  @override
  String get notificationReactions => 'Reacciones';

  @override
  String get notificationSound => 'Sonido';

  @override
  String get notificationVibrate => 'Vibración';

  @override
  String get keyboardShortcutsTitle => 'Atajos de teclado';

  @override
  String get shortcutOpenQuickSearch => 'Abrir búsqueda rápida';

  @override
  String get shortcutCycleThemeMode => 'Cambiar modo de tema';

  @override
  String get shortcutNextTab => 'Ir a la siguiente pestaña';

  @override
  String get shortcutPreviousTab => 'Ir a la pestaña anterior';

  @override
  String get shortcutFocusComposer => 'Enfocar el cuadro de redacción activo';

  @override
  String get shortcutMuteConversation =>
      'Silenciar la conversación seleccionada';

  @override
  String get appLockTitle => 'Bloqueo de la app';

  @override
  String get requireUnlockTitle =>
      'Requerir desbloqueo biométrico o del dispositivo';

  @override
  String get requireUnlockSubtitle =>
      'Cuando está activado, GungChat solicita autenticación del dispositivo al iniciar y al volver desde segundo plano.';

  @override
  String get relockAfterLabel => 'Volver a bloquear después de';

  @override
  String get secondUnit => 'segundo';

  @override
  String get secondsUnit => 'segundos';

  @override
  String get minuteUnit => 'minuto';

  @override
  String get minutesUnit => 'minutos';

  @override
  String get accessibilityTitle => 'Accesibilidad';

  @override
  String get reducedMotionLabel => 'Movimiento reducido';

  @override
  String get highContrastLabel => 'Alto contraste';

  @override
  String get onValue => 'Activado';

  @override
  String get offValue => 'Desactivado';

  @override
  String get accessibilitySummary =>
      'Esta fase usa objetivos táctiles mínimos de 48 dp, anuncios para lectores de pantalla en acciones clave y superficies para descubrir atajos de teclado.';

  @override
  String get burnAfterReadDefaultTitle => 'Predeterminado de borrar tras leer';

  @override
  String get burnAfterReadDefaultSubtitle =>
      'El flujo inicial del chat ya asume mensajería efímera por defecto.';

  @override
  String get antiSurveillanceGuardTitle => 'Guardia antivigilancia';

  @override
  String get antiSurveillanceGuardSubtitle =>
      'El transporte ya está en su lugar. El siguiente trabajo de plataforma ampliará la detección de grabación y la protección de privacidad más allá de las ventanas seguras de Android.';

  @override
  String get selectContactToStartVideoCall =>
      'Selecciona un contacto para iniciar una videollamada';

  @override
  String get blockedContactsCannotBeCalled =>
      'No se puede llamar a contactos bloqueados';

  @override
  String get contactNeedsLanBeforeCall =>
      'Este contacto necesita una dirección LAN antes de poder llamarlo';

  @override
  String get startVideoCallTooltip => 'Iniciar videollamada';

  @override
  String get videoCallAlreadyInProgress => 'Ya hay una videollamada en curso';

  @override
  String get secureChannelOpen => 'Canal seguro abierto';

  @override
  String get chooseContactFromContacts => 'Elige un contacto en Contactos';

  @override
  String get isBlockedSuffix => 'está bloqueado';

  @override
  String get readyToConnect => 'Listo para conectar';

  @override
  String get connectionDetailsTitle => 'Detalles de conexión';

  @override
  String get connectionDetailsTooltip => 'Detalles de conexión';

  @override
  String get videoCallCouldNotStartLabel =>
      'No se pudo iniciar la videollamada';

  @override
  String get noMessagesYetBootstrap =>
      'Todavía no hay mensajes. Guarda un mensaje local inicial o selecciona un contacto.';

  @override
  String get noMessagesYetPeer =>
      'Todavía no hay mensajes para este par. Completa el intercambio de señalización para iniciar la conversación segura.';

  @override
  String get messageLoadFailedLabel => 'No se pudieron cargar los mensajes';

  @override
  String get conversationLabel => 'Conversación';

  @override
  String get localBootstrapCache => 'caché local inicial';

  @override
  String get waitingForSecureChannel => 'esperando el canal seguro';

  @override
  String get peerCustomStatusLabel => 'Estado personalizado del par';

  @override
  String get yourCustomStatusLabel => 'Tu estado personalizado';

  @override
  String get blockedContactWarning =>
      'Este contacto está bloqueado. Desbloquéalo en Contactos antes de continuar con la mensajería entre pares.';

  @override
  String get replyingToYourself => 'Respondiéndote a ti mismo';

  @override
  String get replyingToPeer => 'Respondiendo al par';

  @override
  String get cancelReplyTooltip => 'Cancelar respuesta';

  @override
  String get composerSendAction => 'Enviar';

  @override
  String get composerSaveLocalAction => 'Guardar mensaje local';

  @override
  String get composerWaitForSecureChannel => 'Esperando canal seguro';

  @override
  String get composerSaveMessageEditAction => 'Guardar edición';

  @override
  String get composerConnectAction => 'Conectar';

  @override
  String get composerBurnAfterReadLabel => 'Borrar tras leer';

  @override
  String get composerRecordVoiceTooltip => 'Grabar voz';

  @override
  String get composerStopAndSendVoiceTooltip => 'Detener y enviar voz';

  @override
  String get composerMoreActionsTooltip => 'Más acciones';

  @override
  String get composerBootstrapHint => 'Escribe un borrador cifrado local...';

  @override
  String get composerPeerHint =>
      'Escribe un mensaje cifrado para la sesión activa...';

  @override
  String get composerEditHint =>
      'Actualiza tu mensaje cifrado para la sesión activa...';

  @override
  String get composerHelpHint =>
      'Escribe /help para comandos locales, o completa el intercambio de señales para enviar.';

  @override
  String get composerBlockedHint =>
      'Este contacto está bloqueado. Los comandos de barra siguen funcionando localmente.';

  @override
  String get composerOpenSessionForStickers =>
      'Abre una sesión segura antes de enviar pegatinas.';

  @override
  String get composerFinishSignalExchangeWarning =>
      'Completa el intercambio de señales antes de enviar mensajes entre pares.';

  @override
  String composerOpenSessionBeforeSend(Object name) {
    return 'Abre o responde una sesión con $name antes de enviar.';
  }

  @override
  String get composerRecordingHint =>
      'Grabando mensaje de voz... toca Detener y enviar cuando esté listo. Hasta 2 minutos.';

  @override
  String get composerOpenChannelBeforeRecording =>
      'Abre el canal seguro antes de grabar mensajes de voz.';

  @override
  String get composerMicrophoneError =>
      'No se pudo acceder al micrófono. Revisa los permisos de la aplicación y la configuración del dispositivo.';

  @override
  String get composerEditLabel => 'Editar mensaje seguro';

  @override
  String get composerSecureLabel => 'Mensaje seguro al par';

  @override
  String get composerBootstrapLabel => 'Mensaje de arranque';

  @override
  String get composerPeerLabel => 'Mensaje al par';

  @override
  String composerTypingStatus(Object name) {
    return '$name está escribiendo...';
  }

  @override
  String get attachmentMenuGallery => 'Galería';

  @override
  String get attachmentMenuFiles => 'Archivos';

  @override
  String get attachmentMenuLocation => 'Ubicación';

  @override
  String get attachmentMenuContact => 'Contacto';

  @override
  String get attachmentMenuSticker => 'Pegatina';

  @override
  String get stickerPickerTitle => 'Pegatinas';

  @override
  String get stickerLabelSmile => 'Sonrisa';

  @override
  String get stickerLabelHeart => 'Corazón';

  @override
  String get stickerLabelThumbs => 'Pulgar arriba';

  @override
  String get stickerLabelParty => 'Fiesta';

  @override
  String get stickerLabelFire => 'Fuego';

  @override
  String get stickerLabelSad => 'Triste';

  @override
  String get stickerLabelOk => 'OK';

  @override
  String get stickerLabelClap => 'Aplauso';

  @override
  String get messageBubbleQuotedMessage => 'Mensaje citado';

  @override
  String get messageBubbleStarTooltip => 'Destacar mensaje';

  @override
  String get messageBubbleRemoveStarTooltip => 'Quitar destacado';

  @override
  String get messageBubbleActionsTooltip => 'Acciones del mensaje';

  @override
  String get messageBubbleEditAction => 'Editar mensaje';

  @override
  String get messageBubbleDeleteForEveryoneAction => 'Eliminar para todos';

  @override
  String get messageBubbleErasePermanentlyAction => 'Borrar permanentemente';

  @override
  String get messageBubbleAddReactionTooltip => 'Añadir reacción';

  @override
  String get messageBubbleMessageDeletedLabel => 'Mensaje eliminado';

  @override
  String get messageBubbleBurnAfterReadBadge => 'Borrar tras leer';

  @override
  String get messageBubblePersistentBadge => 'Persistente';

  @override
  String get messageBubbleDeletedMarker => 'eliminado';

  @override
  String get messageBubbleEditedMarker => 'editado';

  @override
  String get messageBubbleSpoilerLabel => 'Spoiler';

  @override
  String get messageBubbleSpoilerHint => 'Spoiler, toca para revelar';

  @override
  String get messageBubblePlayVoiceTooltip => 'Reproducir mensaje de voz';

  @override
  String get messageBubbleStopVoiceTooltip => 'Detener mensaje de voz';

  @override
  String get messageBubbleVoiceMessageLabel => 'Mensaje de voz';

  @override
  String get messageBubbleSharedLocationLabel => 'Ubicación compartida';

  @override
  String get messageBubbleSharedContactLabel => 'Contacto compartido';

  @override
  String messageBubbleLatLngLabel(Object lat, Object lng) {
    return 'Lat $lat, Lon $lng';
  }

  @override
  String get messageBubbleLoadingLinkPreview =>
      'Cargando vista previa del enlace...';

  @override
  String get messageBubbleAttachmentSentAnnouncement => 'Adjunto enviado';

  @override
  String get messageBubbleQuickReplyInsertedAnnouncement =>
      'Respuesta rápida insertada';

  @override
  String get messageBubbleDialogCancel => 'Cancelar';

  @override
  String get messageBubbleDialogClose => 'Cerrar';

  @override
  String get messageBubbleDeleteForEveryoneTitle =>
      '¿Eliminar el mensaje para todos?';

  @override
  String get messageBubbleDeleteForEveryoneBody =>
      'El mensaje se reemplazará por un marcador de eliminado en la conversación.';

  @override
  String get messageBubbleErasePermanentlyTitle =>
      '¿Borrar el mensaje permanentemente?';

  @override
  String get messageBubbleErasePermanentlyBody =>
      'Esto elimina el registro del mensaje en lugar de mostrar un marcador de eliminado.';

  @override
  String get messageBubbleEraseLabel => 'Borrar';

  @override
  String get messageBubbleDeleteLabel => 'Eliminar';

  @override
  String get messageBubbleOriginalMessageGone =>
      'El mensaje original ya no está disponible.';
}
