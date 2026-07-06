import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safesignal/main.dart';

void main() {
  testWidgets('SafeSignal app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SafeSignalApp()));
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
