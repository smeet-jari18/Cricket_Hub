import 'package:firebase_core/firebase_core.dart';

/// Result of bringing Firebase up, in a shape the UI can act on.
class FirebaseBootstrapResult {
  const FirebaseBootstrapResult._({
    required this.ready,
    required this.adoptedExisting,
    this.projectId,
    this.error,
  });

  /// Firebase is usable; safe to call `runApp` with the real app.
  const FirebaseBootstrapResult.ready({
    required bool adoptedExisting,
    String? projectId,
  }) : this._(ready: true, adoptedExisting: adoptedExisting, projectId: projectId);

  /// Firebase could not be started. The caller must show an error screen —
  /// **not** call the normal `runApp`, and **not** swallow this.
  const FirebaseBootstrapResult.failed(Object error)
      : this._(ready: false, adoptedExisting: false, error: error);

  final bool ready;

  /// True when the app was already created by the native SDK (see below)
  /// and we attached to it instead of initializing a second one.
  final bool adoptedExisting;

  final String? projectId;
  final Object? error;
}

/// Brings Firebase up exactly once, without ever crashing the app on the
/// `duplicate-app` race.
///
/// ## Why this exists
///
/// On Android, `com.google.gms.google-services` creates the `[DEFAULT]`
/// FirebaseApp **natively at process start**, from `google-services.json`.
/// `Firebase.initializeApp(options: ...)` then calls
/// `FirebaseApp.initializeApp(context, options, "[DEFAULT]")`, which throws
/// `IllegalStateException` when an app with that name already exists **with
/// different options** — surfaced in Dart as `[core/duplicate-app]`.
///
/// That is exactly what happens when `lib/firebase_options.dart` is the
/// placeholder (apiKey `AIzaSyPLACEHOLDER-…`) while `google-services.json`
/// holds the real key. `main()` threw, `runApp()` never ran, and the phone
/// showed a black screen.
///
/// The native app is the correct one (it came from `google-services.json`), so
/// we adopt it. `initialize` is only called when no app exists at all.
///
/// [existingProjectId] returns the project id of an already-created app, or
/// null. [initialize] creates the app and returns its project id.
/// Both are injected so this logic is testable without Firebase.
/// [adoptExisting] is the last resort: `Firebase.initializeApp()` **without**
/// options attaches to whatever the native layer already created. It is only
/// needed when `existingProjectId()` itself cannot see the native app (plugin
/// race) — rare, but it is the difference between "app starts" and "black
/// screen", so it is worth the extra branch.
Future<FirebaseBootstrapResult> bootstrapFirebase({
  required String? Function() existingProjectId,
  required Future<String?> Function() initialize,
  Future<String?> Function()? adoptExisting,
  void Function(String message)? log,
}) async {
  final logger = log ?? _noop;

  // 1. Native auto-init (google-services.json / GoogleService-Info.plist).
  String? existing;
  try {
    existing = existingProjectId();
  } catch (e) {
    // Plugin not ready yet — treat as "nothing exists" and try the explicit
    // path below, which will surface a real error if anything is wrong.
    logger('Could not read existing Firebase apps: $e');
    existing = null;
  }

  if (existing != null && existing.isNotEmpty) {
    logger('Firebase already initialised natively for "$existing" — adopting it.');
    return FirebaseBootstrapResult.ready(
      adoptedExisting: true,
      projectId: existing,
    );
  }

  // 2. No app yet (iOS without plist, desktop, tests, or a fresh project).
  try {
    final projectId = await initialize();
    return FirebaseBootstrapResult.ready(
      adoptedExisting: false,
      projectId: projectId,
    );
  } on FirebaseException catch (e) {
    // 3. Lost the race: the native app appeared between the check and the call.
    if (e.code == 'duplicate-app') {
      try {
        final now = existingProjectId();
        if (now != null && now.isNotEmpty) {
          logger('Race on Firebase init — adopting the native "$now" app.');
          return FirebaseBootstrapResult.ready(
            adoptedExisting: true,
            projectId: now,
          );
        }
      } catch (_) {
        // The app list is not readable yet; try the options-free attach below.
      }

      if (adoptExisting != null) {
        try {
          final projectId = await adoptExisting();
          logger('Attached to the existing [DEFAULT] app without options.');
          return FirebaseBootstrapResult.ready(
            adoptedExisting: true,
            projectId: projectId,
          );
        } on Exception catch (attachError) {
          logger('Options-free attach failed: $attachError');
        }
      }
    }
    return FirebaseBootstrapResult.failed(e);
  } on Exception catch (e) {
    return FirebaseBootstrapResult.failed(e);
  }
}

void _noop(String message) {}
