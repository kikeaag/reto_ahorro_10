import 'package:flutter/foundation.dart';
import 'package:money_challenge/domain/entities/savings_summary.dart';
import 'package:money_challenge/domain/usecases/get_savings_summary.dart';
import 'package:money_challenge/domain/usecases/get_slots.dart';
import 'package:money_challenge/domain/usecases/initialize_slots.dart';
import 'package:money_challenge/domain/usecases/toggle_slot.dart';

/// Estado de la pantalla principal, expuesto a la UI con `provider`.
///
/// Toda la lógica vive en casos de uso; el controlador solo los orquesta y
/// publica el [SavingsSummary] resultante. No usa `setState`: la UI se repinta
/// con `notifyListeners()` (ver AGENTS.md).
class HomeController extends ChangeNotifier {
  HomeController(
    this._initializeSlots,
    this._getSlots,
    this._toggleSlot,
    this._getSavingsSummary,
  );

  final InitializeSlots _initializeSlots;
  final GetSlots _getSlots;
  final ToggleSlot _toggleSlot;
  final GetSavingsSummary _getSavingsSummary;

  SavingsSummary? _summary;
  bool _initialized = false;

  /// Resumen actual; `null` mientras no se haya inicializado (estado de carga).
  SavingsSummary? get summary => _summary;

  /// Crea (o reconcilia) las casillas y calcula el primer resumen.
  ///
  /// Es idempotente y **no notifica**: se invoca desde `initState`, es decir,
  /// en plena fase de build, donde el `build` siguiente leerá [summary]
  /// directamente. Notificar ahí provocaría un repintado durante el build.
  void init() {
    if (_initialized) return;
    _initialized = true;
    _initializeSlots();
    _summary = _getSavingsSummary(_getSlots());
  }

  /// Marca/desmarca la casilla [id] y notifica a la UI para que repinte.
  ///
  /// El caso de toggle nunca llama a `setState` (ver AGENTS.md): la escritura
  /// se aplica en memoria y el repinte llega por `notifyListeners()`.
  void toggle(String id) {
    _toggleSlot(id);
    _summary = _getSavingsSummary(_getSlots());
    notifyListeners();
  }
}
