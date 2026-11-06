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

  // Paleta Material 3 tonal para el estado completado (verde esmeralda).
  static const Color _checkedBgTop = Color(0xFFDCF7E8);
  static const Color _checkedBgBottom = Color(0xFFC4EED6);
  static const Color _checkedBorder = Color(0xFF2E7D32);
  static const Color _checkedText = Color(0xFF0D532A);
  static const Color _checkedIcon = Color(0xFF1B8755);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isChecked = slot.checked;

    // Sin seleccionar: lila tonal Material 3 (primaryContainer suave).
    final lilacTop = cs.primaryContainer.withAlpha(165);
    final lilacBottom = cs.primaryContainer.withAlpha(115);
    final borderColor = isChecked
        ? _checkedBorder.withAlpha(175)
        : cs.primary.withAlpha(75);
    final textColor = isChecked ? _checkedText : cs.onPrimaryContainer;
    final iconColor = isChecked ? _checkedIcon : cs.primary.withAlpha(190);
    final borderRadius = BorderRadius.circular(14);

    return RepaintBoundary(
      key: ValueKey(slot.id),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          splashColor: (isChecked ? _checkedIcon : cs.primary).withAlpha(36),
          highlightColor: (isChecked ? _checkedIcon : cs.primary).withAlpha(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isChecked
                    ? const [_checkedBgTop, _checkedBgBottom]
                    : [lilacTop, lilacBottom],
              ),
              borderRadius: borderRadius,
              border: Border.all(
                color: borderColor,
                width: isChecked ? 1.5 : 1.1,
              ),
              boxShadow: isChecked
                  ? [
                      BoxShadow(
                        color: _checkedIcon.withAlpha(28),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
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
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 5),
                    SizedBox(
                      height: 20,
                      width: 20,
                      child: Icon(
                        isChecked
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: iconColor,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
