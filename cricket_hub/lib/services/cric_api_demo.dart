import '../models/intl_match.dart';

/// Bundled sample data for the International screen.
///
/// Why ship this at all: without `--dart-define=CRICAPI_KEY` the feature would
/// be a dead screen in every dev build and on every new device. The demo lets
/// someone see the layout, and — more useful for us — it exercises the **same
/// parser** as live data, so a model regression shows up without hitting the
/// API.
///
/// The UI labels this loudly ("Demo data — add a CricAPI key for live scores"),
/// so nobody mistakes it for real scores.
class CricApiDemo {
  CricApiDemo._();

  /// Parsed through [IntlMatch.fromJson] on every call — not a typed const —
  /// so demo data can never silently drift from the real response shape.
  static List<IntlMatch> get matches =>
      _rawMatches.map((m) => IntlMatch.fromJson(m)).toList();

  static IntlMatchDetail? detailFor(String id) {
    final raw = _rawDetails[id];
    if (raw == null) return null;
    return IntlMatchDetail.fromJson(raw);
  }

  static final List<Map<String, dynamic>> _rawMatches = [
    {
      'id': 'demo-live-1',
      'name': 'India vs Australia, 3rd ODI',
      'matchType': 'odi',
      'status': 'India need 43 runs in 36 balls',
      'venue': 'Wankhede Stadium, Mumbai',
      'date': '2026-10-18',
      'dateTimeGMT': '2026-10-18T08:00:00',
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
      'id': 'demo-upcoming-1',
      'name': 'England vs South Africa, 2nd Test',
      'matchType': 'test',
      'status': 'Match not started',
      'venue': "Lord's, London",
      'date': '2026-10-21',
      'dateTimeGMT': '2026-10-21T10:00:00',
      'teams': ['England', 'South Africa'],
      'teamInfo': [
        {'name': 'England', 'shortname': 'ENG', 'img': ''},
        {'name': 'South Africa', 'shortname': 'SA', 'img': ''},
      ],
      'score': <Map<String, dynamic>>[],
      'matchStarted': false,
      'matchEnded': false,
    },
    {
      'id': 'demo-done-1',
      'name': 'Pakistan vs New Zealand, 1st T20I',
      'matchType': 't20',
      'status': 'Pakistan won by 6 wickets',
      'venue': 'Gaddafi Stadium, Lahore',
      'date': '2026-10-16',
      'dateTimeGMT': '2026-10-16T15:00:00',
      'teams': ['Pakistan', 'New Zealand'],
      'teamInfo': [
        {'name': 'Pakistan', 'shortname': 'PAK', 'img': ''},
        {'name': 'New Zealand', 'shortname': 'NZ', 'img': ''},
      ],
      'score': [
        {'r': 164, 'w': 9, 'o': 20, 'inning': 'New Zealand Inning 1'},
        {'r': 168, 'w': 4, 'o': 18.4, 'inning': 'Pakistan Inning 1'},
      ],
      'matchStarted': true,
      'matchEnded': true,
    },
  ];

  static final Map<String, Map<String, dynamic>> _rawDetails = {
    'demo-live-1': {
      ..._rawMatches[0],
      'tossWinner': 'Australia',
      'tossChoice': 'bat',
      'scorecard': [
        {
          'inning': 'Australia Inning 1',
          'batting': [
            {
              'batsman': {'id': 'd1', 'name': 'DA Warner'},
              'r': 62,
              'b': 54,
              '4s': 7,
              '6s': 2,
              'sr': 114.8,
              'dismissal': 'c Kohli b Siraj',
            },
            {
              'batsman': {'id': 'd2', 'name': 'SPD Smith'},
              'r': 88,
              'b': 79,
              '4s': 9,
              '6s': 1,
              'sr': 111.4,
              'dismissal': 'not out',
            },
            {
              'batsman': {'id': 'd3', 'name': 'M Labuschagne'},
              'r': 41,
              'b': 39,
              '4s': 3,
              '6s': 0,
              'sr': 105.1,
              'dismissal': 'lbw b Kuldeep Yadav',
            },
          ],
          'bowling': [
            {
              'bowler': {'id': 'd4', 'name': 'Mohammed Siraj'},
              'o': 10,
              'm': 1,
              'r': 48,
              'w': 3,
              'eco': 4.8,
            },
            {
              'bowler': {'id': 'd5', 'name': 'Kuldeep Yadav'},
              'o': 10,
              'm': 0,
              'r': 52,
              'w': 2,
              'eco': 5.2,
            },
          ],
        },
        {
          'inning': 'India Inning 1',
          'batting': [
            {
              'batsman': {'id': 'd6', 'name': 'RG Sharma'},
              'r': 71,
              'b': 63,
              '4s': 8,
              '6s': 3,
              'sr': 112.7,
              'dismissal': 'c Carey b Hazlewood',
            },
            {
              'batsman': {'id': 'd7', 'name': 'V Kohli'},
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
              'bowler': {'id': 'd8', 'name': 'JR Hazlewood'},
              'o': 9,
              'm': 1,
              'r': 44,
              'w': 2,
              'eco': 4.9,
            },
          ],
        },
      ],
    },
  };
}
