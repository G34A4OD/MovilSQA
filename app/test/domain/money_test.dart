import 'package:app/core/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TC-BUD-01 HU-13 decimal exacto y coma local', () {
    expect(Money.parse('0.10').cents + Money.parse('0,20').cents, 30);
    expect(Money.parse('1234.56').format(), 'Bs 1234,56');
  });
  test('TC-BUD-01 HU-13 rechaza montos ambiguos y fuera de límite', () {
    for (final value in [
      '',
      '-1',
      '0',
      '1.234',
      '1e3',
      '1,234.00',
      'NaN',
      '1000000000',
    ]) {
      expect(() => Money.parse(value), throwsFormatException, reason: value);
    }
    expect(Money.parse('999999999.99').cents, 99999999999);
  });
}
