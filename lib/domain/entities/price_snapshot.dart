import 'gold_product.dart';
import 'price_quote.dart';

enum DataStatus {
  /// Tüm kaynaklar bu turda başarıyla okundu.
  live,

  /// Bazı kaynaklar başarısız oldu; eksikler önbellekten tamamlanmış olabilir.
  partial,

  /// Hiçbir kaynağa ulaşılamadı; yalnızca önbellek gösteriliyor.
  cached,

  /// Ne canlı ne de önbellekte veri var.
  unavailable,
}

class PriceSnapshot {
  const PriceSnapshot({
    required this.quotes,
    required this.fetchedAt,
    required this.status,
    this.issues = const [],
  });

  factory PriceSnapshot.unavailable(DateTime now, List<String> issues) =>
      PriceSnapshot(
        quotes: const {},
        fetchedAt: now,
        status: DataStatus.unavailable,
        issues: issues,
      );

  final Map<GoldProduct, PriceQuote> quotes;
  final DateTime fetchedAt;
  final DataStatus status;
  final List<String> issues;

  PriceQuote? operator [](GoldProduct p) => quotes[p];

  bool get hasData => quotes.isNotEmpty;

  DateTime? get latestAsOf => quotes.values.fold<DateTime?>(
      null, (a, q) => a == null || q.asOf.isAfter(a) ? q.asOf : a);

  PriceSnapshot copyWith({
    Map<GoldProduct, PriceQuote>? quotes,
    DataStatus? status,
    List<String>? issues,
  }) =>
      PriceSnapshot(
        quotes: quotes ?? this.quotes,
        fetchedAt: fetchedAt,
        status: status ?? this.status,
        issues: issues ?? this.issues,
      );

  Map<String, dynamic> toJson() => {
        'fetchedAt': fetchedAt.toUtc().toIso8601String(),
        'quotes': [for (final q in quotes.values) q.toJson()],
      };

  static PriceSnapshot? fromJson(dynamic j) {
    if (j is! Map) return null;
    final fetchedAt = DateTime.tryParse('${j['fetchedAt']}');
    final list = j['quotes'];
    if (fetchedAt == null || list is! List) return null;
    final map = <GoldProduct, PriceQuote>{};
    for (final item in list) {
      final q = PriceQuote.fromJson(item);
      if (q != null) map[q.product] = q.asCached();
    }
    if (map.isEmpty) return null;
    return PriceSnapshot(
      quotes: map,
      fetchedAt: fetchedAt.toUtc(),
      status: DataStatus.cached,
    );
  }
}
