import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:money_challenge/domain/datasources/slot_datasource.dart';
import 'package:money_challenge/domain/entities/slot.dart';

/// Implementación de [SlotDataSource] sobre una caja de Hive.
///
/// La caja `'slots'` debe estar abierta antes de usarla (la abre `main()`).
///
/// Sincronía (importante): Hive actualiza la caja **en memoria de forma
/// síncrona** y la persistencia en disco ocurre en segundo plano. Por eso las
/// escrituras devuelven `void` y se descarta el futuro: esperarlo no añade
/// nada a la UI y, en un entorno de test, bloquearía el hilo para siempre.
class HiveSlotDataSource implements SlotDataSource {
  HiveSlotDataSource({this.boxName = 'slots'});

  final String boxName;

  Box<Slot> get _box => Hive.box<Slot>(boxName);

  @override
  List<Slot> getSlots() => _box.values.toList();

  @override
  Slot? getSlot(String id) {
    for (final slot in _box.values) {
      if (slot.id == id) return slot;
    }
    return null;
  }

  @override
  void putSlot(Slot slot) => _ignoreDisk(_box.put(slot.id, slot));

  @override
  void putSlots(List<Slot> slots) {
    if (slots.isEmpty) return;
    _ignoreDisk(_box.putAll({for (final slot in slots) slot.id: slot}));
  }

  @override
  void resetSlots() {
    // Solo desmarca: se reescribe cada casilla con `checked: false`
    // conservando id y monto (no se borra la box).
    _ignoreDisk(
      _box.putAll({
        for (final slot in _box.values) slot.id: slot.copyWith(checked: false),
      }),
    );
  }

  @override
  void deleteSlot(String id) => _ignoreDisk(_box.delete(id));

  /// La memoria ya está actualizada al salir de aquí; solo se engancha un
  /// manejador para que un fallo de disco no se escape como error no
  /// controlado. No se espera el resultado a propósito.
  void _ignoreDisk(Future<void> persistence) {
    persistence.catchError((Object error) {
      debugPrint('Hive: no se pudo persistir "$boxName": $error');
    });
  }
}
