import 'package:money_challenge/domain/datasources/slot_datasource.dart';
import 'package:money_challenge/domain/entities/slot.dart';
import 'package:money_challenge/domain/repositories/savings_repository.dart';

/// Implementación de [SavingsRepository] sobre un [SlotDataSource].
///
/// Es el traductor entre el contrato de dominio y el concreto; hoy delega
/// directamente, pero es el punto donde se añadiría caché o mapeo si hiciera
/// falta sin tocar la capa de dominio.
class SavingsRepositoryImpl implements SavingsRepository {
  const SavingsRepositoryImpl(this._dataSource);

  final SlotDataSource _dataSource;

  @override
  List<Slot> getSlots() => _dataSource.getSlots();

  @override
  Slot? getSlot(String id) => _dataSource.getSlot(id);

  @override
  void saveSlot(Slot slot) => _dataSource.putSlot(slot);

  @override
  void saveSlots(List<Slot> slots) => _dataSource.putSlots(slots);

  @override
  void resetSlots() => _dataSource.resetSlots();

  @override
  void deleteSlot(String id) => _dataSource.deleteSlot(id);
}
