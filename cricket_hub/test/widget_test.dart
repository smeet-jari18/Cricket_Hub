import 'package:cricket_hub/widgets/score_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ScoreButton renders its label', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              ScoreButton(label: '4', onTap: () {}),
            ],
          ),
        ),
      ),
    );

    expect(find.text('4'), findsOneWidget);
  });
}
