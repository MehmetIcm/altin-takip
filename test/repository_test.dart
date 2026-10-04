import 'package:altin_takip/core/errors/data_exception.dart';
import 'package:altin_takip/data/cache/snapshot_cache.dart';
import 'package:altin_takip/data/repositories/gold_repository.dart';
import 'package:altin_takip/domain/entities/chart_models.dart';
import 'package:altin_takip/domain/entities/gold_product.dart';
import 'package:altin_takip/domain/entities/price_quote.dart';
import 'package:altin_takip/domain/entities/price_snapshot.dart';
import 'package:altin_takip/domain/providers/data_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeQuotes implements QuoteProvider {
  FakeQuotes(this.name, this.result);
  @override
  final String name;
  Object result; // List<PriceQuote> veya Exception
  int calls = 0;
  @override
  Future<List<PriceQuote>> fetchQuotes() async {
    calls++;
    final r = result;
    if (r is Exception) throw r;
    return r as List<PriceQuote>;
  }
}

class FakeOns implements OnsProvider {
  FakeOns({this.fail = false});
  bool fail;
  @override
  String get name => 'FakeOns';
  @override
  Future<OnsSpot> fetchSpot() async {
    if (fail) throw const DataSourceException(DataErrorKind.network);
    return OnsSpot(priceUsd: 4100, asOf: DateTime.utc(2026, 10, 3, 12));
  }

  @override
  Future<OnsHistory> fetchHistory() async => OnsHistory(bars: [
        DailyBar(DateTime.utc(2026, 10, 1), 4000),
        DailyBar(DateTime.utc(2026, 10, 2), 4050),
      ]);
  @override
  Future<List<ChartPoint>> fetchIntraday({int hours = 24}) async => [
        ChartPoint(DateTime.utc(2026, 10, 3, 1), 4090),
        ChartPoint(DateTime.utc(2026, 10, 3, 2), 4100),
      ];
}

class FakeFx implements FxHistoryProvider {
  @override
  String get name => 'FakeFx';
  @override
  Future<List<ChartPoint>> usdTryHistory(DateTime from, DateTime to) async => [
        ChartPoint(DateTime.utc(2026, 9, 28), 49),
        ChartPoint(DateTime.utc(2026, 10, 2), 50),
      ];
}

PriceQuote gram() => PriceQuote(
      product: GoldProduct.gram,
      buy: 6500,
      sell: 6510,
      changePercent: 0.5,
      asOf: DateTime.utc(2026, 10, 3, 6),
      source: 'Fake',
    );

void main() {
  late SnapshotCache cache;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    cache = SnapshotCache(await SharedPreferences.getInstance());
  });

  GoldRepository repo(List<QuoteProvider> q, {FakeOns? ons}) => GoldRepository(
        quoteProviders: q,
        ons: ons ?? FakeOns(),
        fx: FakeFx(),
        cache: cache,
        clock: () => DateTime.utc(2026, 10, 3, 12, 5),
      );

  test('Tüm kaynaklar çalışınca durum canlı ve ons değişimi hesaplanır', () async {
    final s = await repo([FakeQuotes('A', [gram()])]).loadSnapshot();
    expect(s.status, DataStatus.live);
    expect(s[GoldProduct.gram]!.cached, isFalse);
    // önceki kapanış 4050 -> 4100 = +%1,2346
    expect(s[GoldProduct.ons]!.changePercent, closeTo(1.2346, 0.001));
  });

  test('Birincil sağlayıcı çökerse yedek devreye girer', () async {
    final primary = FakeQuotes('A', const DataSourceException(DataErrorKind.server));
    final backup = FakeQuotes('B', [gram()]);
    final s = await repo([primary, backup]).loadSnapshot();
    expect(primary.calls, 1);
    expect(backup.calls, 1);
    expect(s[GoldProduct.gram], isNotNull);
    expect(s.status, DataStatus.live);
    expect(s.issues, isEmpty);
  });

  test('Tüm TL kaynakları çökerse önbellek "önbellek" olarak işaretlenir', () async {
    final ok = FakeQuotes('A', [gram()]);
    final r = repo([ok]);
    await r.loadSnapshot(); // önbelleği doldurur

    ok.result = const DataSourceException(DataErrorKind.timeout);
    final s = await r.loadSnapshot();
    expect(s.status, DataStatus.partial);
    expect(s[GoldProduct.gram]!.cached, isTrue);
    expect(s[GoldProduct.ons]!.cached, isFalse);
    expect(s.issues.single, contains('A:'));
  });

  test('Hiçbir kaynak çalışmazsa yalnızca önbellek gösterilir', () async {
    final ok = FakeQuotes('A', [gram()]);
    final ons = FakeOns();
    final r = repo([ok], ons: ons);
    await r.loadSnapshot();

    ok.result = const DataSourceException(DataErrorKind.network);
    ons.fail = true;
    final s = await r.loadSnapshot();
    expect(s.status, DataStatus.cached);
    expect(s.quotes.values.every((q) => q.cached), isTrue);
    expect(s.fetchedAt, DateTime.utc(2026, 10, 3, 12, 5));
  });

  test('Önbellek de yoksa uygulama "veri yok" durumuna geçer, sahte veri üretmez', () async {
    final s = await repo([FakeQuotes('A', const DataSourceException(DataErrorKind.network))],
            ons: FakeOns(fail: true))
        .loadSnapshot();
    expect(s.status, DataStatus.unavailable);
    expect(s.quotes, isEmpty);
    expect(s.issues.length, 2);
  });

  test('Gram grafiği hesaplanmış olarak işaretlenir', () async {
    final series = await repo([FakeQuotes('A', [gram()])])
        .series(GoldProduct.gram, ChartRange.month, usdTryNow: 50);
    expect(series.isComputed, isTrue);
    expect(series.title, contains('hesaplanmış'));
    expect(series.points.length, 2);
    // 4000 USD/oz * 49 / 31.1034768
    expect(series.points.first.value, closeTo(4000 * 49 / 31.1034768, 1e-6));
  });

  test('Ons grafiği hesaplanmış değildir; desteklenmeyen ürün hata verir', () async {
    final r = repo([FakeQuotes('A', [gram()])]);
    final ons = await r.series(GoldProduct.ons, ChartRange.week);
    expect(ons.isComputed, isFalse);
    await expectLater(r.series(GoldProduct.ceyrek, ChartRange.week),
        throwsA(isA<DataSourceException>()));
  });
}
