import 'dart:ui' as ui;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:money_challenge/domain/entities/denomination_group.dart';
import 'package:money_challenge/presentation/controllers/home_controller.dart';
import 'package:money_challenge/presentation/screens/home_screen.dart';
import 'package:money_challenge/presentation/utils/app_download_links.dart';
import 'package:money_challenge/presentation/utils/money_format.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

/// Pantalla de felicitaciones: se muestra **solo** cuando el usuario marca
/// la última casilla y alcanza la meta ([goal]).
///
/// Se abre con `Navigator.pushReplacement` desde `HomeScreen`, es decir,
/// reemplaza a la lista y **no tiene vuelta atrás**: sus únicas acciones son
/// "Compartir logro" (hoja del sistema con texto + ligas de descarga +
/// captura) y
/// "Iniciar nueva alcancía", que resetea el ahorro (desmarca las 184
/// casillas) y navega a un home nuevo. No hay AppBar ni retorno a la lista
/// anterior (el botón atrás del sistema cierra la app).
/// Es una UI pura (ver AGENTS.md): no persiste nada ni habla con Hive, solo
/// lee el [SavingsSummary] publicado por el [HomeController].
class GoalReachedScreen extends StatefulWidget {
  const GoalReachedScreen({super.key});

  @override
  State<GoalReachedScreen> createState() => _GoalReachedScreenState();
}

