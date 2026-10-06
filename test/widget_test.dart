import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spartial_touch/features/help/help_screen.dart';

void main() {
  testWidgets('Help screen lists every guide section and expands one', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HelpScreen()));

    for (final title in ['Getting started', 'Using gestures', 'Custom gestures', 'Troubleshooting']) {
      await tester.scrollUntilVisible(find.text(title), 100);
      expect(find.text(title), findsOneWidget);
    }

    await tester.scrollUntilVisible(find.text('Getting started'), -100);
    await tester.tap(find.text('Getting started'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Accessibility Service'), findsWidgets);
  });
}
