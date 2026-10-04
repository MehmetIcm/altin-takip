import '../../core/errors/data_exception.dart';
import '../../domain/calculators/gold_math.dart';
import '../../domain/entities/chart_models.dart';
import '../../domain/entities/gold_product.dart';
import '../../domain/entities/price_quote.dart';
import '../../domain/entities/price_snapshot.dart';
import '../../domain/providers/data_providers.dart';
import '../cache/snapshot_cache.dart';

class _Cached<T> {
  _Cached(this.value, this.at);
  final T value;
  final DateTime at;
}

/// UI ile veri sağlayıcıları arasındaki tek giriş noktası.
/// - Türkiye fiyatları: [quoteProviders] öncelik sırasıyla denenir (yedek desteği).
/// - Hiçbir kaynak çalışmazsa önbellek, "önbellek" işaretiyle gösterilir.
/// - Hiçbir koşulda sahte/rastgele fiyat üretmez.
class GoldRepository {
  GoldRepository({
    required this.quoteProviders,
    required this.ons,
    required this.fx,
    required this.cache,
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now;

  final List<QuoteProvider> quoteProviders;
  final OnsProvider ons;
  final FxHistoryProvider fx;
  final SnapshotCache cache;
  final DateTime Function() _now;

  static const _historyTtl = Duration(hours: 6);
  _Cached<OnsHistory>? _history;
  final Map<String, _Cached<ChartSeries>> _series = {};

  /// Uygulama açılırken hemen gösterilecek önbellek (varsa).
  PriceSnapshot? readCached() => cache.load();

  Future<PriceSnapshot> loadSnapshot() async {
    final issues = <String>[];
    final fresh = <GoldProduct, PriceQuote>{};

    // Bir yedek sağlayıcı başarılı olursa, öndekilerin hatası kullanıcıya
    // yansıtılmaz (veri yine de güncel ve eksiksizdir).
    final quoteIssues = <String>[];
    var quotesOk = false;
    for (final p in quoteProviders) {
      try {
        for (final q in await p.fetchQuotes()) {
          fresh.putIfAbsent(q.product, () => q);
        }
        quotesOk = true;
        break; // ilk başarılı sağlayıcı yeterli
      } on DataSourceException catch (e) {
        quoteIssues.add('${p.name}: ${e.userMessage}');
      } catch (_) {
        quoteIssues.add('${p.name}: Beklenmeyen bir hata oluştu.');
      }
    }
    if (!quotesOk) issues.addAll(quoteIssues);

    try {
      final spot = await ons.fetchSpot();
      OnsHistory? hist;
      try {
        hist = await onsHistory();
      } catch (_) {
        hist = null; // değişim yüzdesi olmadan devam
      }
      fresh[GoldProduct.ons] = _onsQuote(spot, hist);
    } on DataSourceException catch (e) {
      issues.add('${ons.name}: ${e.userMessage}');
    } catch (_) {
      issues.add('${ons.name}: Beklenmeyen bir hata oluştu.');
    }

    final cached = cache.load();
    final merged = <GoldProduct, PriceQuote>{...fresh};
    var usedCache = false;
    if (cached != null) {
      for (final e in cached.quotes.entries) {
        if (!merged.containsKey(e.key)) {
          merged[e.key] = e.value; // zaten cached işaretli
          usedCache = true;
        }
      }
    }

    if (merged.isEmpty) {
      return PriceSnapshot.unavailable(_now().toUtc(), issues);
    }
    if (fresh.isEmpty) {
      return PriceSnapshot(
        quotes: merged,
        fetchedAt: cached!.fetchedAt,
        status: DataStatus.cached,
        issues: issues,
      );
    }

    final snapshot = PriceSnapshot(
      quotes: merged,
      fetchedAt: _now().toUtc(),
      status: (issues.isEmpty && !usedCache) ? DataStatus.live : DataStatus.partial,
      issues: issues,
    );
    try {
      await cache.save(snapshot);
    } catch (_) {/* önbellek yazılamazsa sessizce devam */}
    return snapshot;
  }

  PriceQuote _onsQuote(OnsSpot s, OnsHistory? h) {
    double? change;
    if (h != null && h.bars.isNotEmpty) {
      final today = DateTime.utc(s.asOf.year, s.asOf.month, s.asOf.day);
      final before = h.bars.where((b) => b.date.isBefore(today));
      if (before.isNotEmpty && before.last.close > 0) {
        change = (s.priceUsd - before.last.close) / before.last.close * 100;
      }
    }
    return PriceQuote(
      product: GoldProduct.ons,
      last: s.priceUsd,
      changePercent: change,
      high: h?.dayHigh,
      low: h?.dayLow,
      asOf: s.asOf,
      source: ons.name,
      stale: s.stale,
    );
  }

  Future<OnsHistory> onsHistory() async {
    final h = _history;
    if (h != null && _now().difference(h.at) < _historyTtl) return h.value;
    final fresh = await ons.fetchHistory();
    _history = _Cached(fresh, _now());
    return fresh;
  }

  /// Grafik serisi. Desteklenmeyen ürün için [DataSourceException] (empty) atar.
  Future<ChartSeries> series(GoldProduct p, ChartRange r, {double? usdTryNow}) async {
    final key = '${p.name}_${r.name}';
    final c = _series[key];
    final ttl = r == ChartRange.day ? const Duration(minutes: 2) : _historyTtl;
    if (c != null && _now().difference(c.at) < ttl) return c.value;

    final ChartSeries s;
    switch (p) {
      case GoldProduct.ons:
        s = await _onsSeries(r);
        break;
      case GoldProduct.gram:
      case GoldProduct.has:
        s = await _gramSeries(p, r, usdTryNow);
        break;
      default:
        throw const DataSourceException(
            DataErrorKind.empty, 'Bu ürün için geçmiş veri kaynağı yok');
    }
    _series[key] = _Cached(s, _now());
    return s;
  }

  Future<ChartSeries> _onsSeries(ChartRange r) async {
    if (r == ChartRange.day) {
      final pts = await ons.fetchIntraday(hours: 24);
      return ChartSeries(
        points: pts,
        title: 'Ons Altın (USD)',
        source: ons.name,
        note: 'Son 24 saat, yaklaşık 2 dakikalık kayıtlar.',
      );
    }
    final h = await onsHistory();
    final pts = _slice(h.bars, r);
    if (pts.length < 2) throw const DataSourceException(DataErrorKind.empty);
    return ChartSeries(
      points: [for (final b in pts) ChartPoint(b.date, b.close)],
      title: 'Ons Altın (USD)',
      source: ons.name,
      note: 'Günlük kapanış değerleri.',
    );
  }

  Future<ChartSeries> _gramSeries(GoldProduct p, ChartRange r, double? usdTryNow) async {
    final title = '${p.title} (hesaplanmış)';
    const note = 'Piyasadan alınan gram fiyatı değildir: ons fiyatı × USD/TRY '
        '÷ 31,1035 ile hesaplanmıştır. Gerçek alış/satış fiyatından farklı olabilir.';
    if (r == ChartRange.day) {
      if (usdTryNow == null || usdTryNow <= 0) {
        throw const DataSourceException(
            DataErrorKind.empty, 'Güncel USD/TRY yok');
      }
      final pts = await ons.fetchIntraday(hours: 24);
      return ChartSeries(
        points: [for (final x in pts) ChartPoint(x.time, GoldCalc.gramTlFromOunce(x.value, usdTryNow))],
        title: title,
        source: '${ons.name} + güncel USD/TRY',
        isComputed: true,
        note: note,
      );
    }
    final h = await onsHistory();
    final bars = _slice(h.bars, r);
    if (bars.length < 2) throw const DataSourceException(DataErrorKind.empty);
    final rates = await fx.usdTryHistory(
        bars.first.date.subtract(const Duration(days: 10)), bars.last.date);
    final pts = <ChartPoint>[];
    var i = 0;
    double? rate;
    for (final b in bars) {
      while (i < rates.length && !rates[i].time.isAfter(b.date)) {
        rate = rates[i].value;
        i++;
      }
      if (rate == null) continue;
      pts.add(ChartPoint(b.date, GoldCalc.gramTlFromOunce(b.close, rate)));
    }
    if (pts.length < 2) throw const DataSourceException(DataErrorKind.empty);
    return ChartSeries(
      points: pts,
      title: title,
      source: '${ons.name} + ${fx.name}',
      isComputed: true,
      note: note,
    );
  }

  List<DailyBar> _slice(List<DailyBar> bars, ChartRange r) {
    if (bars.isEmpty) return const [];
    final cutoff = bars.last.date.subtract(Duration(days: r.days));
    return bars.where((b) => !b.date.isBefore(cutoff)).toList();
  }

  Future<void> clearCache() async {
    await cache.clear();
    _history = null;
    _series.clear();
  }
}
