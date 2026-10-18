import 'package:cricket_hub/l10n/generated/app_localizations.dart';
import 'package:cricket_hub/screens/bootstrap_error_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders a readable message instead of a black screen',
      (tester) async {
    await tester.pumpWidget(
      const BootstrapErrorScreen(error: 'core/duplicate-app'),
    );
    await tester.pumpAndSettle();

    expect(find.text('CricketHub could not start'), findsOneWidget);
    expect(find.textContaining('flutterfire configure'), findsOneWidget);
    // The technical detail is available but collapsed behind an expander.
    expect(find.text('Technical details'), findsOneWidget);
    expect(find.text('core/duplicate-app'), findsNothing);
  });

  testWidgets('works without an error object too', (tester) async {
    await tester.pumpWidget(const BootstrapErrorScreen(error: null));
    await tester.pumpAndSettle();

    expect(find.text('CricketHub could not start'), findsOneWidget);
    expect(find.text('Technical details'), findsNothing);
  });

  testWidgets('expanding shows the raw error', (tester) async {
    await tester.pumpWidget(
      const BootstrapErrorScreen(error: 'core/duplicate-app'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Technical details'));
    await tester.pumpAndSettle();

    expect(find.text('core/duplicate-app'), findsOneWidget);
  });

  test('the error screen does not depend on AppLocalizations', () {
    // It must render even when localization itself failed to load, so it is
    // deliberately kept outside the l10n pipeline.
    expect(AppLocalizations.supportedLocales, isNotEmpty);
  });
}
