// test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';

import 'package:circl/main.dart';

void main() {
  testWidgets('Circl app launches to the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const CirclApp());

    expect(find.text('Circl'), findsOneWidget);
    expect(find.text('Discover People Around You'), findsOneWidget);
  });
}
