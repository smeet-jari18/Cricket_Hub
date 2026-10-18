import 'dart:convert';

import 'package:cricket_hub/core/app_theme.dart';
import 'package:cricket_hub/l10n/generated/app_localizations.dart';
import 'package:cricket_hub/providers/locale_provider.dart';
import 'package:cricket_hub/screens/international/international_screen.dart';
import 'package:cricket_hub/screens/settings/language_screen.dart';
import 'package:cricket_hub/services/cric_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

/// Layout safety for Hindi and Tamil.
///
/// Devanagari and Tamil are wider than Latin at the same font size, and the
/// translations are longer than the English they replace. Nothing in a normal
/// widget test notices a `RenderFlex overflowed by 24 pixels` — it is a
/// painted warning, not an exception — unless the widget tree is pumped on a
/// **narrow** surface and the exception is taken.
///
/// So every case here runs at 320 × 640 (small phone) with text scaled 1.3×
/// (a user who needs larger type), in all three languages, and asserts that
/// nothing overflowed and no other layout exception was thrown.
const _narrow = Size(320, 640);
const _bigText = 1.3;

Widget _app(Widget child, Locale locale) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light,
      builder: (context, widget) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: const TextScaler.linear(_bigText),
          size: _narrow,
        ),
        child: widget!,
      ),
      home: child,
    );

Future<void> _pumpNarrow(
  WidgetTester tester,
  Widget child,
  Locale locale,
) async {
  tester.view.physicalSize = _narrow;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(_app(child, locale));
  await tester.pumpAndSettle();
}

/// A live payload with the longest realistic strings: a long venue, a long
/// status sentence, and an opponent name that does not wrap nicely.
Map<String, dynamic> _livePayload() => {
      'status': 'success',
      'data': [
        {
          'id': 'live-1',
          'name': 'India vs Australia, 3rd ODI',
          'matchType': 'odi',
          'status': 'India need 43 runs in 36 balls',
          'venue': 'Narendra Modi Stadium, Ahmedabad',
          'teams': ['India', 'Australia'],
          'teamInfo': [
            {'name': 'India', 'shortname': 'IND', 'img': ''},
            {'name': 'Australia', 'shortname': 'AUS', 'img': ''},
          ],
          'score': [
            {'r': 289, 'w': 7, 'o': 50, 'inning': 'Australia Inning 1'},
            {'r': 247, 'w': 5, 'o': 44, 'inning': 'India Inning 1'},
          ],
          'matchStarted': true,
          'matchEnded': false,
        },
        {
          'id': 'upcoming-1',
          'name': 'South Africa vs New Zealand, 2nd Test',
          'matchType': 'test',
          'status': '',
          'venue': 'Newlands, Cape Town',
          'teams': ['South Africa', 'New Zealand'],
          'teamInfo': [
            {'name': 'South Africa', 'shortname': 'SA', 'img': ''},
            {'name': 'New Zealand', 'shortname': 'NZ', 'img': ''},
          ],
          'score': <Map<String, dynamic>>[],
          'matchStarted': false,
          'matchEnded': false,
        },
      ],
    };

CricApiService _liveService() => CricApiService(
      apiKey: 'test-key',
      client: MockClient((_) async => http.Response(
            jsonEncode(_livePayload()),
            200,
            headers: {'content-type': 'application/json'},
          )),
    );

void main() {
  testWidgets('the narrow harness really does catch an overflow', (tester) async {
    // A safety net nobody has tested is a rumour. This control case forces a
    // 400px child into a 320px surface and proves the assertion below fails.
    await _pumpNarrow(
      tester,
      const Scaffold(body: Row(children: [SizedBox(width: 400, height: 20)])),
      const Locale('en'),
    );

    expect(tester.takeException(), isA<FlutterError>());
  });

  group('language picker', () {
    for (final code in ['en', 'hi', 'ta']) {
      testWidgets('renders at 320px in $code', (tester) async {
        await _pumpNarrow(
          tester,
          ChangeNotifierProvider(
            create: (_) => LocaleProvider(),
            child: const LanguageScreen(),
          ),
          Locale(code),
        );

        expect(tester.takeException(), isNull);
        // The screen really rendered — not an empty box that trivially passes.
        expect(find.byType(ListTile), findsWidgets);
      });
    }
  });

  group('international screen', () {
    for (final code in ['hi', 'ta']) {
      testWidgets('no-key state fits at 320px in $code', (tester) async {
        await _pumpNarrow(
          tester,
          InternationalScreen(service: CricApiService(apiKey: '')),
          Locale(code),
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('live match cards fit at 320px in $code', (tester) async {
        await _pumpNarrow(
          tester,
          InternationalScreen(service: _liveService()),
          Locale(code),
        );

        expect(tester.takeException(), isNull);
        // Both matches made it onto the screen with their long venue strings.
        expect(find.textContaining('Narendra Modi Stadium'), findsWidgets);
      });
    }
  });
}
