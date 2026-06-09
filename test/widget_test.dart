import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spectroom/screens/home_screen.dart';
import 'package:spectroom/theme.dart';

void main() {
  testWidgets('Home shows seeded challenges', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildSpectroomTheme(),
      home: const HomeScreen(),
    ));
    await tester.pumpAndSettle();

    // Library title + at least one built-in challenge card.
    expect(find.text('Spectroom'), findsOneWidget);
    expect(find.text('Stříhání nehtů'), findsOneWidget);
  });
}
