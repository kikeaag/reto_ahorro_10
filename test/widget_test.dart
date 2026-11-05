import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:money_challenge/domain/entities/slot.dart';
import 'package:money_challenge/infrastructure/models/slot_model.dart';
import 'package:money_challenge/main.dart';

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (MethodCall methodCall) async => Directory.systemTemp.path,
  );

  await Hive.initFlutter();
  Hive.registerAdapter(SlotAdapter());
  await Hive.deleteBoxFromDisk('slots');
  await Hive.openBox<Slot>('slots');

  testWidgets('renders the separated alcancía groups', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('10k Challenge'), findsOneWidget);
    expect(find.text('0.00 %'), findsOneWidget);
    expect(find.text('Monedas de \$5'), findsOneWidget);
    expect(find.text('Casillas totales: 228'), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -200));
    await tester.pump();

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Total guardado: \$0.00'),
      ),
      findsOneWidget,
    );
  });
}
