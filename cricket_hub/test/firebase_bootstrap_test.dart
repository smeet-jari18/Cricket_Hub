import 'package:cricket_hub/core/firebase_bootstrap.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression tests for the black-screen bug.
///
/// On a real device `google-services.json` creates the `[DEFAULT]` FirebaseApp
/// natively. Calling `Firebase.initializeApp(options: …)` with different
/// options (the placeholder `firebase_options.dart`) then threw
/// `[core/duplicate-app]` inside `main()`, so `runApp()` never executed and the
/// phone showed a black screen. These tests pin the behaviour that fixed it.
void main() {
  test('adopts an app the native SDK already created', () async {
    var initializeCalls = 0;

    final result = await bootstrapFirebase(
      existingProjectId: () => 'crickethub-dev',
      initialize: () async {
        initializeCalls++;
        return 'crickethub-dev';
      },
    );

    expect(result.ready, isTrue);
    expect(result.adoptedExisting, isTrue);
    expect(result.projectId, 'crickethub-dev');
    expect(initializeCalls, 0,
        reason: 'must not try to create a second [DEFAULT] app');
  });

  test('initializes normally when nothing exists yet', () async {
    var initializeCalls = 0;

    final result = await bootstrapFirebase(
      existingProjectId: () => null,
      initialize: () async {
        initializeCalls++;
        return 'crickethub-dev';
      },
    );

    expect(result.ready, isTrue);
    expect(result.adoptedExisting, isFalse);
    expect(initializeCalls, 1);
  });

  test('survives the race where the app appears between check and init',
      () async {
    // First read: nothing. Then the plugin reports the app after the throw —
    // exactly the duplicate-app case that used to crash the app.
    var reads = 0;

    final result = await bootstrapFirebase(
      existingProjectId: () {
        reads++;
        return reads == 1 ? null : 'crickethub-dev';
      },
      initialize: () async {
        throw FirebaseException(
          plugin: 'firebase_core',
          code: 'duplicate-app',
          message: 'A Firebase App named "[DEFAULT]" already exists',
        );
      },
    );

    expect(result.ready, isTrue);
    expect(result.adoptedExisting, isTrue);
    expect(result.projectId, 'crickethub-dev');
  });

  test('falls back to an options-free attach when the app list is unreadable',
      () async {
    // Worst case: `Firebase.apps` cannot see the native app (plugin race) yet
    // initialize still says duplicate-app. Without this branch the app would
    // show the error screen even though a perfectly good native app exists.
    var attachCalls = 0;

    final result = await bootstrapFirebase(
      existingProjectId: () => throw StateError('plugin not ready'),
      initialize: () async {
        throw FirebaseException(
          plugin: 'firebase_core',
          code: 'duplicate-app',
          message: 'A Firebase App named "[DEFAULT]" already exists',
        );
      },
      adoptExisting: () async {
        attachCalls++;
        return 'crickethub-dev';
      },
    );

    expect(attachCalls, 1);
    expect(result.ready, isTrue);
    expect(result.adoptedExisting, isTrue);
    expect(result.projectId, 'crickethub-dev');
  });

  test('a failing options-free attach still reports the original error',
      () async {
    final result = await bootstrapFirebase(
      existingProjectId: () => null,
      initialize: () async {
        throw FirebaseException(
          plugin: 'firebase_core',
          code: 'duplicate-app',
          message: 'A Firebase App named "[DEFAULT]" already exists',
        );
      },
      adoptExisting: () async => throw Exception('still nothing'),
    );

    expect(result.ready, isFalse);
    expect((result.error! as FirebaseException).code, 'duplicate-app');
  });

  test('a duplicate-app error with nothing to adopt is a clean failure',
      () async {
    final result = await bootstrapFirebase(
      existingProjectId: () => null,
      initialize: () async {
        throw FirebaseException(
          plugin: 'firebase_core',
          code: 'duplicate-app',
          message: 'A Firebase App named "[DEFAULT]" already exists',
        );
      },
    );

    expect(result.ready, isFalse);
    expect(result.error, isA<FirebaseException>());
  });

  test('any other Firebase error is reported, never swallowed', () async {
    final result = await bootstrapFirebase(
      existingProjectId: () => null,
      initialize: () async {
        throw FirebaseException(
          plugin: 'firebase_core',
          code: 'invalid-api-key',
          message: 'API key not valid',
        );
      },
    );

    expect(result.ready, isFalse);
    expect(
      (result.error! as FirebaseException).code,
      'invalid-api-key',
    );
  });

  test('a throwing app-list probe does not crash the bootstrap', () async {
    final result = await bootstrapFirebase(
      existingProjectId: () => throw StateError('plugin not registered'),
      initialize: () async => 'crickethub-dev',
    );

    expect(result.ready, isTrue);
    expect(result.adoptedExisting, isFalse);
  });

  test('an empty project id counts as "no app"', () async {
    var initializeCalls = 0;
    final result = await bootstrapFirebase(
      existingProjectId: () => '',
      initialize: () async {
        initializeCalls++;
        return 'crickethub-dev';
      },
    );

    expect(initializeCalls, 1);
    expect(result.ready, isTrue);
  });

  test('the failure result carries the error object for the error screen', () async {
    final error = Exception('boom');
    final result = await bootstrapFirebase(
      existingProjectId: () => null,
      initialize: () async => throw error,
    );

    expect(result.ready, isFalse);
    expect(result.error, same(error));
    expect(result.projectId, isNull);
  });
}
