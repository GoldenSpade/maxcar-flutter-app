// Basic Flutter widget test for MaxCar Tracker

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:maxcar_tracker/app/app.dart';

void main() {
  testWidgets('MaxCar app loads', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: MaxCarApp(),
      ),
    );

    // Verify that the app loads with a progress indicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
