import 'package:money_challenge/domain/entities/slot.dart';
import 'package:money_challenge/domain/repositories/savings_repository.dart';

/// Caso de uso: leer el estado actual de las casillas.
///
/// Lectura síncrona (las casillas viven en memoria); el caso de uso la entrega
/// tal cual para que [GetSavingsSummary] pueda calcular el resumen.
class GetSlots {
  const GetSlots(this._repository);

  final SavingsRepository _repository;

  List<Slot> call() => _repository.getSlots();
}
