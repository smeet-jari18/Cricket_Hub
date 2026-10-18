/// Typed model for the CricAPI (`cricapi.com`) responses used by the
/// International Match Center.
///
/// CricAPI is a third-party API: fields come and go, numbers sometimes arrive
/// as strings, and `score` is missing until a match starts. Every parser here
/// is written to survive that — a single weird match must not blank the whole
/// screen (see `test/cric_api_service_test.dart`).
library;

class IntlTeamInfo {
  const IntlTeamInfo({required this.name, this.shortName = '', this.imageUrl = ''});

  final String name;
  final String shortName;
  final String imageUrl;

  factory IntlTeamInfo.fromJson(Map<String, dynamic> json) {
    return IntlTeamInfo(
      name: _str(json['name']),
      shortName: _str(json['shortname']),
      imageUrl: _str(json['img']),
    );
  }
}

/// One innings line, e.g. `India Inning 1 — 280/8 (50.0)`.
class IntlInnings {
  const IntlInnings({
    required this.inning,
    required this.runs,
    required this.wickets,
    required this.overs,
  });

  final String inning;
  final int runs;
  final int wickets;

  /// Overs are fractional in cricket (45.2 = 45 overs 2 balls), so this stays
  /// a double / string — never an int.
  final double overs;

  bool get hasScore => overs > 0 || runs > 0;

  String get scoreLabel {
    final o = overs == overs.roundToDouble()
        ? overs.toStringAsFixed(0)
        : overs.toStringAsFixed(1);
    return '$runs/$wickets ($o)';
  }

  factory IntlInnings.fromJson(Map<String, dynamic> json) {
    return IntlInnings(
      inning: _str(json['inning']),
      runs: _int(json['r']),
      wickets: _int(json['w']),
      overs: _double(json['o']),
    );
  }
}

/// A match as shown on the list screen (and the header of the detail screen).
class IntlMatch {
  const IntlMatch({
    required this.id,
    required this.name,
    required this.matchType,
    required this.status,
    required this.venue,
    required this.date,
    required this.teams,
    required this.teamInfo,
    required this.score,
    required this.matchStarted,
    required this.matchEnded,
  });

  final String id;
  final String name;
  final String matchType;
  final String status;
  final String venue;
  final DateTime? date;
  final List<String> teams;
  final List<IntlTeamInfo> teamInfo;
  final List<IntlInnings> score;
  final bool matchStarted;
  final bool matchEnded;

  bool get isLive => matchStarted && !matchEnded;
  bool get isUpcoming => !matchStarted;
  bool get isCompleted => matchEnded;

  /// Short names in the same order as [teams] — used for the score chips.
  String shortNameFor(String teamName) {
    for (final info in teamInfo) {
      if (info.name == teamName) {
        return info.shortName.isNotEmpty ? info.shortName : _abbrev(teamName);
      }
    }
    return _abbrev(teamName);
  }

  String imageFor(String teamName) {
    for (final info in teamInfo) {
      if (info.name == teamName) return info.imageUrl;
    }
    return '';
  }

  /// The innings CricAPI returns are in batting order, so innings[0] belongs to
  /// teams[0] in the common case. The innings label is used only when CricAPI
  /// actually provides one that names a team.
  String inningsLabel(IntlInnings innings) {
    if (innings.inning.isNotEmpty) return innings.inning;
    return innings.inning;
  }

  factory IntlMatch.fromJson(Map<String, dynamic> json) {
    final rawTeams = json['teams'];
    final teams = rawTeams is List
        ? rawTeams.map((t) => _str(t)).where((t) => t.isNotEmpty).toList()
        : <String>[];

    final rawInfo = json['teamInfo'];
    final teamInfo = rawInfo is List
        ? rawInfo
            .whereType<Map>()
            .map((t) => IntlTeamInfo.fromJson(Map<String, dynamic>.from(t)))
            .toList()
        : <IntlTeamInfo>[];

    final rawScore = json['score'];
    final score = rawScore is List
        ? rawScore
            .whereType<Map>()
            .map((s) => IntlInnings.fromJson(Map<String, dynamic>.from(s)))
            .where((s) => s.hasScore)
            .toList()
        : <IntlInnings>[];

    return IntlMatch(
      id: _str(json['id']),
      name: _str(json['name']),
      matchType: _str(json['matchType']),
      status: _str(json['status']),
      venue: _str(json['venue']),
      date: _date(json['dateTimeGMT']) ?? _date(json['date']),
      teams: teams,
      teamInfo: teamInfo,
      score: score,
      matchStarted: _bool(json['matchStarted']),
      matchEnded: _bool(json['matchEnded']),
    );
  }
}

