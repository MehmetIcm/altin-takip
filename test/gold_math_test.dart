import 'package:altin_takip/domain/calculators/gold_math.dart';
import 'package:altin_takip/domain/entities/chart_models.dart';
import 'package:altin_takip/domain/entities/gold_product.dart';
import 'package:altin_takip/domain/entities/portfolio_item.dart';
import 'package:altin_takip/domain/entities/price_quote.dart';
import 'package:flutter_test/flutter_test.dart';

PriceQuote quote({double? buy, double? sell, double? change}) => PriceQuote(
      product: GoldProduct.gram,
      buy: buy,
      sell: sell,
      changePercent: change,
      asOf: DateTime.utc(2026, 10, 3),
      source: 'test',
    );

void main() {
  bilezikTests();
  group('Makas', () {
    test('Makas = Satış - Alış, yüzde satışa göre', () {
      final q = quote(buy: 10600, sell: 10850);
      expect(q.spread, 250);
      expect(q.spreadPercent, closeTo(2.304, 0.001));
    });
    test('Alış veya satış yoksa makas yok', () {
      expect(quote(sell: 100).spread, isNull);
      expect(quote(buy: 100).spreadPercent, isNull);
    });
  });

  group('Dönüşümler', () {
    test('Gram -> TL ve TL -> gram', () {
      expect(GoldCalc.amountToTl(15, 6000), 90000);
      expect(GoldCalc.tlToAmount(90000, 6000), 15);
      expect(GoldCalc.tlToAmount(100, 0), isNull);
      expect(GoldCalc.amountToTl(1, null), isNull);
    });
    test('Ons ve kurdan gram fiyatı', () {
      expect(GoldCalc.gramTlFromOunce(gramsPerTroyOunce * 100, 50), closeTo(5000, 1e-9));
    });
  });

  group('Portföy', () {
    final item = PortfolioItem(
      id: '1',
      product: GoldProduct.gram,
      amount: 25,
      buyPrice: 5900,
      addedAt: DateTime.utc(2026, 1, 1),
    );

    test('Değer alış fiyatı üzerinden, kâr/zarar doğru', () {
      final v = PortfolioMath.valueItem(item, quote(buy: 6500, sell: 6510, change: 1))!;
      expect(v.value, 25 * 6500);
      expect(v.cost, 25 * 5900);
      expect(v.pnl, 25 * 600);
      expect(v.pnlPercent, closeTo(600 / 5900 * 100, 1e-9));
      expect(v.dailyChange, closeTo(25 * 6500 - 25 * 6500 / 1.01, 1e-6));
    });

    test('Zarar negatif', () {
      final v = PortfolioMath.valueItem(item, quote(buy: 5000, sell: 5010))!;
      expect(v.pnl, 25 * -900);
      expect(v.pnlPercent!, lessThan(0));
      expect(v.dailyChange, isNull);
    });

    test('Alış fiyatı girilmediyse kâr/zarar yok', () {
      final noCost = PortfolioItem(
          id: '2', product: GoldProduct.gram, amount: 10, addedAt: DateTime.utc(2026));
      final v = PortfolioMath.valueItem(noCost, quote(buy: 6000, sell: 6010))!;
      expect(v.pnl, isNull);
      final t = PortfolioMath.total([v]);
      expect(t.pnl, isNull);
      expect(t.value, 60000);
    });

    test('Toplam yalnızca maliyeti olan kalemlerden kâr/zarar hesaplar', () {
      final a = const Valuation(value: 1000, cost: 800);
      final b = const Valuation(value: 500);
      final t = PortfolioMath.total([a, b]);
      expect(t.value, 1500);
      expect(t.pnl, 200);
      expect(t.pnlPercent, 25);
      expect(t.dailyChange, isNull);
    });
  });

  group('Dönemsel değişim', () {
    final bars = [
      for (var i = 0; i < 40; i++)
        DailyBar(DateTime.utc(2026, 9, 1).add(Duration(days: i)), 100.0 + i),
    ];
    test('7 gün önceki kapanışa göre', () {
      // now = 10 Eki; hedef = 3 Eki -> bar i=32 (kapanış 132)
      final c = GoldCalc.changeOver(bars, 142, DateTime.utc(2026, 10, 10), 7);
      expect(c, closeTo((142 - 132) / 132 * 100, 1e-9));
    });
    test('Yeterli geçmiş yoksa null', () {
      expect(GoldCalc.changeOver(bars, 142, DateTime.utc(2026, 10, 10), 365), isNull);
    });
  });
}

void bilezikTests() {
  group('Bilezik ilan kontrolü', () {
    test('Fark ve yüzde doğru hesaplanır', () {
      final r = BraceletMath.compare(listingPrice: 70000, grams: 10, goldPerGram: 6000)!;
      expect(r.goldValue, 60000);
      expect(r.premium, 10000);
      expect(r.premiumPercent, closeTo(16.6667, 0.001));
      expect(r.pricePerGram, 7000);
    });
    test('İlan altın değerinden ucuzsa fark negatif', () {
      final r = BraceletMath.compare(listingPrice: 55000, grams: 10, goldPerGram: 6000)!;
      expect(r.premium, -5000);
    });
    test('Geçersiz girdilerde null', () {
      expect(BraceletMath.compare(listingPrice: 1, grams: 0, goldPerGram: 6000), isNull);
      expect(BraceletMath.compare(listingPrice: 1, grams: 1, goldPerGram: null), isNull);
      expect(BraceletMath.compare(listingPrice: 0, grams: 1, goldPerGram: 6000), isNull);
    });
  });
}
