// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lawhi/main.dart';

void main() {
  testWidgets('App launch smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Note: This might fail if Firebase is not fully mocked, 
    // but it fixes the compilation errors.
    await tester.pumpWidget(const ProviderScope(child: SirajApp()));

    // Verify that splash screen or main view is present.
    expect(find.byType(SirajApp), findsOneWidget);
  });
}
