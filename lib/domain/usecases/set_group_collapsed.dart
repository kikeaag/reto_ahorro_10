import 'package:money_challenge/domain/repositories/savings_repository.dart';

/// Persiste si el grupo de monto [amount] está contraído o expandido.
class SetGroupCollapsed {
  const SetGroupCollapsed(this._repository);

  final SavingsRepository _repository;

  void call(double amount, {required bool collapsed}) =>
      _repository.setGroupCollapsed(amount, collapsed: collapsed);
}
