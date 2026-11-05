import 'package:flutter/material.dart';
import 'package:money_challenge/domain/entities/savings_summary.dart';

/// Encabezado de un grupo de denominación: `Monedas de $X` + `n / total`.
class GroupHeader extends StatelessWidget {
  const GroupHeader({super.key, required this.group});

  final GroupProgress group;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Monedas de \$${group.amount.toInt()}',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        Text('${group.checkedSlots} / ${group.targetSlots}'),
      ],
    );
  }
}
