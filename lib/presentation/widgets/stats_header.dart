import 'package:flutter/material.dart';
import 'package:money_challenge/domain/entities/savings_summary.dart';
import 'package:money_challenge/presentation/utils/money_format.dart';
import 'package:money_challenge/presentation/widgets/rolling_number_text.dart';

/// Tarjeta de estadísticas (Material 3): total guardado + porcentaje con
/// barra de progreso, y debajo el nº de casillas marcadas.
///
/// Los textos `0.00 %` y `Casillas totales: n / N` los assertúa el test
/// (ver AGENTS.md): no cambiarlos sin actualizar `test/widget_test.dart`.
class StatsHeader extends StatelessWidget {
  const StatsHeader({super.key, required this.summary});

  final SavingsSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Mismo acabado lila tonal Material 3 que las casillas (SlotTile).
    final lilacTop = cs.primaryContainer.withAlpha(165);
    final lilacBottom = cs.primaryContainer.withAlpha(115);
    final subtleText = cs.onPrimaryContainer.withAlpha(195);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [lilacTop, lilacBottom],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.primary.withAlpha(75),
          width: 1.1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icono tonal con contraste suave sobre el fondo lila.
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cs.primary.withAlpha(32),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.primary.withAlpha(55)),
                  ),
                  child: Icon(
                    Icons.savings,
                    color: cs.onPrimaryContainer,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total guardado',
                        style: theme.textTheme.labelMedium
                            ?.copyWith(color: subtleText),
                      ),
                      const SizedBox(height: 2),
                      RollingNumberText(
                        numericValue: summary.total,
                        text: formatMoney(summary.total),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Progreso',
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: subtleText),
                    ),
                    const SizedBox(height: 2),
                    RollingNumberText(
                      numericValue: summary.percent,
                      text: '${summary.percent.toStringAsFixed(2)} %',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Barra de progreso animada con esquinas redondeadas.
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(end: summary.percent / 100),
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                builder: (context, animatedValue, _) => LinearProgressIndicator(
                  value: animatedValue,
                  minHeight: 8,
                  color: cs.primary,
                  backgroundColor: cs.primary.withAlpha((0.22 * 255).round()),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.checklist, size: 18, color: subtleText),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Casillas totales: ${summary.checkedSlots} / '
                    '${summary.totalSlots}',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: subtleText),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
