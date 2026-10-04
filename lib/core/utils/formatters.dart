import 'package:intl/intl.dart';

import '../../domain/entities/gold_product.dart';
import 'istanbul_time.dart';

/// Türkçe para, yüzde ve tarih biçimleri. Örn: 6.425,50 ₺
class Fmt {
  static final NumberFormat _n2 = NumberFormat('#,##0.00', 'tr_TR');
  static final NumberFormat _n4 = NumberFormat('#,##0.0000', 'tr_TR');
  static final NumberFormat _amount = NumberFormat('#,##0.####', 'tr_TR');

  static String tl(num v) => '${_n2.format(v)}\u00A0₺';
  static String usd(num v) => '${_n2.format(v)}\u00A0\$';
  static String fxRate(num v) => '${_n4.format(v)}\u00A0₺';
  static String number(num v) => _n2.format(v);
  static String amount(num v) => _amount.format(v);

  static String signedTl(num v) {
    final r = double.parse(v.abs().toStringAsFixed(2));
    final sign = r == 0 ? '' : (v > 0 ? '+' : '-');
    return '$sign${_n2.format(r)}\u00A0₺';
  }

  static String percent(num v) {
    final r = double.parse(v.abs().toStringAsFixed(2));
    final sign = r == 0 ? '' : (v > 0 ? '+' : '-');
    return '$sign%${_n2.format(r)}';
  }

  /// Ürüne uygun fiyat biçimi (ons: USD, kur: 4 hane, diğerleri: TL).
  static String price(GoldProduct p, num v) {
    if (p.group == ProductGroup.fx) return fxRate(v);
    return p == GoldProduct.ons ? usd(v) : tl(v);
  }

  static String time(DateTime instant) =>
      DateFormat('HH:mm').format(IstanbulTime.toWall(instant));

  static String dateTime(DateTime instant) =>
      DateFormat('d MMM y HH:mm', 'tr_TR').format(IstanbulTime.toWall(instant));

  static String date(DateTime instant) =>
      DateFormat('d MMM y', 'tr_TR').format(IstanbulTime.toWall(instant));

  static String age(Duration d) {
    if (d.inMinutes < 1) return 'az önce';
    if (d.inMinutes < 60) return '${d.inMinutes} dk önce';
    if (d.inHours < 48) return '${d.inHours} sa önce';
    return '${d.inDays} gün önce';
  }

  /// Kullanıcı girdisini sayıya çevirir. "5.900" -> 5900, "5,5" -> 5.5
  static double? parseNumber(String raw) {
    var s = raw.trim().replaceAll(RegExp(r'\s'), '').replaceAll('₺', '');
    if (s.isEmpty) return null;
    if (s.contains(',')) {
      s = s.replaceAll('.', '').replaceAll(',', '.');
    } else if (RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(s)) {
      s = s.replaceAll('.', '');
    }
    final v = double.tryParse(s);
    if (v == null || v.isNaN || v.isInfinite) return null;
    return v;
  }
}
