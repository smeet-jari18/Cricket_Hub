// Fills lib/firebase_options.dart with the REAL Firebase values that are
// already sitting on your machine, without installing the Firebase CLI.
//
// Why this exists: `flutterfire configure` needs `firebase-tools`, and without
// it the CLI stops with "FirebaseCommandException: ... firebase --version".
// But if `android/app/google-services.json` (and/or
// `ios/Runner/GoogleService-Info.plist`) is already there — which is exactly
// the case when the Google Services Gradle plugin is building your app — then
// the real apiKey / appId / senderId are already on disk. This script copies
// them into the Dart file.
//
//   dart run tools/sync_firebase_options.dart
//   dart run tools/sync_firebase_options.dart --check    (report, change nothing)
//
// It only rewrites the keys it can prove; anything else is left untouched.
import 'dart:convert';
import 'dart:io';

const _placeholder = 'AIzaSyPLACEHOLDER';

void main(List<String> args) {
  final root = _projectRoot(args);
  final checkOnly = args.contains('--check');

  final optionsFile = File('$root/lib/firebase_options.dart');
  if (!optionsFile.existsSync()) {
    _fail('lib/firebase_options.dart not found in $root');
  }

  final sources = <String, _Config>{};

  final androidJson = File('$root/android/app/google-services.json');
  if (androidJson.existsSync()) {
    final config = _fromGoogleServicesJson(androidJson, root);
    if (config != null) sources['android'] = config;
  }

  final iosPlist = File('$root/ios/Runner/GoogleService-Info.plist');
  if (iosPlist.existsSync()) {
    final config = _fromGoogleServiceInfoPlist(iosPlist);
    if (config != null) sources['ios'] = config;
  }

  if (sources.isEmpty) {
    _fail(
      'No platform config found.\n'
      '  Looked for: android/app/google-services.json\n'
      '              ios/Runner/GoogleService-Info.plist\n'
      'Get one from Firebase Console → Project settings → Your apps, or use\n'
      '  flutterfire configure --project=<your-project>',
    );
  }

  var source = optionsFile.readAsStringSync();
  final applied = <String>[];

  for (final entry in sources.entries) {
    final patched = _patchBlock(source, entry.key, entry.value);
    if (patched != source) {
      source = patched;
      applied.add(entry.key);
    }
  }

  if (applied.isEmpty) {
    stdout.writeln('Nothing to change — blocks already match the platform '
        'config files (${sources.keys.join(', ')}).');
  }

  if (checkOnly) {
    stdout.writeln('--check: no files were written.');
    _report(source, sources);
    return;
  }

  optionsFile.writeAsStringSync(source);
  stdout.writeln('Updated lib/firebase_options.dart for: '
      '${applied.isEmpty ? '(no changes)' : applied.join(', ')}');
  _report(source, sources);
}

// ───────────────────────────────────────────────────────────────────────────

class _Config {
  const _Config({
    required this.apiKey,
    required this.appId,
    required this.senderId,
    required this.projectId,
    required this.storageBucket,
    this.bundleId,
  });

  final String apiKey;
  final String appId;
  final String senderId;
  final String projectId;
  final String storageBucket;
  final String? bundleId;
}

String _projectRoot(List<String> args) {
  final explicit = args.where((a) => !a.startsWith('--')).toList();
  if (explicit.isNotEmpty) return explicit.first;
  // Default: the current directory, or its parent if we are inside tools/.
  final cwd = Directory.current.path;
  if (File('$cwd/lib/firebase_options.dart').existsSync()) return cwd;
  if (File('$cwd/../lib/firebase_options.dart').existsSync()) {
    return Directory('$cwd/..').path;
  }
  return cwd;
}

_Config? _fromGoogleServicesJson(File file, String root) {
  Map<String, dynamic> json;
  try {
    json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  } catch (e) {
    _fail('android/app/google-services.json is not valid JSON: $e');
  }

  final projectInfo =
      (json['project_info'] as Map?)?.cast<String, dynamic>() ?? const {};
  final clients = (json['client'] as List?) ?? const [];
  if (clients.isEmpty) return null;

  // Prefer the client whose package_name matches the app's applicationId.
  final applicationId = _applicationId(root);
  Map<String, dynamic>? client;
  for (final raw in clients) {
    final map = (raw as Map).cast<String, dynamic>();
    final info =
        (map['client_info'] as Map?)?.cast<String, dynamic>() ?? const {};
    final android =
        (info['android_client_info'] as Map?)?.cast<String, dynamic>() ?? const {};
    if (applicationId != null && android['package_name'] == applicationId) {
      client = map;
      break;
    }
  }
  client ??= (clients.first as Map).cast<String, dynamic>();

  final clientInfo =
      (client['client_info'] as Map?)?.cast<String, dynamic>() ?? const {};
  final apiKeys = (client['api_key'] as List?) ?? const [];
  final firstKey = apiKeys.isEmpty
      ? const <String, dynamic>{}
      : (apiKeys.first as Map).cast<String, dynamic>();

  final apiKey = (firstKey['current_key'] as String?) ?? '';
  if (apiKey.isEmpty) return null;

  return _Config(
    apiKey: apiKey,
    appId: (clientInfo['mobilesdk_app_id'] as String?) ?? '',
    senderId: '${projectInfo['project_number'] ?? ''}',
    projectId: (projectInfo['project_id'] as String?) ?? '',
    storageBucket: (projectInfo['storage_bucket'] as String?) ?? '',
  );
}

