import 'package:flutter/material.dart';
import 'package:money_challenge/domain/entities/savings_summary.dart';

/// Encabezado de un grupo de denominación: `Monedas de $X` / `Billetes de $X`
/// + `n / total`.
///
/// Si el grupo está completado ([collapsible]), el encabezado es tocable y
/// alterna el colapso de sus casillas mediante [onToggle] (icono ▾/▴).
class GroupHeader extends StatelessWidget {
  const GroupHeader({
    super.key,
    required this.group,
    this.collapsible = false,
    this.collapsed = false,
    this.onToggle,
  });

  final GroupProgress group;

  /// El grupo está completado y su encabezado puede contraerse.
  final bool collapsible;

  /// El grid de casillas del grupo está actualmente contraído.
  final bool collapsed;

  /// Alterna el colapso; solo se invoca si [collapsible] es true.
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    // $5 y $10 son monedas; de $20 en adelante son billetes.
    final label = group.amount >= 20 ? 'Billetes' : 'Monedas';

    final row = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label de \$${group.amount.toInt()}',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${group.checkedSlots} / ${group.targetSlots}'),
            if (collapsible)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Icon(
                  collapsed ? Icons.expand_more : Icons.expand_less,
                  size: 20,
                ),
              ),
          ],
        ),
      ],
    );

    if (!collapsible) return row;

    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(8),
      child: row,
    );
  }
}
