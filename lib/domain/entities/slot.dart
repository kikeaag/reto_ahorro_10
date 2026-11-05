/// Entidad de dominio: una "casilla" de dinero del reto.
///
/// Clase pura de Dart: **no** importa Flutter ni Hive.
/// Campos: id (String), checked (bool), amount (double).
class Slot {
  const Slot({
    required this.id,
    required this.checked,
    required this.amount,
  });

  final String id;
  final bool checked;
  final double amount;

  /// Devuelve una copia con [checked] alterado (las entidades son inmutables).
  Slot copyWith({bool? checked, double? amount}) {
    return Slot(
      id: id,
      checked: checked ?? this.checked,
      amount: amount ?? this.amount,
    );
  }

  @override
  String toString() => 'Slot(id: $id, checked: $checked, amount: $amount)';
}
