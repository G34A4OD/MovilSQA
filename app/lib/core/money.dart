/// BOB in integer cents. Never parse financial amounts as floating point.
class Money {
  const Money._(this.cents);
  static const maxCents = 99999999999;
  final int cents;

  factory Money.parse(String input) {
    final value = input.trim();
    if (!RegExp(r'^\d{1,9}([.,]\d{1,2})?$').hasMatch(value)) {
      throw const FormatException(
        'Usa un monto positivo con hasta dos decimales.',
      );
    }
    final parts = value.replaceAll(',', '.').split('.');
    final cents =
        int.parse(parts.first) * 100 +
        (parts.length == 2 ? int.parse(parts[1].padRight(2, '0')) : 0);
    if (cents <= 0 || cents > maxCents) {
      throw const FormatException(
        'El monto debe estar entre 0,01 y 999999999,99.',
      );
    }
    return Money._(cents);
  }

  String format() => formatCents(cents);
}

String formatCents(int cents) =>
    '${cents < 0 ? '-' : ''}Bs ${cents.abs() ~/ 100},${(cents.abs() % 100).toString().padLeft(2, '0')}';