/// `/v1/match_info` — the match plus its scorecard.
class IntlMatchDetail {
  const IntlMatchDetail({required this.match, required this.innings});

  final IntlMatch match;
  final List<IntlInningsScorecard> innings;

  bool get hasScorecard =>
      innings.any((i) => i.batting.isNotEmpty || i.bowling.isNotEmpty);

  factory IntlMatchDetail.fromJson(Map<String, dynamic> json) {
    final raw = json['scorecard'];
    final innings = raw is List
        ? raw
            .whereType<Map>()
            .map((i) => IntlInningsScorecard.fromJson(Map<String, dynamic>.from(i)))
            .toList()
        : <IntlInningsScorecard>[];

    return IntlMatchDetail(
      match: IntlMatch.fromJson(json),
      innings: innings,
    );
  }
}

class IntlInningsScorecard {
  const IntlInningsScorecard({
    required this.inning,
    required this.batting,
    required this.bowling,
  });

  final String inning;
  final List<IntlBattingLine> batting;
  final List<IntlBowlingLine> bowling;

  factory IntlInningsScorecard.fromJson(Map<String, dynamic> json) {
    final rawBat = json['batting'];
    final rawBowl = json['bowling'];
    return IntlInningsScorecard(
      inning: _str(json['inning']),
      batting: rawBat is List
          ? rawBat
              .whereType<Map>()
              .map((b) => IntlBattingLine.fromJson(Map<String, dynamic>.from(b)))
              .toList()
          : const [],
      bowling: rawBowl is List
          ? rawBowl
              .whereType<Map>()
              .map((b) => IntlBowlingLine.fromJson(Map<String, dynamic>.from(b)))
              .toList()
          : const [],
    );
  }
}

class IntlBattingLine {
  const IntlBattingLine({
    required this.name,
    required this.runs,
    required this.balls,
    required this.fours,
    required this.sixes,
    required this.strikeRate,
    required this.dismissal,
  });

  final String name;
  final int runs;
  final int balls;
  final int fours;
  final int sixes;
  final double strikeRate;
  final String dismissal;

  factory IntlBattingLine.fromJson(Map<String, dynamic> json) {
    return IntlBattingLine(
      name: _nestedName(json['batsman']) ?? _str(json['batsman']),
      runs: _int(json['r']),
      balls: _int(json['b']),
      fours: _int(json['4s']),
      sixes: _int(json['6s']),
      strikeRate: _double(json['sr']),
      dismissal: _str(json['dismissal']),
    );
  }
}

class IntlBowlingLine {
  const IntlBowlingLine({
    required this.name,
    required this.overs,
    required this.maidens,
    required this.runs,
    required this.wickets,
    required this.economy,
  });

  final String name;
  final double overs;
  final int maidens;
  final int runs;
  final int wickets;
  final double economy;

  factory IntlBowlingLine.fromJson(Map<String, dynamic> json) {
    return IntlBowlingLine(
      name: _nestedName(json['bowler']) ?? _str(json['bowler']),
      overs: _double(json['o']),
      maidens: _int(json['m']),
      runs: _int(json['r']),
      wickets: _int(json['w']),
      economy: _double(json['eco']),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Tolerant primitives — CricAPI mixes types between endpoints.
// ───────────────────────────────────────────────────────────────────────────

String _str(Object? value) {
  if (value == null) return '';
  if (value is String) return value;
  return value.toString();
}

int _int(Object? value) {
  if (value is int) return value;
  if (value is double) return value.round();
  if (value is String) return int.tryParse(value) ?? double.tryParse(value)?.round() ?? 0;
  return 0;
}

double _double(Object? value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

bool _bool(Object? value) {
  if (value is bool) return value;
  if (value is String) return value.toLowerCase() == 'true';
  return false;
}

DateTime? _date(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value)?.toLocal();
}

String? _nestedName(Object? value) {
  if (value is Map) {
    final name = value['name'];
    if (name is String && name.isNotEmpty) return name;
  }
  return null;
}

String _abbrev(String team) {
  final words = team.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  if (words.isEmpty) return '';
  if (words.length == 1) {
    final single = words.first;
    return single.length <= 3 ? single.toUpperCase() : single.substring(0, 3).toUpperCase();
  }
  return words.take(3).map((w) => w[0]).join().toUpperCase();
}
