import 'dart:convert';

import 'package:cricket_hub/l10n/generated/app_localizations.dart';
import 'package:cricket_hub/screens/international/international_screen.dart';
import 'package:cricket_hub/services/cric_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Widget-level proof for the Phase-4 International screen: the three states
/// (no key / demo / live) render, the filters work, and the whole screen is
/// really localized (not just the ARB files).
CricApiService _service({
  String key = '',
  Future<http.Response> Function(http.Request)? handler,
}) =>
    CricApiService(
      apiKey: key,
      client: MockClient(handler ?? (_) async => http.Response('{}', 200)),
    );

Widget _app(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

Map<String, dynamic> _livePayload() => {
      'status': 'success',
      'data': [
        {
          'id': 'live-1',
          'name': 'India vs Australia, 3rd ODI',
          'matchType': 'odi',
          'status': 'India need 43 runs in 36 balls',
          'venue': 'Wankhede Stadium, Mumbai',
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
      ],
    };

void main() {
  testWidgets('without a key it explains itself and offers demo data',
      (tester) async {
    await tester.pumpWidget(_app(InternationalScreen(service: _service())));
    await tester.pumpAndSettle();

    expect(find.text('Live scores need a CricAPI key'), findsOneWidget);
    expect(find.text('Show demo matches'), findsOneWidget);
    // No network was attempted and no spinner is stuck on screen.
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('demo data renders and the filters split it correctly',
      (tester) async {
    await tester.pumpWidget(_app(InternationalScreen(service: _service())));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Show demo matches'));
    await tester.pumpAndSettle();

    // Demo banner is loud about being fake.
    expect(
      find.textContaining('Demo data'),
      findsOneWidget,
    );

    // Live tab (default) shows only the live match.
    expect(find.text('India vs Australia, 3rd ODI'), findsOneWidget);
    expect(find.text('England vs South Africa, 2nd Test'), findsNothing);

    // Upcoming tab.
    await tester.tap(find.text('Upcoming'));
    await tester.pumpAndSettle();
    expect(find.text('England vs South Africa, 2nd Test'), findsOneWidget);
    expect(find.text('India vs Australia, 3rd ODI'), findsNothing);

    // Recent tab.
    await tester.tap(find.text('Recent'));
    await tester.pumpAndSettle();
    expect(find.text('Pakistan vs New Zealand, 1st T20I'), findsOneWidget);
  });

  testWidgets('live data from the API renders as score cards', (tester) async {
    final service = _service(
      key: 'k',
      handler: (_) async => http.Response(
        jsonEncode(_livePayload()),
        200,
        headers: {'content-type': 'application/json'},
      ),
    );

    await tester.pumpWidget(_app(InternationalScreen(service: service)));
    await tester.pumpAndSettle();

    expect(find.text('India vs Australia, 3rd ODI'), findsOneWidget);
    expect(find.text('289/7 (50)'), findsOneWidget);
    expect(find.text('247/5 (44)'), findsOneWidget);
    expect(find.text('LIVE'), findsWidgets);
    // No demo banner when the data is real.
    expect(find.textContaining('Demo data'), findsNothing);
  });

  testWidgets('an invalid key shows the specific error, not a blank screen',
      (tester) async {
    final service = _service(
      key: 'bad',
      handler: (_) async => http.Response(
        jsonEncode({'status': 'failure', 'reason': 'Invalid API Key'}),
        200,
      ),
    );

    await tester.pumpWidget(_app(InternationalScreen(service: service)));
    await tester.pumpAndSettle();

    expect(find.textContaining('CricAPI rejected the key'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('a network failure is reported and retry is offered',
      (tester) async {
    var calls = 0;
    final service = _service(
      key: 'k',
      handler: (_) async {
        calls++;
        if (calls == 1) throw http.ClientException('offline');
        return http.Response(
          jsonEncode(_livePayload()),
          200,
          headers: {'content-type': 'application/json'},
        );
      },
    );

    await tester.pumpWidget(_app(InternationalScreen(service: service)));
    await tester.pumpAndSettle();
    expect(find.textContaining('Could not reach CricAPI'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('India vs Australia, 3rd ODI'), findsOneWidget);
    expect(find.textContaining('Could not reach CricAPI'), findsNothing);
  });

  testWidgets('the screen is translated, not just the ARB file', (tester) async {
    await tester.pumpWidget(
      _app(InternationalScreen(service: _service()), locale: const Locale('hi')),
    );
    await tester.pumpAndSettle();

    expect(find.text('अंतरराष्ट्रीय'), findsOneWidget); // app bar
    expect(find.text('डेमो मैच दिखाएँ'), findsOneWidget); // CTA

    // The filter bar only exists once there is data, so load the demo first.
    await tester.tap(find.text('डेमो मैच दिखाएँ'));
    await tester.pumpAndSettle();
    // "Live" appears twice in Hindi: the filter chip and the LIVE badge.
    expect(find.text('लाइव'), findsWidgets);
    expect(find.text('आगामी'), findsOneWidget); // filter: Upcoming
    expect(find.text('हाल के'), findsOneWidget); // filter: Recent
    expect(find.textContaining('डेमो डेटा'), findsOneWidget); // demo banner
  });

  testWidgets('Tamil renders too', (tester) async {
    await tester.pumpWidget(
      _app(InternationalScreen(service: _service()), locale: const Locale('ta')),
    );
    await tester.pumpAndSettle();

    expect(find.text('சர்வதேசம்'), findsOneWidget);
    expect(find.text('டெமோ ஆட்டங்களைக் காட்டு'), findsOneWidget); // CTA

    await tester.tap(find.text('டெமோ ஆட்டங்களைக் காட்டு'));
    await tester.pumpAndSettle();
    expect(find.text('நேரலை'), findsWidgets); // filter chip + LIVE badge
    expect(find.text('வரவிருக்கும்'), findsOneWidget); // filter: Upcoming
    expect(find.textContaining('டெமோ தரவு'), findsOneWidget);
  });
}
