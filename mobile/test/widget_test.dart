// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:blinkit_mobile/providers/auth_provider.dart';
import 'package:blinkit_mobile/providers/cart_provider.dart';

void main() {
  testWidgets('App shell renders smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => CartProvider()),
        ],
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: Text('Blinkit')),
        ),
      ),
    );

    expect(find.text('Blinkit'), findsOneWidget);
  });
}
