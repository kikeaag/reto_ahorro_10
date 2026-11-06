/// Agrupación de denominaciones del reto: un monto y cuántas casillas tiene.
///
/// [denominationGroups] es la **fuente única de verdad** de la configuración
/// del reto. Invariantes (ver AGENTS.md):
///  - La suma de `monto * casillas` debe ser exactamente [goal] ($5,000).
///  - La suma de `casillas` debe ser 184 (está hardcodeado en el test).
class DenominationGroup {
  const DenominationGroup({required this.amount, required this.slots});

  /// Monto de la moneda (ej. 5, 10, 20...).
  final double amount;

  /// Cantidad de casillas de este monto.
  final int slots;
}

/// Meta global del reto: $5,000.00.
const double goal = 5000.0;

/// Denominaciones del reto. Fuente única de verdad.
const List<DenominationGroup> denominationGroups = [
  DenominationGroup(amount: 5, slots: 56),
  DenominationGroup(amount: 10, slots: 54),
  DenominationGroup(amount: 20, slots: 54),
  DenominationGroup(amount: 50, slots: 6),
  DenominationGroup(amount: 100, slots: 6),
  DenominationGroup(amount: 200, slots: 6),
  DenominationGroup(amount: 500, slots: 2),
];
