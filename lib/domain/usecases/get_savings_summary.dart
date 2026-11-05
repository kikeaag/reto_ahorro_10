import 'package:money_challenge/domain/entities/savings_summary.dart';
import 'package:money_challenge/domain/entities/slot.dart';

/// Caso de uso: calcular el resumen del ahorro a partir de las casillas.
///
/// Función pura (sin I/O): total, porcentaje y progreso por grupo,
/// en un solo pasagge sobre la lista.
class GetSavingsSummary {
  const GetSavingsSummary();

  SavingsSummary call(List<Slot> slots) => SavingsSummary.fromSlots(slots);
}
