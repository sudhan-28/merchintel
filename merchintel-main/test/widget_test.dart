import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:merchintel/features/auth/login_screen.dart';

void main() {
  testWidgets('login screen renders without overflow on a short viewport',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 392));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(find.text('Shelf Intelligence'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
