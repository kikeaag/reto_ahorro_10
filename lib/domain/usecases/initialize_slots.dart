import 'package:money_challenge/domain/entities/denomination_group.dart';
import 'package:money_challenge/domain/entities/slot.dart';
import 'package:money_challenge/domain/repositories/savings_repository.dart';

/// Caso de uso: crear las casillas en el primer arranque y reconciliarlas con
/// [denominationGroups] en cada arranque posterior.
///
/// Reglas de reconciliación (ver AGENTS.md):
///  - Cada grupo debe terminar con **exactamente** `group.slots` casillas.
///  - El estado `checked` de las casillas existentes **se preserva siempre**.
///  - Sobrantes (índice fuera de rango, id malformado o duplicado) → se borran.
///  - Faltantes (índices de `1..group.slots` ausentes) → se crean sin marcar.
class InitializeSlots {
  const InitializeSlots(this._repository);

  final SavingsRepository _repository;

  void call() {
    final existing = _repository.getSlots();

    if (existing.isEmpty) {
      _repository.saveSlots([
        for (final group in denominationGroups)
          for (var i = 1; i <= group.slots; i++)
            Slot(
              id: '${group.amount}_$i',
              checked: false,
              amount: group.amount,
            ),
      ]);
      return;
    }

    _reconcile(existing);
  }

  /// Reconcilia [existing] con [denominationGroups] sin tocar ningún
  /// `checked` existente.
  void _reconcile(List<Slot> existing) {
    final existingIds = existing.map((slot) => slot.id).toSet();
    final toDelete = <String>[];
    final toCreate = <Slot>[];

    for (final group in denominationGroups) {
      // Índices válidos ya ocupados en este grupo.
      final taken = <int>{};

      for (final slot in existing) {
        if (slot.amount != group.amount) continue;
        final index = _indexOf(slot.id);
        final isValid =
            index != null && index >= 1 && index <= group.slots;
        // `taken.add` devuelve `false` si el índice ya estaba ocupado: en ese
        // caso esta casilla es duplicada y también sobra.
        if (isValid && taken.add(index)) continue;
        toDelete.add(slot.id);
      }

      for (var i = 1; i <= group.slots; i++) {
        if (taken.contains(i)) continue;
        toCreate.add(Slot(
          id: '${group.amount}_$i',
          checked: false,
          amount: group.amount,
        ));
      }
    }

    // Primero se liberan las sobrantes (sus índices pueden reutilizarse) y
    // después se crean las faltantes, sin pisar ningún id que siga existiendo.
    for (final id in toDelete) {
      _repository.deleteSlot(id);
      existingIds.remove(id);
    }

    final missing =
        toCreate.where((slot) => !existingIds.contains(slot.id)).toList();
    if (missing.isNotEmpty) _repository.saveSlots(missing);
  }

  /// Índice de una casilla a partir de su id (`{monto}_{índice}`), o `null`
  /// si el id no tiene ese formato.
  int? _indexOf(String id) {
    final parts = id.split('_');
    if (parts.length != 2) return null;
    return int.tryParse(parts[1]);
  }
}
