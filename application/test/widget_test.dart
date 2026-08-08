// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:application/main.dart';

void main() {
  testWidgets('About Us button displays application information', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.byTooltip('About Us'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Electric and Weather'), findsOneWidget);
    expect(find.text('Phát triển bởi Nhóm 22 - CT220H.'), findsOneWidget);
  });
}
