import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:money_challenge/domain/entities/slot.dart';
import 'package:money_challenge/infrastructure/models/slot_model.dart';
import 'package:money_challenge/main.dart';
import 'package:money_challenge/presentation/screens/goal_reached_screen.dart';
import 'package:money_challenge/presentation/screens/home_screen.dart';
import 'package:money_challenge/presentation/utils/app_download_links.dart';

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

  testWidgets('al marcar la última casilla se muestra la felicitación',
      (WidgetTester tester) async {
    // Asegura que las 184 casillas existan en la box (`init` es idempotente).
    final box = Hive.box<Slot>('slots');
    if (box.isEmpty) {
      // Caso de test en solitario: arranca la app una vez para que `init`
      // cree las casillas y descarta el árbol, de modo que el build "real"
      // del test cree un controlador nuevo.
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }

    // Marca todas las casillas menos la primera (`5.0_1`, $5) y desmarca
    // esa por si un test anterior la dejó marcada: el total queda en
    // $4,995 y el toque pendiente es el que cruza la meta.
    for (final key in box.keys.toList()) {
      final slot = box.get(key);
      if (slot == null) continue;
      final shouldBeChecked = key != '5.0_1';
      if (slot.checked != shouldBeChecked) {
        box.put(key, slot.copyWith(checked: shouldBeChecked));
      }
    }

    // Pantalla "real" del test: un controlador nuevo (el árbol anterior fue
    // desmontado) lee la box con 183 / 184 = $4,995.
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Casillas totales: 183 / 184'), findsOneWidget);

    final firstSlot = find.byKey(const ValueKey('5.0_1'));
    await tester.ensureVisible(firstSlot);
    await tester.pump();
    await tester.tap(firstSlot);
    await tester.pump(); // inicia pushReplacement

    // Pumps acotados en lugar de `pumpAndSettle`: el confeti hace loop y
    // el settle nunca terminaría.
    await tester.pump(const Duration(milliseconds: 400)); // transición
    await tester.pump(const Duration(seconds: 1)); // entrada del contenido

    expect(find.byType(GoalReachedScreen), findsOneWidget);
    expect(find.text('¡Felicidades!'), findsOneWidget);
    expect(find.text('Has alcanzado la meta de \$5,000'), findsOneWidget);
    expect(find.text('100.00 %'), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('el botón "Iniciar nueva alcancía" resetea y vuelve al home',
      (WidgetTester tester) async {
    // Deja la box en 183 / 184 (todas marcadas menos `5.0_1`), igual que el
    // test anterior: el toque pendiente es el que cruza la meta.
    final box = Hive.box<Slot>('slots');
    for (final key in box.keys.toList()) {
      final slot = box.get(key);
      if (slot == null) continue;
      final shouldBeChecked = key != '5.0_1';
      if (slot.checked != shouldBeChecked) {
        box.put(key, slot.copyWith(checked: shouldBeChecked));
      }
    }

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Casillas totales: 183 / 184'), findsOneWidget);

    // Alcanza la meta para llegar a la pantalla de felicitaciones.
    await tester.ensureVisible(find.byKey(const ValueKey('5.0_1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('5.0_1')));
    // Pumps acotados: el confeti hace loop y `pumpAndSettle` colgaría.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(GoalReachedScreen), findsOneWidget);

    // Inicia una alcancía nueva: resetea la box y navega al home.
    await tester.tap(find.text('Iniciar nueva alcancía'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400)); // transición
    // Pumps acotados (no `pumpAndSettle`): por seguridad evitamos depender
    // de cuándo desmonta la ruta saliente, que aún lleva el confeti en loop.
    await tester.pump(const Duration(seconds: 3)); // arranque del home (2 s)

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(GoalReachedScreen), findsNothing);
    expect(find.text('Casillas totales: 0 / 184'), findsOneWidget);
    expect(find.text('0.00 %'), findsOneWidget);
    expect(find.text('\$0'), findsWidgets);

    // La bd quedó con todas las casillas desmarcadas (sin borrar ids).
    expect(box.keys, hasLength(184));
    expect(box.values.every((slot) => !slot.checked), isTrue);
  });

  testWidgets('el botón "Compartir logro" comparte texto + imagen sin navegar',
      (WidgetTester tester) async {
    // Mock del canal de share_plus (la hoja de compartir del sistema).
    final shareCalls = <MethodCall>[];
    final messenger = TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/share'),
      (call) async {
        shareCalls.add(call);
        return null;
      },
    );

    // Llega a la meta: todas marcadas menos `5.0_1`.
    final box = Hive.box<Slot>('slots');
    for (final key in box.keys.toList()) {
      final slot = box.get(key);
      if (slot == null) continue;
      final shouldBeChecked = key != '5.0_1';
      if (slot.checked != shouldBeChecked) {
        box.put(key, slot.copyWith(checked: shouldBeChecked));
      }
    }

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const ValueKey('5.0_1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('5.0_1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(GoalReachedScreen), findsOneWidget);

    await tester.tap(find.text('Compartir logro'));
    await tester.pump();

    // La captura (rasterizado del PNG + escritura del temporal) corre en
    // hilos reales: se da tiempo real y luego se drenan los microtareas del
    // tiempo ficticio hasta que el share se emita.
    for (var i = 0; i < 8 && shareCalls.isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)),
      );
      await tester.pump();
    }

    expect(shareCalls, hasLength(1));
    expect(shareCalls.single.method, 'share');
    final args = shareCalls.single.arguments as Map;
    expect(args['text'], contains('¡Alcancé mi meta de ahorro!'));
    expect(args['text'], contains('\$5,000'));
    expect(args['text'], contains('184/184'));
    // Las ligas de descarga viajan dentro del texto (`text` y `uri` son
    // excluyentes en share_plus).
    expect(args['text'], contains(kPlayStoreUrl));
    expect(args['text'], contains(kAppStoreUrl));
    expect(args['title'], 'Alcancía 5k');
    // Adjunta la captura de la pantalla como PNG.
    expect(args['paths'], isA<List>());
    expect((args['paths'] as List), hasLength(1));

    // Compartir no navega: seguimos en la felicitación.
    expect(find.byType(GoalReachedScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);

    messenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/share'),
      null,
    );
  });
}