_Config? _fromGoogleServiceInfoPlist(File file) {
  final text = file.readAsStringSync();

  String? valueOf(String key) {
    final match = RegExp(
      '<key>$key</key>\\s*<string>([^<]*)</string>',
      multiLine: true,
    ).firstMatch(text);
    return match?.group(1)?.trim();
  }

  final apiKey = valueOf('API_KEY') ?? '';
  if (apiKey.isEmpty) return null;

  return _Config(
    apiKey: apiKey,
    appId: valueOf('GOOGLE_APP_ID') ?? '',
    senderId: valueOf('GCM_SENDER_ID') ?? '',
    projectId: valueOf('PROJECT_ID') ?? '',
    storageBucket: valueOf('STORAGE_BUCKET') ?? '',
    bundleId: valueOf('BUNDLE_ID'),
  );
}

String? _applicationId(String root) {
  final gradle = File('$root/android/app/build.gradle.kts');
  final classic = File('$root/android/app/build.gradle');
  final file = gradle.existsSync() ? gradle : (classic.existsSync() ? classic : null);
  if (file == null) return null;
  final match = RegExp(
    r'''applicationId\s*=?\s*["']([^"']+)["']''',
  ).firstMatch(file.readAsStringSync());
  return match?.group(1);
}

/// Replaces the fields of `static const FirebaseOptions <platform> = ...`.
String _patchBlock(String source, String platform, _Config config) {
  final startMatch = RegExp(
    'static const FirebaseOptions $platform = FirebaseOptions\\(',
  ).firstMatch(source);
  if (startMatch == null) return source;

  final start = startMatch.start;
  final close = source.indexOf(');', start);
  if (close == -1) return source;
  final block = source.substring(start, close + 2);

  var patched = block;
  void set(String field, String? value) {
    if (value == null || value.isEmpty) return;
    final pattern = RegExp("$field: '[^']*'");
    if (pattern.hasMatch(patched)) {
      patched = patched.replaceFirst(pattern, "$field: '$value'");
    } else {
      // Field missing from the block — insert before the closing paren.
      final insertAt = patched.lastIndexOf(');');
      patched = '${patched.substring(0, insertAt)}'
          "  $field: '$value',\n  )${patched.substring(insertAt + 2)}";
    }
  }

  set('apiKey', config.apiKey);
  set('appId', config.appId);
  set('messagingSenderId', config.senderId);
  set('projectId', config.projectId);
  set('storageBucket', config.storageBucket);
  if (platform == 'ios' || platform == 'macos') {
    set('iosBundleId', config.bundleId);
  }

  return source.replaceRange(start, close + 2, patched);
}

void _report(String source, Map<String, _Config> sources) {
  stdout.writeln('');
  stdout.writeln('Project: ${sources.values.first.projectId}');
  for (final entry in sources.entries) {
    final config = entry.value;
    stdout.writeln('  ${entry.key.padRight(7)} appId=${config.appId}');
    stdout.writeln('          apiKey=${_mask(config.apiKey)}');
  }

  // Only count real values, not the placeholder text quoted in the file header.
  final placeholders =
      RegExp("apiKey: '$_placeholder").allMatches(source).length;
  stdout.writeln('');
  if (placeholders == 0) {
    stdout.writeln('✅ No placeholder keys left in lib/firebase_options.dart.');
  } else {
    stdout.writeln('⚠️  $placeholders placeholder key(s) still present — those '
        'platforms have no config file on disk.');
    stdout.writeln('   Android-only setup is fine for phone testing; add the '
        'others later with flutterfire configure.');
  }
}

String _mask(String key) {
  if (key.length <= 10) return key;
  return '${key.substring(0, 8)}…${key.substring(key.length - 4)}';
}

Never _fail(String message) {
  stderr.writeln('✖ $message');
  exit(1);
}
