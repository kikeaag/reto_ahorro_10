import 'package:money_challenge/domain/entities/slot.dart';

/// Contrato de acceso a datos de casillas (interfaz en domain).
///
/// La implementación concreta vive en
/// `lib/infrastructure/datasources/hive_slot_datasource.dart`.
///
/// Contrato de sincronía:
///  - **Las lecturas son síncronas**: las casillas viven en memoria.
///  - **Las escrituras aplican en memoria de forma síncrona** y persisten en
///    segundo plano. Por eso devuelven `void` y **no deben esperarse**: la
///    I/O de disco no tiene por qué terminar antes de que la UI pinte.
abstract class SlotDataSource {
  /// Todas las casillas actuales.
  List<Slot> getSlots();

  /// La casilla con el [id] dado, o `null` si no existe.
  Slot? getSlot(String id);

  /// Inserta o reemplaza una casilla por su id.
  void putSlot(Slot slot);

  /// Inserta o reemplaza varias casillas en lote.
  void putSlots(List<Slot> slots);

  /// Elimina la casilla con el [id] dado (no hace nada si no existe).
  void deleteSlot(String id);
}
