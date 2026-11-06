import 'package:money_challenge/domain/repositories/savings_repository.dart';

/// Devuelve los montos de los grupos completados que el usuario contrajo.
class GetCollapsedGroups {
  const GetCollapsedGroups(this._repository);

  final SavingsRepository _repository;

  Set<double> call() => _repository.getCollapsedGroups();
}
