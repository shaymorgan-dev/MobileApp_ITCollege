// Базовая проверка: приложение собирается без ошибок.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:expenses_app/main.dart';

void main() {
  testWidgets('Приложение запускается', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}