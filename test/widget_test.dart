import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test mock', (WidgetTester tester) async {
    // A simple test to verify testing framework works without
    // running into sqflite platform channel exceptions.
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('Sanket Notes Mock'))));

    expect(find.text('Sanket Notes Mock'), findsOneWidget);
  });
}
