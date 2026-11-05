import 'package:money_challenge/domain/repositories/savings_repository.dart';

/// Caso de uso: marcar/desmarcar una casilla (toggle de `checked`).
///
/// Es la única escritura que dispara la UI (ver AGENTS.md: la interacción es
/// solo toggle; no hay edición de montos ni borrado desde la UI).
class ToggleSlot {
  const ToggleSlot(this._repository);

  final SavingsRepository _repository;

  /// Alterna el estado de la casilla con el [id] dado.
  /// No hace nada si la casilla no existe.
  void call(String id) {
    final slot = _repository.getSlot(id);
    if (slot == null) return;
    _repository.saveSlot(slot.copyWith(checked: !slot.checked));
  }
}
