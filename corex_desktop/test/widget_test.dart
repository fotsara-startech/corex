// This is a basic Flutter widget test for COREX Desktop.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:corex_desktop/main.dart';

void main() {
  testWidgets('COREX Desktop app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CorexDesktopApp());

    // Verify that the login screen is displayed
    expect(find.text('COREX'), findsWidgets);

    // Since this is a complex app with Firebase initialization,
    // we just verify the app builds without crashing
    await tester.pumpAndSettle();
  });
}
