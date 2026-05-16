import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gungchat/app/providers.dart';
import 'package:gungchat/core/encryption/key_manager.dart';
import 'package:gungchat/core/storage/message_db.dart';
import 'package:gungchat/features/contacts/contact_book_controller.dart';
import 'package:gungchat/features/contacts/contact_book_storage.dart';
import 'package:gungchat/features/contacts/contact_exchange_service.dart';
import 'package:gungchat/features/contacts/contacts_screen.dart';
import 'package:gungchat/l10n/app_localizations.dart';
import 'package:gungchat/models/contact.dart';
import 'package:gungchat/organization/contact_notes_service.dart';
import 'package:gungchat/organization/conversation_mute_service.dart';
import 'package:gungchat/organization/label_service.dart';
import 'package:gungchat/security/contact_block_service.dart';

class _FakeMessageDatabase extends MessageDatabase {}

class _FakeContactBookStorage extends ContactBookStorage {
  _FakeContactBookStorage(this._contacts);

  List<Contact> _contacts;

  @override
  Future<List<Contact>> loadContacts() async {
    return List<Contact>.unmodifiable(_contacts);
  }

  @override
  Future<void> saveContacts(List<Contact> contacts) async {
    _contacts = List<Contact>.from(contacts);
  }
}

class _FakeContactBlockStore implements ContactBlockStore {
  Set<String> _blocked = <String>{};

  @override
  Future<Set<String>> loadBlockedFingerprints() async {
    return Set<String>.unmodifiable(_blocked);
  }

  @override
  Future<void> saveBlockedFingerprints(Set<String> fingerprints) async {
    _blocked = {...fingerprints};
  }
}

class _FakeContactExchangeService extends ContactExchangeService {
  const _FakeContactExchangeService();

  @override
  Future<ContactCard> buildLocalContactCard({
    required DeviceIdentity identity,
    required String displayName,
    int port = 40524,
  }) async {
    return ContactCard(
      displayName: displayName,
      fingerprint: identity.fingerprint,
      addresses: const <String>['192.168.1.10'],
      port: port,
      createdAt: DateTime(2026, 4, 24, 12),
    );
  }
}

class _FakeLabelService extends LabelService {
  _FakeLabelService({
    List<ConversationLabel> labels = const <ConversationLabel>[],
    Map<String, Set<String>> selected = const <String, Set<String>>{},
  })  : _labels = List<ConversationLabel>.from(labels),
        _selected = {
          for (final entry in selected.entries) entry.key: {...entry.value},
        },
        super(_FakeMessageDatabase());

  final List<ConversationLabel> _labels;
  final Map<String, Set<String>> _selected;
  int _counter = 0;

  @override
  Future<ConversationLabel> createLabel(String name, String colorHex) async {
    _counter += 1;
    final label = ConversationLabel(
      id: 'label-$_counter',
      name: name.trim(),
      colorHex: colorHex,
      createdAt: DateTime(2026, 4, 24, 12, _counter),
    );
    _labels.add(label);
    return label;
  }

  @override
  Future<List<ConversationLabel>> getAllLabels() async {
    return List<ConversationLabel>.unmodifiable(_labels);
  }

  @override
  Future<List<ConversationLabel>> getLabelsForConversation(String contactId) async {
    final selectedIds = _selected[contactId] ?? <String>{};
    return _labels
        .where((label) => selectedIds.contains(label.id))
        .toList(growable: false);
  }

  @override
  Future<void> addLabelToConversation(String contactId, String labelId) async {
    _selected.putIfAbsent(contactId, () => <String>{}).add(labelId);
  }

  @override
  Future<void> removeLabelFromConversation(String contactId, String labelId) async {
    _selected[contactId]?.remove(labelId);
  }

  @override
  Future<List<String>> getConversationsByLabel(String labelId) async {
    return _selected.entries
        .where((entry) => entry.value.contains(labelId))
        .map((entry) => entry.key)
        .toList(growable: false);
  }
}

class _FakeContactNotesService extends ContactNotesService {
  _FakeContactNotesService({
    Map<String, List<ContactNote>> notes = const <String, List<ContactNote>>{},
  })  : _notes = {
          for (final entry in notes.entries) entry.key: [...entry.value],
        },
        super(_FakeMessageDatabase());

  final Map<String, List<ContactNote>> _notes;
  int _counter = 0;

  @override
  Future<ContactNote> addNote(String contactId, String noteText) async {
    _counter += 1;
    final note = ContactNote(
      id: 'note-$_counter',
      contactId: contactId,
      content: noteText.trim(),
      createdAt: DateTime(2026, 4, 24, 13, _counter),
      updatedAt: DateTime(2026, 4, 24, 13, _counter),
    );
    _notes.putIfAbsent(contactId, () => <ContactNote>[]).insert(0, note);
    return note;
  }

  @override
  Future<void> deleteNote(String noteId) async {
    for (final entry in _notes.entries) {
      entry.value.removeWhere((note) => note.id == noteId);
    }
  }

  @override
  Future<List<ContactNote>> getNotesForContact(String contactId) async {
    return List<ContactNote>.unmodifiable(_notes[contactId] ?? const <ContactNote>[]);
  }
}

class _FakeConversationMuteService extends ConversationMuteService {
  _FakeConversationMuteService({
    Map<String, ConversationNotificationSettings> initial =
        const <String, ConversationNotificationSettings>{},
  })  : _state = {...initial},
        super(_FakeMessageDatabase());

  final Map<String, ConversationNotificationSettings> _state;

  @override
  Future<ConversationNotificationSettings> getSettings(String contactId) async {
    return _state[contactId] ??
        ConversationNotificationSettings(contactId: contactId, muted: false);
  }

