import 'package:flutter/material.dart';

/// Texto numérico con animación tipo odómetro / reloj antiguo: cuando cambia
/// [text], únicamente los dígitos que cambiaron ruedan verticalmente (bajan al
/// incrementar y suben al decrementar).
///
/// En reposo devuelve un único [Text] con la cadena completa para mantener
/// intactas las búsquedas por texto en tests y la semántica de accesibilidad.
class RollingNumberText extends StatefulWidget {
  const RollingNumberText({
    super.key,
    required this.numericValue,
    required this.text,
    this.style,
  });

  final double numericValue;
  final String text;
  final TextStyle? style;

  @override
  State<RollingNumberText> createState() => _RollingNumberTextState();
}

class _RollingNumberTextState extends State<RollingNumberText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late String _previousText;
  late double _previousValue;
  bool _increasing = true;

  @override
  void initState() {
    super.initState();
    _previousText = widget.text;
    _previousValue = widget.numericValue;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _previousText = widget.text);
        }
      });
  }

  @override
  void didUpdateWidget(covariant RollingNumberText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text) {
      _previousText = oldWidget.text;
      _increasing = widget.numericValue >= _previousValue;
      _previousValue = widget.numericValue;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Alinea la cadena anterior y la nueva por valor posicional (de derecha a
  /// izquierda), manteniendo fijo el prefijo `$` si ambas lo tienen.
  (List<String>, List<String>) _alignedChars(String oldStr, String newStr) {
    final hasDollarPrefix = oldStr.startsWith(r'$') && newStr.startsWith(r'$');
    final oldBody = hasDollarPrefix ? oldStr.substring(1) : oldStr;
    final newBody = hasDollarPrefix ? newStr.substring(1) : newStr;

    final maxLen =
        oldBody.length > newBody.length ? oldBody.length : newBody.length;
    final paddedOld = oldBody.padLeft(maxLen);
    final paddedNew = newBody.padLeft(maxLen);

    final oldChars = <String>[
      if (hasDollarPrefix) r'$',
      ...paddedOld.split(''),
    ];
    final newChars = <String>[
      if (hasDollarPrefix) r'$',
      ...paddedNew.split(''),
    ];
    return (oldChars, newChars);
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.isAnimating || _previousText == widget.text) {
      return Text(
        widget.text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: widget.style,
      );
    }

    final (oldChars, newChars) = _alignedChars(_previousText, widget.text);
    final length = newChars.length;
    final direction = _increasing ? 1.0 : -1.0;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List<Widget>.generate(length, (i) {
              final oldChar = oldChars[i];
              final newChar = newChars[i];

              // Los caracteres que no cambian (como '$', ',', '%' o dígitos
              // superiores iguales) permanecen fijos.
              if (oldChar == newChar) {
                return Text(newChar, style: widget.style);
              }

              // Ligero escalonamiento de derecha a izquierda como tambor mecánico.
              final fromRight = length - 1 - i;
              final start = (fromRight * 0.045).clamp(0.0, 0.30);
              final rawT = ((_controller.value - start) / (1.0 - start))
                  .clamp(0.0, 1.0);
              final t = Curves.easeOutBack.transform(rawT);
              final opacityT = Curves.easeOut.transform(rawT);

              // Si incrementa (direction = 1): el dígito nuevo baja desde
              // arriba (-1 -> 0) y empuja al anterior hacia abajo (0 -> +1).
              final oldOffset = Offset(0, direction * t);
              final newOffset = Offset(0, -direction * (1.0 - t));

              return ClipRect(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (oldChar != ' ')
                      Opacity(
                        opacity: (1.0 - opacityT).clamp(0.0, 1.0),
                        child: FractionalTranslation(
                          translation: oldOffset,
                          child: Text(oldChar, style: widget.style),
                        ),
                      ),
                    if (newChar != ' ')
                      Opacity(
                        opacity: opacityT.clamp(0.0, 1.0),
                        child: FractionalTranslation(
                          translation: newOffset,
                          child: Text(newChar, style: widget.style),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
