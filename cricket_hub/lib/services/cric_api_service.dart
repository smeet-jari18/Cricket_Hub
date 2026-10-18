import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/intl_match.dart';

/// Why a CricAPI call failed. The UI turns this into a localized message —
/// the service never builds user-facing English text.
enum CricApiError {
  /// No `--dart-define=CRICAPI_KEY` at build time. Not a crash: the screen
  /// offers demo data instead.
  missingKey,

  /// CricAPI said no (wrong/expired key).
  invalidKey,

  /// Daily quota gone (free tier is ~100 hits/day).
  rateLimited,

  /// No network, DNS failure, timeout.
  network,

  /// 5xx, HTML instead of JSON, `status != success`, unparseable body.
  badResponse,
}

class CricApiException implements Exception {
  const CricApiException(this.kind, {this.detail});

  final CricApiError kind;
  final String? detail;

  @override
  String toString() => 'CricApiException(${kind.name}${detail == null ? '' : ': $detail'})';
}

/// Client for [CricAPI](https://cricapi.com) — the Phase-4 source of
/// international fixtures and scores (PRD US-10).
///
/// Design notes:
/// * **The key comes from the build, not from Firestore.** `--dart-define`
///   keeps it out of the repo (`.gitignore` cannot protect a hardcoded string).
///   In production the sane long-term move is a Cloud Function proxy so the key
///   never ships inside the APK; that is a Blaze-plan change, documented in
///   `PHASE4_ANALYSIS.md`.
/// * **Cached for [cacheTtl].** The free tier is ~100 hits/day; a pull-to-refresh
///   loop would burn it in minutes. Every screen rebuild reads the cache.
/// * **Failure is typed, never a raw string.** See [CricApiError].
class CricApiService {
  CricApiService({
    http.Client? client,
    String? apiKey,
    Duration cacheTtl = const Duration(minutes: 5),
    DateTime Function()? clock,
  })  : _client = client ?? http.Client(),
        _apiKey = apiKey ?? compileTimeKey,
        _cacheTtl = cacheTtl,
        _clock = clock ?? DateTime.now;

  /// Set at build time: `flutter run --dart-define=CRICAPI_KEY=xxxx`.
  static const String compileTimeKey = String.fromEnvironment('CRICAPI_KEY');

  static const String _host = 'api.cricapi.com';
  static const Duration _timeout = Duration(seconds: 12);

  final http.Client _client;
  final String _apiKey;
  final Duration _cacheTtl;
  final DateTime Function() _clock;

  List<IntlMatch>? _cachedMatches;
  DateTime? _cachedAt;

  bool get hasKey => _apiKey.trim().isNotEmpty;

  /// True when the last list came from the cache (the UI shows a soft hint).
  bool get isServingCache {
    final at = _cachedAt;
    if (at == null || _cachedMatches == null) return false;
    return _clock().difference(at) < _cacheTtl;
  }

  /// Live + recent + upcoming matches. CricAPI returns all three in one call.
  Future<List<IntlMatch>> currentMatches({bool forceRefresh = false}) async {
    final at = _cachedAt;
    if (!forceRefresh && at != null && _cachedMatches != null) {
      if (_clock().difference(at) < _cacheTtl) return _cachedMatches!;
    }

    final json = await _get('/v1/currentMatches', {'offset': '0'});
    final data = json['data'];
    if (data is! List) {
      throw const CricApiException(
        CricApiError.badResponse,
        detail: 'currentMatches payload had no data list',
      );
    }

    final matches = data
        .whereType<Map>()
        .map((m) => IntlMatch.fromJson(Map<String, dynamic>.from(m)))
        .where((m) => m.id.isNotEmpty)
        .toList();

    _cachedMatches = matches;
    _cachedAt = _clock();
    return matches;
  }

  /// Full match + scorecard for the detail screen.
  Future<IntlMatchDetail> matchInfo(String matchId) async {
    if (matchId.trim().isEmpty) {
      throw const CricApiException(CricApiError.badResponse, detail: 'empty match id');
    }
    final json = await _get('/v1/match_info', {'id': matchId});
    final data = json['data'];
    if (data is! Map) {
      throw const CricApiException(
        CricApiError.badResponse,
        detail: 'match_info payload had no data object',
      );
    }
    return IntlMatchDetail.fromJson(Map<String, dynamic>.from(data));
  }

  /// Visible for tests — drops the TTL cache.
  void clearCache() {
    _cachedMatches = null;
    _cachedAt = null;
  }

  // ── internals ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _get(String path, Map<String, String> query) async {
    if (!hasKey) {
      throw const CricApiException(CricApiError.missingKey);
    }

    final uri = Uri.https(_host, path, {'apikey': _apiKey, ...query});

    late http.Response response;
    try {
      response = await _client.get(uri).timeout(_timeout);
    } on TimeoutException catch (e) {
      throw CricApiException(CricApiError.network, detail: e.toString());
    } on http.ClientException catch (e) {
      throw CricApiException(CricApiError.network, detail: e.message);
    } on Exception catch (e) {
      // SocketException & friends — dart:io is not imported so that this file
      // stays usable on web builds.
      throw CricApiException(CricApiError.network, detail: e.toString());
    }

    if (response.statusCode == 429) {
      throw const CricApiException(CricApiError.rateLimited);
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const CricApiException(CricApiError.invalidKey);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CricApiException(
        CricApiError.badResponse,
        detail: 'HTTP ${response.statusCode}',
      );
    }

    Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        throw const FormatException('not an object');
      }
      json = Map<String, dynamic>.from(decoded);
    } on FormatException catch (e) {
      throw CricApiException(CricApiError.badResponse, detail: e.message);
    }

    // CricAPI reports key/quota problems *inside* a 200 response.
    final status = json['status']?.toString().toLowerCase();
    if (status == 'failure') {
      final reason = json['reason']?.toString() ?? '';
      final lower = reason.toLowerCase();
      if (lower.contains('invalid api key') ||
          lower.contains('api key') ||
          lower.contains('key')) {
        throw CricApiException(CricApiError.invalidKey, detail: reason);
      }
      if (lower.contains('limit') || lower.contains('quota') || lower.contains('hit')) {
        throw CricApiException(CricApiError.rateLimited, detail: reason);
      }
      throw CricApiException(CricApiError.badResponse, detail: reason);
    }

    return json;
  }
}
