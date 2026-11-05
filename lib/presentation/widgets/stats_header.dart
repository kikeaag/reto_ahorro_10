import 'package:flutter/material.dart';
import 'package:money_challenge/domain/entities/savings_summary.dart';

/// Textos superiores: porcentaje de avance, total guardado y nº de casillas.
class StatsHeader extends StatelessWidget {
  const StatsHeader({super.key, required this.summary});

  final SavingsSummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Text('${summary.percent.toStringAsFixed(2)} %'),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Total guardado: \$${summary.total.toStringAsFixed(2)}'),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Casillas totales: ${summary.totalSlots}'),
        ),
        const SizedBox(height: 18),
      ],
    );
  }
}
