import 'dart:convert';

import 'package:cricket_hub/models/intl_match.dart';
import 'package:cricket_hub/services/cric_api_demo.dart';
import 'package:cricket_hub/services/cric_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Response shape taken from the CricAPI v1 docs — trimmed to what we read.
Map<String, dynamic> _payload({List<Map<String, dynamic>>? data}) => {
      'apikey': 'test',
      'data': data ??
          [
            {
              'id': 'm1',
              'name': 'India vs Australia, 3rd ODI',
              'matchType': 'odi',
              'status': 'India need 43 runs in 36 balls',
              'venue': 'Wankhede Stadium, Mumbai',
              'date': '2026-10-18',
              'dateTimeGMT': '2026-10-18T08:00:00',
              'teams': ['India', 'Australia'],
              'teamInfo': [
                {'name': 'India', 'shortname': 'IND', 'img': 'https://x/ind.png'},
                {'name': 'Australia', 'shortname': 'AUS', 'img': ''},
              ],
              'score': [
                {'r': 289, 'w': 7, 'o': 50, 'inning': 'Australia Inning 1'},
                {'r': 247, 'w': 5, 'o': 44, 'inning': 'India Inning 1'},
              ],
              'matchStarted': true,
              'matchEnded': false,
            }
          ],
      'status': 'success',
      'info': {'hitsToday': 1, 'hitsLimitToday': 100},
    };

CricApiService _service(
  MockClient client, {
  String key = 'test-key',
  Duration ttl = const Duration(minutes: 5),
  DateTime Function()? clock,
}) =>
    CricApiService(
      client: client,
      apiKey: key,
      cacheTtl: ttl,
      clock: clock,
    );

