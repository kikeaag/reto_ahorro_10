import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:money_challenge/domain/entities/slot.dart';
import 'package:money_challenge/domain/usecases/get_collapsed_groups.dart';
import 'package:money_challenge/domain/usecases/get_savings_summary.dart';
import 'package:money_challenge/domain/usecases/get_slots.dart';
import 'package:money_challenge/domain/usecases/initialize_slots.dart';
import 'package:money_challenge/domain/usecases/reset_slots.dart';
import 'package:money_challenge/domain/usecases/set_group_collapsed.dart';
import 'package:money_challenge/domain/usecases/toggle_slot.dart';
import 'package:money_challenge/infrastructure/datasources/hive_slot_datasource.dart';
import 'package:money_challenge/infrastructure/models/slot_model.dart';
import 'package:money_challenge/infrastructure/repositories/savings_repository_impl.dart';
import 'package:money_challenge/presentation/controllers/home_controller.dart';
import 'package:money_challenge/presentation/screens/splash_screen.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(SlotAdapter());
  await Hive.openBox<Slot>('slots');
  await Hive.openBox<bool>('collapsed_groups');

  runApp(const MyApp());
}

/// Raíz de composición: aquí se ensambla el grafo de dependencias
/// (datasource → repository → casos de uso → controlador).
HomeController buildHomeController() {
  final dataSource = HiveSlotDataSource();
  final repository = SavingsRepositoryImpl(dataSource);
  // Orden: crear/reconciliar, leer, alternar, calcular el resumen.
  return HomeController(
    InitializeSlots(repository),
    GetSlots(repository),
    ToggleSlot(repository),
    const GetSavingsSummary(),
    ResetSlots(repository),
    GetCollapsedGroups(repository),
    SetGroupCollapsed(repository),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Use the official Material 3 lilac (seed/demo) color exactly as primary.
    // Hex: #6750A4
    final baseColor = const Color(0xFF6750A4);
    var colorScheme = ColorScheme.fromSeed(seedColor: baseColor);
    // Ensure the primary token uses the exact lilac hex requested.
    colorScheme = colorScheme.copyWith(primary: baseColor, onPrimary: Colors.white);

    return ChangeNotifierProvider(
      create: (_) => buildHomeController(),
      child: MaterialApp(
        title: 'Alcancía 5k',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          // Fuente de toda la app: Roboto, la oficial de Material 3
          // (declarada en pubspec.yaml).
          fontFamily: 'Roboto',
          colorScheme: colorScheme,
          checkboxTheme: CheckboxThemeData(
            // When selected, use the exact Material 3 lilac color.
            // When unselected, use a subdued onSurface color.
            fillColor: WidgetStateProperty.resolveWith<Color?>((states) {
              if (states.contains(WidgetState.selected)) {
                return baseColor;
              }
              // Use withAlpha instead of deprecated withOpacity.
              return colorScheme.onSurface.withAlpha((0.6 * 255).round());
            }),
            // Make the check icon contrast against the filled color.
            checkColor: WidgetStateProperty.all(Colors.white),
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
