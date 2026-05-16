
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gungchat/app/providers.dart';
import 'package:gungchat/core/storage/message_db.dart';
import 'package:gungchat/features/settings/settings_screen.dart';
import 'package:gungchat/l10n/app_localizations.dart';
import 'package:gungchat/templates/quick_reply_service.dart';

class _FakeMessageDatabase extends MessageDatabase {}

class _FakeQuickReplyService extends QuickReplyService {
  _FakeQuickReplyService([List<QuickReply> initial = const <QuickReply>[]])
      : _templates = List<QuickReply>.from(initial),
        super(_FakeMessageDatabase());

  final List<QuickReply> _templates;

  @override
  Future<void> createTemplate(String shortCode, String content) async {
    final normalizedShortCode = QuickReplyService.normalizeShortCode(shortCode);
    _templates.removeWhere((template) => template.shortCode == normalizedShortCode);
    _templates.add(
      QuickReply(
        shortCode: normalizedShortCode,
        content: content.trim(),
        usageCount: 0,
        createdAt: DateTime(2026, 4, 24, 10),
      ),
    );
  }

  @override
  Future<void> deleteTemplate(String shortCode) async {
    final normalizedShortCode = QuickReplyService.normalizeShortCode(shortCode);
    _templates.removeWhere((template) => template.shortCode == normalizedShortCode);
  }

  @override
  Future<List<QuickReply>> getAllTemplates() async {
    final templates = [..._templates]
      ..sort((left, right) => right.usageCount.compareTo(left.usageCount));
    return List<QuickReply>.unmodifiable(templates);
  }

  @override
  Future<List<QuickReply>> search(String prefix) async {
    final normalizedPrefix = QuickReplyService.lookupPrefix(prefix);
    final matches = _templates
        .where((template) => template.shortCode.startsWith(normalizedPrefix))
        .toList(growable: false);
    return List<QuickReply>.unmodifiable(matches);
  }

  @override
  Future<String?> useTemplate(String shortCode) async {
    final normalizedShortCode = QuickReplyService.normalizeShortCode(shortCode);
    final index = _templates.indexWhere(
      (template) => template.shortCode == normalizedShortCode,
    );
    if (index == -1) {
      return null;
    }

    final template = _templates[index];
    _templates[index] = QuickReply(
      shortCode: template.shortCode,
      content: template.content,
      usageCount: template.usageCount + 1,
      createdAt: template.createdAt,
    );
    return template.content;
  }
}

Widget _buildApp({
  required Widget child,
  List<Override> overrides = const <Override>[],
  Locale? locale,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: child),
    ),
  );
}

Widget _buildLocaleBoundApp({
  required Widget child,
  List<Override> overrides = const <Override>[],
}) {
  return ProviderScope(
    overrides: overrides,
    child: Consumer(
      builder: (context, ref, _) {
        final locale = ref.watch(appLocaleProvider);
        return MaterialApp(
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(body: child),
        );
      },
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
  });

  testWidgets('settings screen shows quick replies, shortcuts, and notification prefs', (
    WidgetTester tester,
  ) async {
    final fakeQuickReplies = _FakeQuickReplyService(
      <QuickReply>[
        QuickReply(
          shortCode: 'hi',
          content: 'Hello from GungChat',
          usageCount: 3,
          createdAt: DateTime(2026, 4, 24, 9),
        ),
      ],
    );

    await tester.pumpWidget(
      _buildApp(
        child: const SettingsScreen(),
        overrides: <Override>[
          quickReplyServiceProvider.overrideWith(
            (ref) => Future<QuickReplyService>.value(fakeQuickReplies),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Quick reply templates'), findsOneWidget);
    expect(find.text('/hi'), findsWidgets);
    expect(find.textContaining('Hello from GungChat'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Notification preferences'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Notification preferences'), findsOneWidget);
    expect(find.text('Open quick search'), findsOneWidget);
    expect(find.text('Ctrl+K'), findsOneWidget);
  });

  testWidgets('settings screen can create and delete a quick reply template', (
    WidgetTester tester,
  ) async {
    final fakeQuickReplies = _FakeQuickReplyService();

    await tester.pumpWidget(
      _buildApp(
        child: const SettingsScreen(),
        overrides: <Override>[
          quickReplyServiceProvider.overrideWith(
            (ref) => Future<QuickReplyService>.value(fakeQuickReplies),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Shortcode'), '/brb');
    await tester.enterText(
      find.widgetWithText(TextField, 'Template text'),
      'Be right back',
    );
    await tester.tap(find.text('Save template'));
    await tester.pumpAndSettle();

    expect(find.text('/brb'), findsOneWidget);
    expect(find.textContaining('Be right back'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete template'));
    await tester.pumpAndSettle();

    expect(find.text('/brb'), findsNothing);
  });

  testWidgets('settings screen renders Spanish labels when locale is es', (
    WidgetTester tester,
  ) async {
    final fakeQuickReplies = _FakeQuickReplyService();

    await tester.pumpWidget(
      _buildApp(
        child: const SettingsScreen(),
        locale: const Locale('es'),
        overrides: <Override>[
          quickReplyServiceProvider.overrideWith(
            (ref) => Future<QuickReplyService>.value(fakeQuickReplies),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ajustes'), findsOneWidget);
    expect(find.text('Apariencia'), findsOneWidget);
    expect(find.text('Modo de tema'), findsOneWidget);
  });

  testWidgets('settings screen language selector updates the app locale', (
    WidgetTester tester,
  ) async {
    final fakeQuickReplies = _FakeQuickReplyService();

    await tester.pumpWidget(
      _buildLocaleBoundApp(
        child: const SettingsScreen(),
        overrides: <Override>[
          quickReplyServiceProvider.overrideWith(
            (ref) => Future<QuickReplyService>.value(fakeQuickReplies),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);

    await tester.tap(find.text('System default'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Spanish').last);
    await tester.pumpAndSettle();

    expect(find.text('Ajustes'), findsOneWidget);
    expect(find.text('Idioma'), findsOneWidget);
  });
}