class _GoalReachedScreenState extends State<GoalReachedScreen>
    with SingleTickerProviderStateMixin {
  /// Confeti continuo mientras la pantalla siga abierta (`shouldLoop`).
  late final ConfettiController _confettiController;

  /// Entrada escalonada del contenido: icono → título → tarjeta.
  late final AnimationController _entranceController;

  late final Animation<double> _iconOpacity;
  late final Animation<double> _iconScale;
  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _cardOpacity;
  late final Animation<Offset> _cardSlide;

  /// Límites de toda la pantalla (fondo + confeti + contenido): es lo que
  /// se captura como PNG para adjuntarlo al compartir el logro.
  final GlobalKey _repaintKey = GlobalKey();

  /// Evita el doble toque mientras un share está en curso.
  bool _sharing = false;

  @override
  void initState() {
    super.initState();

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 4),
    )..play();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();

    _iconOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    );
    // `easeOutBack` sobrepasa 1.0: solo se usa para escala (no para opacidad).
    _iconScale = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
    );
    _textOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.25, 0.65, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.25, 0.65, curve: Curves.easeOut),
      ),
    );
    _cardOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _entranceController.dispose();
    // El `ConfettiWidget` se desmonta antes que esta pantalla y ya llamó a
    // `stop()`; aquí solo liberamos el controlador.
    _confettiController.dispose();
    super.dispose();
  }

  /// Reinicia el ahorro (desmarca las 184 casillas) y reemplaza esta
  /// pantalla por un home nuevo, que arranca con el resumen en cero y
  /// repite la animación de arranque.
  void _startNewSavings() {
    context.read<HomeController>().reset();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
    );
  }

  /// Mensaje de texto que se adjunta al compartir el logro.
  ///
  /// Incluye al final las ligas de descarga de la app
  /// ([kPlayStoreUrl] / [kAppStoreUrl]): `share_plus` no permite pasar
  /// `text` y `uri` al mismo tiempo, así que las URLs viajan dentro del
  /// texto.
  String _achievementMessage() {
    final summary = context.read<HomeController>().summary!;
    return '¡Alcancé mi meta de ahorro! 🐷💰\n'
        '${formatMoney(summary.total)} en la Alcancía 5k — '
        '${summary.totalSlots}/${summary.totalSlots} casillas completadas.\n'
        '\n'
        '📲 Descarga la app:\n'
        'Android: $kPlayStoreUrl\n'
        'iOS: $kAppStoreUrl';
  }

  /// Captura la pantalla completa como PNG (fondo + confeti + contenido).
  ///
  /// Devuelve `null` si no es posible: en ese caso se comparte **solo el
  /// texto**, nunca se rompe el share por la imagen.
  Future<XFile?> _capturePngFile() async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary) return null;

      // Se leen contexto/tamaño **antes** del primer `await`.
      final pixelRatio = MediaQuery.devicePixelRatioOf(context);
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (byteData == null) return null;

      return XFile.fromData(
        byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
        mimeType: 'image/png',
        name: 'alcanci-5k.png',
      );
    } catch (error) {
      debugPrint('Share: no se pudo capturar la pantalla: $error');
      return null;
    }
  }

  /// Comparte el logro (texto + ligas de descarga + captura) con la hoja de
  /// compartir del sistema: ahí elige WhatsApp, X, Facebook, Instagram, etc.
  ///
  /// No navega ni modifica datos. [origin] es el rectángulo del botón (ancla
  /// del popover en iPad). Se lee el contexto solo antes del primer `await`.
  Future<void> _shareAchievement(Rect? origin) async {
    if (_sharing) return;
    _sharing = true;
    try {
      final message = _achievementMessage();
      final png = await _capturePngFile();
      await SharePlus.instance.share(
        ShareParams(
          text: message,
          files: [?png],
          title: 'Alcancía 5k',
          sharePositionOrigin: origin,
        ),
      );
    } catch (error) {
      debugPrint('Share: no se pudo compartir el logro: $error');
    } finally {
      _sharing = false;
    }
  }

  /// Ancla del popover de compartir (necesario en iPad) calculada con el
  /// contexto del propio botón.
  Rect? _originOf(BuildContext buttonContext) {
    final box = buttonContext.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Invariante: solo se navega aquí desde `HomeScreen` después de
    // `HomeController.init()`, así que el resumen ya está calculado.
    final summary = context.read<HomeController>().summary!;

    return Scaffold(
      // Envuelve toda la pantalla para poder capturarla al compartir.
      body: RepaintBoundary(
        key: _repaintKey,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Fondo degradado lila (primaryContainer → surface).
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [cs.primaryContainer, cs.surface],
                ),
              ),
            ),
            // Confeti: el paquete emite desde la esquina superior *izquierda*
            // de su contenedor, así que se usa un contenedor angosto centrado
            // para que la lluvia salga del centro superior de la pantalla.
            Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: 4,
                height: 140,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: true,
                  emissionFrequency: 0.05,
                  numberOfParticles: 12,
                  gravity: 0.12,
                  colors: [
                    cs.primary,
                    cs.secondary,
                    cs.tertiary,
                    Colors.white,
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icono de alcancía con entrada de escala + fundido.
                      FadeTransition(
                        opacity: _iconOpacity,
                        child: ScaleTransition(
                          scale: _iconScale,
                          child: Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: cs.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: cs.primary.withAlpha(77),
                                  blurRadius: 24,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.savings,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      // Título + subtítulo.
                      FadeTransition(
                        opacity: _textOpacity,
                        child: SlideTransition(
                          position: _textSlide,
                          child: Column(
                            children: [
                              Semantics(
                                header: true,
                                child: Text(
                                  '¡Felicidades!',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: cs.onPrimaryContainer,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Has alcanzado la meta de '
                                '${formatMoney(goal)}',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: cs.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      // Resumen final (mismos textos/estilos que StatsHeader),
                      // con estilo "vidrio esmerilado": sombra suave por
                      // fuera, blur del fondo (degradado + confeti) recortado
                      // al radio, relleno blanco translúcido y borde degradado
                      // que simula el canto del vidrio.
                      FadeTransition(
                        opacity: _cardOpacity,
                        child: SlideTransition(
                          position: _cardSlide,
                          child: Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: cs.primary.withAlpha(20),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: BackdropFilter(
                                    filter: ui.ImageFilter.blur(
                                      sigmaX: 12,
                                      sigmaY: 12,
                                    ),
                                    // El borde de "canto de vidrio" se pinta
                                    // con un CustomPaint: `BoxDecoration` no
                                    // acepta bordes con degradado.
                                    child: CustomPaint(
                                      foregroundPainter: _GlassBorderPainter(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.white.withValues(
                                              alpha: 0.9,
                                            ),
                                            Colors.white.withValues(
                                              alpha: 0.25,
                                            ),
                                          ],
                                        ),
                                        radius: BorderRadius.circular(16),
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.10,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 28,
                                          vertical: 18,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            _FinalStat(
                                              label: 'Total guardado',
                                              value:
                                                  formatMoney(summary.total),
                                              valueColor: cs.onSurface,
                                            ),
                                            Container(
                                              width: 1,
                                              height: 44,
                                              margin: const EdgeInsets
                                                  .symmetric(
                                                horizontal: 24,
                                              ),
                                              color: cs.outlineVariant
                                                  .withValues(alpha: 0.55),
                                            ),
                                            _FinalStat(
                                              label: 'Progreso',
                                              value:
                                                  '${summary.percent.toStringAsFixed(2)} %',
                                              valueColor: cs.primary,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Completaste las ${summary.totalSlots} casillas '
                                'de tu alcancía.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: cs.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(height: 32),
                              // Compartir el logro (secundario): texto +
                              // ligas de descarga + captura de esta
                              // pantalla, con la hoja del sistema
                              // (WhatsApp, X, Facebook...). El `Builder` da
                              // el contexto para el ancla iPad.
                              Builder(
                                builder: (buttonContext) => SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () => _shareAchievement(
                                      _originOf(buttonContext),
                                    ),
                                    icon: const Icon(Icons.share),
                                    label: const Text('Compartir logro'),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Acción principal: reset + home nuevo.
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: _startNewSavings,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Iniciar nueva alcancía'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dato final de la tarjeta (etiqueta + valor), en el mismo estilo que la
/// tarjeta de estadísticas del home.
class _FinalStat extends StatelessWidget {
  const _FinalStat({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

/// Borde de 1 px con [gradient] dibujado como un `RRect` trazado (el "canto"
/// de la tarjeta de vidrio).
///
/// Existe porque `BoxDecoration.border` solo acepta `BoxBorder` y en esta
/// versión de Flutter no hay `GradientBorder`: por eso la tarjeta usa un
/// `CustomPaint(foregroundPainter: ...)` en lugar de un `border:`.
class _GlassBorderPainter extends CustomPainter {
  const _GlassBorderPainter({required this.gradient, required this.radius});

  final Gradient gradient;
  final BorderRadius radius;

  @override
  void paint(Canvas canvas, Size size) {
    // `deflate(0.5)` centra el trazo de 1 px dentro del rectángulo para que
    // no se recorte por la mitad en el borde.
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      radius.topLeft,
    ).deflate(0.5);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..shader = gradient.createShader(rrect.outerRect);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_GlassBorderPainter oldDelegate) =>
      oldDelegate.gradient != gradient || oldDelegate.radius != radius;
}
