import 'package:money_challenge/domain/entities/slot.dart';

/// Contrato de persistencia del ahorro (interfaz en domain).
///
/// La implementación concreta vive en
/// `lib/infrastructure/repositories/savings_repository_impl.dart`.
///
/// El repository es la puerta que usan los casos de uso; nunca hablan con el
/// datasource directamente. Sigue el mismo contrato de sincronía que
/// [SlotDataSource]: lecturas síncronas y escrituras que aplican en memoria
/// de inmediato sin esperar el disco.
abstract class SavingsRepository {
  /// Devuelve todas las casillas.
  List<Slot> getSlots();

  /// Devuelve una casilla por su [id], o `null` si no existe.
  Slot? getSlot(String id);

  /// Guarda (inserta o reemplaza) una casilla.
  void saveSlot(Slot slot);

  /// Guarda varias casillas en lote.
  void saveSlots(List<Slot> slots);

  /// Pone `checked: false` en todas las casillas (reset del ahorro).
  void resetSlots();

  /// Elimina la casilla con el [id] dado.
  void deleteSlot(String id);

  /// Montos de los grupos completados que el usuario dejó contraídos.
  Set<double> getCollapsedGroups();

  /// Marca o desmarca el grupo de monto [amount] como contraído.
  void setGroupCollapsed(double amount, {required bool collapsed});
}
