import 'package:money_challenge/domain/repositories/savings_repository.dart';

/// Caso de uso: reiniciar el ahorro (desmarcar todas las casillas).
///
/// Es la **única** operación que limpia `checked` y solo se invoca desde el
/// botón "Iniciar nueva alcancía" de la pantalla de felicitaciones
/// (ver AGENTS.md). No borra la box: los ids y los conteos se conservan.
class ResetSlots {
  const ResetSlots(this._repository);

  final SavingsRepository _repository;

  /// Desmarca todas las casillas (`checked: false`).
  void call() => _repository.resetSlots();
}
