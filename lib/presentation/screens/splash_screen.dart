import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:money_challenge/presentation/screens/home_screen.dart';

/// Pantalla splash animada con el logo de la alcancía y la moneda cayendo.
///
/// Usa un único [AnimationController] acotado (sin timers sueltos) y al
/// terminar reemplaza la ruta por [HomeScreen].
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pigScale;
  late final Animation<double> _pigOpacity;
  late final Animation<double> _coinDrop;
  late final Animation<double> _pigPulse;
  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1450),
    );

    _pigScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.50, curve: Curves.easeOutBack),
    );
    _pigOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.30, curve: Curves.easeOut),
    );
    _coinDrop = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.28, 0.76, curve: Curves.bounceOut),
    );
    _pigPulse = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.60, 0.88, curve: Curves.easeInOut),
    );
    _textOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.40, 0.82, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.40, 0.82, curve: Curves.easeOutCubic),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder<void>(
            transitionDuration: const Duration(milliseconds: 280),
            pageBuilder: (_, _, _) => const HomeScreen(),
            transitionsBuilder: (_, animation, _, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        );
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6750A4),
              Color(0xFF4F378B),
              Color(0xFF381E72),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  // Pequeño pulso elástico cuando la moneda entra en la alcancía.
                  final pulse = 1.0 + 0.045 * math.sin(_pigPulse.value * math.pi);
                  final scale = _pigScale.value * pulse;
                  return Opacity(
                    opacity: _pigOpacity.value.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: scale,
                      child: SizedBox(
                        width: 210,
                        height: 210,
                        child: CustomPaint(
                          painter: _PiggyLogoPainter(
                            coinProgress: _coinDrop.value,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              FadeTransition(
                opacity: _textOpacity,
                child: SlideTransition(
                  position: _textSlide,
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Alcancía 5k',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Tu reto de ahorro a \$5,000',
                        style: TextStyle(
                          color: Color(0xFFE8DEF8),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
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
    );
  }
}

/// Dibuja el logo vectorial de la app (cerdito blanco + moneda dorada `$`)
/// sobre un lienzo lógico de 512×512 escalado al tamaño del widget.
class _PiggyLogoPainter extends CustomPainter {
  const _PiggyLogoPainter({required this.coinProgress});

  final double coinProgress;

  static const Color _lilac = Color(0xFF6750A4);
  static const Color _coinFill = Color(0xFFFFD54F);
  static const Color _coinRing = Color(0xFFF9A825);
  static const Color _coinText = Color(0xFFF57F17);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 512.0, size.height / 512.0);

    final whiteFill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final lilacFill = Paint()
      ..color = _lilac
      ..style = PaintingStyle.fill;

    // Cola rizada.
    final tailPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;
    final tailPath = Path()
      ..moveTo(96, 252)
      ..quadraticBezierTo(62, 238, 66, 278)
      ..quadraticBezierTo(70, 308, 96, 300);
    canvas.drawPath(tailPath, tailPaint);

    // Cuerpo.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(238, 292), width: 296, height: 228),
      whiteFill,
    );

    // Patas.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(158, 368, 56, 74),
        const Radius.circular(20),
      ),
      whiteFill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(288, 368, 56, 74),
        const Radius.circular(20),
      ),
      whiteFill,
    );

    // Oreja.
    final earPath = Path()
      ..moveTo(336, 196)
      ..lineTo(392, 178)
      ..lineTo(378, 240)
      ..close();
    canvas.drawPath(earPath, whiteFill);

    // Cabeza.
    canvas.drawCircle(const Offset(368, 268), 86, whiteFill);

    // Hocico y fosas.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(446, 292), width: 72, height: 62),
      whiteFill,
    );
    canvas.drawCircle(const Offset(458, 283), 6.5, lilacFill);
    canvas.drawCircle(const Offset(458, 301), 6.5, lilacFill);

    // Ojo.
    canvas.drawCircle(const Offset(396, 246), 11, lilacFill);

    // Ranura de moneda.
    final slotRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(212, 196, 94, 20),
      const Radius.circular(10),
    );
    canvas.drawRRect(slotRect, lilacFill);

    // Moneda animada: cae desde arriba (y=58) hasta entrar parcialmente en la
    // ranura (y=170), recortada por encima del borde inferior de la ranura.
    final coinY = 58.0 + (170.0 - 58.0) * coinProgress;
    canvas.save();
    canvas.clipRect(const Rect.fromLTRB(0, 0, 512, 206));
    final coinCenter = Offset(259, coinY);

    canvas.drawCircle(
      coinCenter,
      44,
      Paint()
        ..color = _coinFill
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      coinCenter,
      33,
      Paint()
        ..color = _coinRing
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );

    final textPainter = TextPainter(
      text: const TextSpan(
        text: r'$',
        style: TextStyle(
          color: _coinText,
          fontSize: 42,
          fontWeight: FontWeight.w700,
          fontFamily: 'Roboto',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      coinCenter - Offset(textPainter.width / 2, textPainter.height / 2),
    );
    canvas.restore();

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PiggyLogoPainter oldDelegate) =>
      oldDelegate.coinProgress != coinProgress;
}
