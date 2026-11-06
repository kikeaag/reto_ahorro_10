import 'package:flutter/foundation.dart';
import 'package:money_challenge/domain/entities/denomination_group.dart';
import 'package:money_challenge/domain/entities/savings_summary.dart';
import 'package:money_challenge/domain/usecases/get_collapsed_groups.dart';
import 'package:money_challenge/domain/usecases/get_savings_summary.dart';
import 'package:money_challenge/domain/usecases/get_slots.dart';
import 'package:money_challenge/domain/usecases/initialize_slots.dart';
import 'package:money_challenge/domain/usecases/reset_slots.dart';
import 'package:money_challenge/domain/usecases/set_group_collapsed.dart';
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
    this._resetSlots, [
    this._getCollapsedGroups,
    this._setGroupCollapsed,
  ]);

  final InitializeSlots _initializeSlots;
  final GetSlots _getSlots;
  final ToggleSlot _toggleSlot;
  final GetSavingsSummary _getSavingsSummary;
  final ResetSlots _resetSlots;
  final GetCollapsedGroups? _getCollapsedGroups;
  final SetGroupCollapsed? _setGroupCollapsed;

  SavingsSummary? _summary;
  Set<double> _collapsedGroups = <double>{};
  bool _initialized = false;

  /// Resumen actual; `null` mientras no se haya inicializado (estado de carga).
  SavingsSummary? get summary => _summary;

  /// Montos de los grupos completados que están actualmente contraídos.
  Set<double> get collapsedGroups => _collapsedGroups;

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
    _collapsedGroups = _getCollapsedGroups?.call() ?? <double>{};
    _pruneIncompleteCollapsedGroups();
  }

  /// Alterna el estado contraído del grupo de monto [amount] y lo persiste.
  void toggleGroupCollapsed(double amount) {
    final nextCollapsed = !_collapsedGroups.contains(amount);
    if (nextCollapsed) {
      _collapsedGroups = {..._collapsedGroups, amount};
    } else {
      _collapsedGroups = {..._collapsedGroups}..remove(amount);
    }
    _setGroupCollapsed?.call(amount, collapsed: nextCollapsed);
    notifyListeners();
  }

  void _pruneIncompleteCollapsedGroups() {
    final currentSummary = _summary;
    if (currentSummary == null || _collapsedGroups.isEmpty) return;
    final completedAmounts = <double>{
      for (final g in currentSummary.groups)
        if (g.targetSlots > 0 && g.checkedSlots == g.targetSlots) g.amount,
    };
    final toRemove = _collapsedGroups.difference(completedAmounts);
    if (toRemove.isEmpty) return;
    for (final amount in toRemove) {
      _setGroupCollapsed?.call(amount, collapsed: false);
    }
    _collapsedGroups = _collapsedGroups.intersection(completedAmounts);
  }

  /// Marca/desmarca la casilla [id] y notifica a la UI para que repinte.
  ///
  /// El caso de toggle nunca llama a `setState` (ver AGENTS.md): la escritura
  /// se aplica en memoria y el repinte llega por `notifyListeners()`.
  ///
  /// Devuelve `true` solo cuando este toque **cruza la meta**: el total pasó
  /// de menor que [goal] a [goal] o más. Así la pantalla principal sabe que
  /// debe mostrar la felicitaciones sin tener que calcular el umbral ella.
  /// (Al iniciar ya completada no hay cruce, así que `init()` nunca lo
  /// activa: la celebración es exclusiva de marcar la última casilla.)
  bool toggle(String id) {
    final before = _summary?.total ?? 0;
    _toggleSlot(id);
    _summary = _getSavingsSummary(_getSlots());
    _pruneIncompleteCollapsedGroups();
    notifyListeners();
    return before < goal && _summary!.total >= goal;
  }

  /// Desmarca todas las casillas y publica el resumen en cero.
  ///
  /// Se invoca desde el botón "Iniciar nueva alcancía" de la pantalla de
  /// felicitaciones, **antes** de navegar al home: `init()` es idempotente
  /// y no recalcularía el resumen, así que sin este paso la pantalla nueva
  /// mostraría el total viejo.
  void reset() {
    _resetSlots();
    _collapsedGroups = <double>{};
    _summary = _getSavingsSummary(_getSlots());
    notifyListeners();
  }
}