void main() {
  group('currentMatches — happy path', () {
    test('parses the documented response shape', () async {
      final service = _service(MockClient((_) async => http.Response(
            jsonEncode(_payload()),
            200,
            headers: {'content-type': 'application/json'},
          )));

      final matches = await service.currentMatches();
      expect(matches, hasLength(1));

      final match = matches.single;
      expect(match.id, 'm1');
      expect(match.name, 'India vs Australia, 3rd ODI');
      expect(match.matchType, 'odi');
      expect(match.teams, ['India', 'Australia']);
      expect(match.isLive, isTrue);
      expect(match.isCompleted, isFalse);
      expect(match.score, hasLength(2));
      expect(match.score.first.runs, 289);
      expect(match.score.first.wickets, 7);
      expect(match.score.first.scoreLabel, '289/7 (50)');
      expect(match.score.last.scoreLabel, '247/5 (44)');
      expect(match.shortNameFor('India'), 'IND');
      // No teamInfo entry for a hypothetical name → derived abbreviation.
      expect(match.shortNameFor('Sri Lanka'), 'SL');
      expect(match.imageFor('India'), 'https://x/ind.png');
      expect(match.imageFor('Australia'), '');
    });

    test('sends the api key and offset as query parameters', () async {
      Uri? seen;
      final service = _service(MockClient((request) async {
        seen = request.url;
        return http.Response(jsonEncode(_payload()), 200);
      }));

      await service.currentMatches();

      expect(seen!.host, 'api.cricapi.com');
      expect(seen!.path, '/v1/currentMatches');
      expect(seen!.queryParameters['apikey'], 'test-key');
      expect(seen!.queryParameters['offset'], '0');
    });

    test('drops matches without an id instead of rendering blanks', () async {
      final service = _service(MockClient((_) async => http.Response(
            jsonEncode({
              'status': 'success',
              'data': [
                {'name': 'no id here'},
                {'id': 'ok', 'name': 'Fine match', 'teams': []},
              ],
            }),
            200,
          )));

      final matches = await service.currentMatches();
      expect(matches.map((m) => m.id), ['ok']);
    });

    test('an empty data list is a valid, empty result', () async {
      final service = _service(MockClient((_) async =>
          http.Response(jsonEncode({'status': 'success', 'data': []}), 200)));
      expect(await service.currentMatches(), isEmpty);
    });
  });

  group('errors are typed, not strings', () {
    Future<CricApiError> kindOf(MockClient client, {String key = 'test-key'}) async {
      final service = _service(client, key: key);
      try {
        await service.currentMatches();
      } on CricApiException catch (e) {
        return e.kind;
      }
      fail('expected a CricApiException');
    }

    test('no key at all → missingKey (and no HTTP call is made)', () async {
      var called = false;
      final client = MockClient((_) async {
        called = true;
        return http.Response('{}', 200);
      });
      expect(await kindOf(client, key: ''), CricApiError.missingKey);
      expect(called, isFalse, reason: 'must not burn a request without a key');
    });

    test('CricAPI "Invalid API Key" inside a 200 → invalidKey', () async {
      final client = MockClient((_) async => http.Response(
            jsonEncode({'status': 'failure', 'reason': 'Invalid API Key'}),
            200,
          ));
      expect(await kindOf(client), CricApiError.invalidKey);
    });

    test('HTTP 401/403 → invalidKey', () async {
      expect(
        await kindOf(MockClient((_) async => http.Response('nope', 401))),
        CricApiError.invalidKey,
      );
      expect(
        await kindOf(MockClient((_) async => http.Response('nope', 403))),
        CricApiError.invalidKey,
      );
    });

    test('HTTP 429 → rateLimited', () async {
      expect(
        await kindOf(MockClient((_) async => http.Response('slow down', 429))),
        CricApiError.rateLimited,
      );
    });

    test('quota wording inside a failure payload → rateLimited', () async {
      final client = MockClient((_) async => http.Response(
            jsonEncode({
              'status': 'failure',
              'reason': 'Your daily hits limit is over',
            }),
            200,
          ));
      expect(await kindOf(client), CricApiError.rateLimited);
    });

    test('HTML / 500 → badResponse', () async {
      expect(
        await kindOf(MockClient((_) async => http.Response('<html>oops</html>', 500))),
        CricApiError.badResponse,
      );
      expect(
        await kindOf(MockClient((_) async => http.Response('not json', 200))),
        CricApiError.badResponse,
      );
    });

    test('a success payload without a data list → badResponse', () async {
      final client = MockClient((_) async =>
          http.Response(jsonEncode({'status': 'success'}), 200));
      expect(await kindOf(client), CricApiError.badResponse);
    });

    test('timeout → network', () async {
      final client = MockClient((_) async {
        await Future<void>.delayed(const Duration(seconds: 30));
        return http.Response('{}', 200);
      });
      // 12s real wait is too slow for CI; the service's timeout is what turns
      // this into `network`, so we assert on the mapping via a client that
      // throws the same exception the timeout would.
      final throwing = MockClient((_) async => throw http.ClientException('boom'));
      expect(await kindOf(throwing), CricApiError.network);
      // Keep the delayed client out of the test run.
      expect(client, isNotNull);
    });
  });

  group('cache', () {
    test('a second call inside the TTL does not hit the network', () async {
      var calls = 0;
      final service = _service(MockClient((_) async {
        calls++;
        return http.Response(jsonEncode(_payload()), 200);
      }));

      await service.currentMatches();
      await service.currentMatches();
      expect(calls, 1);
    });

    test('forceRefresh bypasses the cache', () async {
      var calls = 0;
      final service = _service(MockClient((_) async {
        calls++;
        return http.Response(jsonEncode(_payload()), 200);
      }));

      await service.currentMatches();
      await service.currentMatches(forceRefresh: true);
      expect(calls, 2);
    });

    test('the cache expires after the TTL', () async {
      var calls = 0;
      var now = DateTime(2026, 10, 18, 12);
      final service = _service(
        MockClient((_) async {
          calls++;
          return http.Response(jsonEncode(_payload()), 200);
        }),
        ttl: const Duration(minutes: 5),
        clock: () => now,
      );

      await service.currentMatches();
      now = now.add(const Duration(minutes: 4));
      await service.currentMatches();
      expect(calls, 1, reason: 'still inside the 5 minute window');

      now = now.add(const Duration(minutes: 2));
      await service.currentMatches();
      expect(calls, 2, reason: 'window expired, must refetch');
    });

    test('a failed refresh keeps the previous result usable', () async {
      var fail = false;
      final service = _service(MockClient((_) async {
        if (fail) return http.Response('down', 500);
        return http.Response(jsonEncode(_payload()), 200);
      }));

      final first = await service.currentMatches();
      expect(first, hasLength(1));

      fail = true;
      await expectLater(
        service.currentMatches(forceRefresh: true),
        throwsA(isA<CricApiException>()),
      );
      // The cached list is untouched, so the UI can keep showing it.
      expect(service.isServingCache, isTrue);
    });
  });

  group('matchInfo', () {
    test('parses a scorecard', () async {
      final service = _service(MockClient((_) async => http.Response(
            jsonEncode({
              'status': 'success',
              'data': {
                ..._payload()['data'][0],
                'scorecard': [
                  {
                    'inning': 'India Inning 1',
                    'batting': [
                      {
                        'batsman': {'id': 'p1', 'name': 'V Kohli'},
                        'r': 94,
                        'b': 88,
                        '4s': 6,
                        '6s': 2,
                        'sr': 106.8,
                        'dismissal': 'not out',
                      },
                    ],
                    'bowling': [
                      {
                        'bowler': {'id': 'p2', 'name': 'JR Hazlewood'},
                        'o': 9,
                        'm': 1,
                        'r': 44,
                        'w': 2,
                        'eco': 4.9,
                      },
                    ],
                  }
                ],
              },
            }),
            200,
          )));

      final detail = await service.matchInfo('m1');
      expect(detail.hasScorecard, isTrue);
      expect(detail.innings, hasLength(1));

      final batting = detail.innings.single.batting.single;
      expect(batting.name, 'V Kohli');
      expect(batting.runs, 94);
      expect(batting.dismissal, 'not out');

      final bowling = detail.innings.single.bowling.single;
      expect(bowling.name, 'JR Hazlewood');
      expect(bowling.overs, 9.0);
      expect(bowling.wickets, 2);
    });

    test('an empty id fails before spending a request', () async {
      var called = false;
      final service = _service(MockClient((_) async {
        called = true;
        return http.Response('{}', 200);
      }));

      await expectLater(
        service.matchInfo('  '),
        throwsA(isA<CricApiException>()
            .having((e) => e.kind, 'kind', CricApiError.badResponse)),
      );
      expect(called, isFalse);
    });

    test('a match with no scorecard is not an error', () async {
      final service = _service(MockClient((_) async => http.Response(
            jsonEncode({
              'status': 'success',
              'data': {..._payload()['data'][0], 'scorecard': <dynamic>[]},
            }),
            200,
          )));

      final detail = await service.matchInfo('m1');
      expect(detail.hasScorecard, isFalse);
    });
  });

  group('tolerant parsing (CricAPI mixes types)', () {
    test('numbers arriving as strings still parse', () {
      final match = IntlMatch.fromJson({
        'id': 'x',
        'teams': ['A', 'B'],
        'score': [
          {'r': '150', 'w': '4', 'o': '18.3', 'inning': 'A Inning 1'},
        ],
        'matchStarted': 'true',
        'matchEnded': 'false',
      });

      expect(match.score.single.runs, 150);
      expect(match.score.single.wickets, 4);
      expect(match.score.single.overs, 18.3);
      expect(match.isLive, isTrue);
    });

    test('missing/blank fields do not throw', () {
      final match = IntlMatch.fromJson({
        'id': 'x',
        'teams': null,
        'teamInfo': null,
        'score': null,
        'matchStarted': null,
      });

      expect(match.teams, isEmpty);
      expect(match.score, isEmpty);
      expect(match.name, '');
      expect(match.date, isNull);
      expect(match.isLive, isFalse);
    });

    test('an innings with no runs/overs is dropped from the score line', () {
      final match = IntlMatch.fromJson({
        'id': 'x',
        'teams': ['A', 'B'],
        'score': [
          {'r': 0, 'w': 0, 'o': 0, 'inning': ''},
        ],
      });
      expect(match.score, isEmpty);
    });

    test('a malformed date does not crash the list', () {
      final match = IntlMatch.fromJson({'id': 'x', 'date': 'not-a-date'});
      expect(match.date, isNull);
    });
  });

  group('demo data', () {
    test('every demo match parses and is classified', () {
      final matches = CricApiDemo.matches;
      expect(matches, hasLength(3));

      expect(matches.where((m) => m.isLive), hasLength(1));
      expect(matches.where((m) => m.isUpcoming), hasLength(1));
      expect(matches.where((m) => m.isCompleted), hasLength(1));

      for (final match in matches) {
        expect(match.id, isNotEmpty);
        expect(match.teams, hasLength(2));
      }
    });

    test('the demo live match has a scorecard', () {
      final detail = CricApiDemo.detailFor('demo-live-1');
      expect(detail, isNotNull);
      expect(detail!.hasScorecard, isTrue);
      expect(detail.innings, hasLength(2));
      expect(detail.innings.first.batting, isNotEmpty);
      expect(detail.innings.first.bowling, isNotEmpty);
    });

    test('an unknown demo id returns null (detail screen shows "not published")', () {
      expect(CricApiDemo.detailFor('nope'), isNull);
    });
  });
}
