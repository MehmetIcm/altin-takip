import 'gold_product.dart';

/// Tek bir ürünün, tek bir kaynaktan gelen anlık fiyatı.
class PriceQuote {
  const PriceQuote({
    required this.product,
    required this.asOf,
    required this.source,
    this.buy,
    this.sell,
    this.last,
    this.changePercent,
    this.high,
    this.low,
    this.stale = false,
    this.cached = false,
  });

  final GoldProduct product;

  /// Alış (kullanıcı satarsa alacağı fiyat).
  final double? buy;

  /// Satış (kullanıcı alırsa ödeyeceği fiyat).
  final double? sell;

  /// Alış/satış ayrımı olmayan tek fiyat (ör. ons spot).
  final double? last;
  final double? changePercent;
  final double? high;
  final double? low;

  /// Verinin gerçek zamanlı ölçüm anı (sağlayıcının bildirdiği zaman).
  final DateTime asOf;
  final String source;

  /// Kaynak, kendi sunucusunda eski veri sunduğunu bildirdi.
  final bool stale;

  /// Önbellekten okundu; canlı veri değildir.
  final bool cached;

  double? get bid => buy ?? last;
  double? get ask => sell ?? last;
  double? get reference => sell ?? last ?? buy;
  double? get mid =>
      (buy != null && sell != null) ? (buy! + sell!) / 2 : (last ?? sell ?? buy);

  /// Makas = Satış - Alış
  double? get spread => (buy == null || sell == null) ? null : sell! - buy!;

  /// Makas yüzdesi = Makas / Satış * 100
  double? get spreadPercent {
    final s = spread;
    if (s == null || sell == null || sell! <= 0) return null;
    return s / sell! * 100;
  }

  PriceQuote asCached() => PriceQuote(
        product: product,
        asOf: asOf,
        source: source,
        buy: buy,
        sell: sell,
        last: last,
        changePercent: changePercent,
        high: high,
        low: low,
        stale: stale,
        cached: true,
      );

  Map<String, dynamic> toJson() => {
        'product': product.name,
        'buy': buy,
        'sell': sell,
        'last': last,
        'change': changePercent,
        'high': high,
        'low': low,
        'asOf': asOf.toUtc().toIso8601String(),
        'source': source,
        'stale': stale,
      };

  static PriceQuote? fromJson(dynamic j) {
    if (j is! Map) return null;
    final product = GoldProduct.fromName(j['product'] as String?);
    final asOf = DateTime.tryParse('${j['asOf']}');
    if (product == null || asOf == null) return null;
    double? n(dynamic v) => v is num ? v.toDouble() : null;
    return PriceQuote(
      product: product,
      asOf: asOf.toUtc(),
      source: '${j['source']}',
      buy: n(j['buy']),
      sell: n(j['sell']),
      last: n(j['last']),
      changePercent: n(j['change']),
      high: n(j['high']),
      low: n(j['low']),
      stale: j['stale'] == true,
    );
  }
}
