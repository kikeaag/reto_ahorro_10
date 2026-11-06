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

    expect(find.text('Alcancía 5k'), findsOneWidget);
    expect(find.text('0.00 %'), findsOneWidget);
    expect(find.text('Monedas de \$5'), findsOneWidget);
    expect(find.text('Billetes de \$20', skipOffstage: false), findsOneWidget);
    expect(find.text('Casillas totales: 0 / 184'), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -200));
    await tester.pump();

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.savings),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('\$0'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('colapsa y expande un grupo completado desde su encabezado',
      (WidgetTester tester) async {
    // Marcar las 56 casillas de $5 directamente en la box (el grupo queda
    // completado: 56 / 56).
    final box = Hive.box<Slot>('slots');
    for (var i = 1; i <= 56; i++) {
      final id = '5.0_$i';
      final slot = box.get(id);
      if (slot != null) box.put(id, slot.copyWith(checked: true));
    }

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('56 / 56'), findsOneWidget);
    expect(find.text('5'), findsWidgets);

    // Contraer: solo debe quedar el encabezado, sin casillas.
    await tester.tap(find.text('Monedas de \$5'));
    await tester.pumpAndSettle();

    expect(find.text('Monedas de \$5'), findsOneWidget);
    expect(find.text('56 / 56'), findsOneWidget);
    expect(find.text('5'), findsNothing);

    // Volver a expandir.
    await tester.tap(find.text('Monedas de \$5'));
    await tester.pumpAndSettle();

    expect(find.text('5'), findsWidgets);
  });
}
