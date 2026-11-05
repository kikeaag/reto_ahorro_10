import 'package:flutter/material.dart';
import 'package:money_challenge/domain/entities/slot.dart';

/// Casilla individual del grid. Es el "tile" sin envoltura de animación:
/// el arranque animado lo decide la pantalla que la contiene.
///
/// Envuelta en `RepaintBoundary` para aislar sus repintados (ver AGENTS.md).
class SlotTile extends StatelessWidget {
  const SlotTile({
    super.key,
    required this.slot,
    required this.onTap,
  });

  final Slot slot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Neutra cuando no está marcada; tinte primario al 18% cuando lo está.
    final baseBg = cs.surfaceContainerHighest;
    final checkedBg = cs.primary.withAlpha((0.18 * 255).round());
    final bgColor = slot.checked ? checkedBg : baseBg;
    final accentColor = slot.checked ? cs.primary : cs.onSurfaceVariant;

    return RepaintBoundary(
      key: ValueKey(slot.id),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outline),
          ),
          padding: const EdgeInsets.all(6),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    slot.amount.toInt().toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: Icon(
                      slot.checked
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: accentColor,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