  @override
  Future<void> mute(String contactId) async {
    _state[contactId] = ConversationNotificationSettings(
      contactId: contactId,
      muted: true,
    );
  }

  @override
  Future<void> snoozeUntil(String contactId, DateTime until) async {
    _state[contactId] = ConversationNotificationSettings(
      contactId: contactId,
      muted: false,
      snoozedUntil: until,
    );
  }

  @override
  Future<void> unmute(String contactId) async {
    _state.remove(contactId);
  }

  @override
  Future<bool> shouldNotify(String contactId) async {
    return (await getSettings(contactId)).shouldNotifyAt(DateTime.now());
  }
}

Widget _buildApp({required List<Override> overrides}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: ContactsScreen()),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
  });

  testWidgets('contacts screen can show the organization panel and update it', (
    WidgetTester tester,
  ) async {
    final contact = Contact(
      id: 'peer-1',
      displayName: 'Alice',
      fingerprint: 'peer:alice',
      lastKnownAddress: '192.168.1.25:40524',
      lastSeenAt: DateTime(2026, 4, 24, 11, 30),
      trustLevel: ContactTrustLevel.verified,
      isLanDiscovered: true,
    );
    final labelService = _FakeLabelService();
    final notesService = _FakeContactNotesService();
    final muteService = _FakeConversationMuteService();

    await tester.pumpWidget(
      _buildApp(
        overrides: <Override>[
          deviceIdentityProvider.overrideWith(
            (ref) async => DeviceIdentity(
              publicKey: Uint8List(32),
              privateKey: Uint8List(32),
              fingerprint: 'me:01:02:03',
            ),
          ),
          contactExchangeServiceProvider.overrideWith(
            (ref) => const _FakeContactExchangeService(),
          ),
          contactBookProvider.overrideWith(
            (ref) => ContactBookController(
              storage: _FakeContactBookStorage(<Contact>[contact]),
            ),
          ),
          selectedContactProvider.overrideWith((ref) => contact),
          blockedContactsProvider.overrideWith(
            (ref) => ContactBlockController(
              storage: _FakeContactBlockStore(),
            ),
          ),
          labelServiceProvider.overrideWith(
            (ref) => Future<LabelService>.value(labelService),
          ),
          contactNotesServiceProvider.overrideWith(
            (ref) => Future<ContactNotesService>.value(notesService),
          ),
          conversationMuteServiceProvider.overrideWith(
            (ref) => Future<ConversationMuteService>.value(muteService),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Organization'), findsOneWidget);
    expect(find.text('No labels created yet.'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'New label'), 'VIP');
    final createLabelButton = find.text('Create label');
    await tester.ensureVisible(createLabelButton);
    await tester.tap(createLabelButton);
    await tester.pumpAndSettle();

    expect(find.text('VIP'), findsOneWidget);

    final noteField = find.widgetWithText(TextField, 'Add private note');
    await tester.ensureVisible(noteField);
    await tester.enterText(
      noteField,
      'Met at the cafe',
    );
    final saveNoteButton = find.text('Save note');
    await tester.ensureVisible(saveNoteButton);
    await tester.tap(saveNoteButton);
    await tester.pumpAndSettle();

    expect(find.text('Met at the cafe'), findsOneWidget);

    final notificationsText = find.text(
      'Notifications are active for this contact.',
      skipOffstage: false,
    );
    await tester.ensureVisible(notificationsText);
    await tester.pumpAndSettle();

    expect(find.text('Notifications are active for this contact.'), findsOneWidget);

    final muteButton = find.text('Mute');
    await tester.ensureVisible(muteButton);
    await tester.tap(muteButton);
    await tester.pumpAndSettle();

    expect(find.text('Muted until you manually unmute it.'), findsOneWidget);
  });

  testWidgets('contacts screen uses a QR-first connect flow', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        overrides: <Override>[
          deviceIdentityProvider.overrideWith(
            (ref) async => DeviceIdentity(
              publicKey: Uint8List(32),
              privateKey: Uint8List(32),
              fingerprint: 'me:01:02:03',
            ),
          ),
          contactExchangeServiceProvider.overrideWith(
            (ref) => const _FakeContactExchangeService(),
          ),
          contactBookProvider.overrideWith(
            (ref) => ContactBookController(
              storage: _FakeContactBookStorage(const <Contact>[]),
            ),
          ),
          blockedContactsProvider.overrideWith(
            (ref) => ContactBlockController(
              storage: _FakeContactBlockStore(),
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Scan Peer QR'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Your Connect QR'), findsOneWidget);
    expect(find.text('Scan Peer QR'), findsOneWidget);
    expect(find.text('Scan QR and Connect'), findsOneWidget);
    expect(find.text('Import Contact'), findsNothing);
    expect(find.text('Nearby Peers'), findsNothing);
  });

  testWidgets('contacts screen disables local scanning on Windows', (
    WidgetTester tester,
  ) async {
    final previousPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;

    await tester.pumpWidget(
      _buildApp(
        overrides: <Override>[
          deviceIdentityProvider.overrideWith(
            (ref) async => DeviceIdentity(
              publicKey: Uint8List(32),
              privateKey: Uint8List(32),
              fingerprint: 'me:01:02:03',
            ),
          ),
          contactExchangeServiceProvider.overrideWith(
            (ref) => const _FakeContactExchangeService(),
          ),
          contactBookProvider.overrideWith(
            (ref) => ContactBookController(
              storage: _FakeContactBookStorage(const <Contact>[]),
            ),
          ),
          blockedContactsProvider.overrideWith(
            (ref) => ContactBlockController(
              storage: _FakeContactBlockStore(),
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Scan on Another Device'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Scan on Another Device'), findsOneWidget);

    debugDefaultTargetPlatformOverride = previousPlatform;
  });
}