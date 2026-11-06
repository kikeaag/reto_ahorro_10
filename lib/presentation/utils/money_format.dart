/// Formatea un monto como `$2,500` (entero + separador de miles, sin centavos).
///
/// El total del reto siempre es múltiplo de 5, así que nunca hay centavos
/// reales; se redondea al entero más cercano por seguridad.
String formatMoney(double amount) {
  final whole = amount.round();
  final digits = whole.abs().toString();
  final grouped = digits.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '${whole < 0 ? '-' : ''}\$$grouped';
}
