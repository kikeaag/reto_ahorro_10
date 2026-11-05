import 'package:money_challenge/domain/entities/denomination_group.dart';
import 'package:money_challenge/domain/entities/slot.dart';

/// Resumen calculado del ahorro, listo para consumir desde la presentación.
///
/// Se calcula en **un solo pasagge** sobre la lista de slots (ver AGENTS.md:
/// reglas de rendimiento).
class SavingsSummary {
  const SavingsSummary({
    required this.total,
    required this.percent,
    required this.totalSlots,
    required this.groups,
  });

  /// Suma de los montos de las casillas con `checked == true`.
  final double total;

  /// Progreso: `total / goal * 100` con `clamp(0, 100)`.
  final double percent;

  /// Total de casillas (todas, sin importar el estado).
  final int totalSlots;

  /// Progreso por grupo, en el mismo orden que [denominationGroups].
  final List<GroupProgress> groups;

  /// Calcula el resumen a partir de [slots] en un solo pasagge.
  factory SavingsSummary.fromSlots(List<Slot> slots) {
    double total = 0;
    int totalSlots = 0;

    // Índice de casillas por monto (un solo pasagge).
    final byAmount = <double, List<Slot>>{};
    for (final slot in slots) {
      totalSlots++;
      if (slot.checked) total += slot.amount;
      (byAmount[slot.amount] ??= <Slot>[]).add(slot);
    }

    final percent = (total / goal * 100).clamp(0.0, 100.0);

    final groups = <GroupProgress>[
      for (final group in denominationGroups)
        GroupProgress.fromGroup(group, byAmount[group.amount] ?? const []),
    ];

    return SavingsSummary(
      total: total,
      percent: percent,
      totalSlots: totalSlots,
      groups: groups,
    );
  }
}

/// Progreso de un grupo de denominación.
class GroupProgress {
  const GroupProgress({
    required this.amount,
    required this.targetSlots,
    required this.checkedSlots,
    required this.slots,
  });

  factory GroupProgress.fromGroup(DenominationGroup group, List<Slot> slots) {
    var checked = 0;
    for (final slot in slots) {
      if (slot.checked) checked++;
    }
    return GroupProgress(
      amount: group.amount,
      targetSlots: group.slots,
      checkedSlots: checked,
      slots: slots,
    );
  }

  /// Monto del grupo (ej. 5).
  final double amount;

  /// Casillas objetivo según `denominationGroups` (ej. 40).
  final int targetSlots;

  /// Casillas marcadas de este grupo.
  final int checkedSlots;

  /// Casillas reales de este grupo, listas para pintar.
  final List<Slot> slots;
}
