import 'package:altin_takip/core/utils/formatters.dart';
import 'package:altin_takip/core/utils/istanbul_time.dart';
import 'package:altin_takip/domain/entities/gold_product.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async => initializeDateFormatting('tr_TR'));

  test('Türk lirası biçimi', () {
    expect(Fmt.tl(6425.5), '6.425,50\u00A0₺');
    expect(Fmt.tl(0.5), '0,50\u00A0₺');
  });

  test('Yüzde biçimi ve işaret', () {
    expect(Fmt.percent(0.964), '+%0,96');
    expect(Fmt.percent(-0.76), '-%0,76');
    expect(Fmt.percent(0.001), '%0,00');
  });

  test('Ürüne göre fiyat biçimi', () {
    expect(Fmt.price(GoldProduct.ons, 4141.8), '4.141,80\u00A0\$');
    expect(Fmt.price(GoldProduct.usdTry, 49.1791), '49,1791\u00A0₺');
  });

  test('Kullanıcı sayı girdisi', () {
    expect(Fmt.parseNumber('5.900'), 5900);
    expect(Fmt.parseNumber('5,5'), 5.5);
    expect(Fmt.parseNumber('1.234,56'), 1234.56);
    expect(Fmt.parseNumber('25'), 25);
    expect(Fmt.parseNumber('abc'), isNull);
    expect(Fmt.parseNumber(''), isNull);
  });

  test('İstanbul saati UTC+3', () {
    final instant = IstanbulTime.parseWall('2026-10-03 09:38:02');
    expect(instant, DateTime.utc(2026, 10, 3, 6, 38, 2));
    expect(Fmt.time(instant), '09:38');
  });
}
