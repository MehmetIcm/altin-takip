import 'package:altin_takip/core/errors/data_exception.dart';
import 'package:altin_takip/data/providers/frankfurter_provider.dart';
import 'package:altin_takip/data/providers/truncgil_provider.dart';
import 'package:altin_takip/data/providers/xaus_provider.dart';
import 'package:altin_takip/domain/entities/gold_product.dart';
import 'package:flutter_test/flutter_test.dart';

// Trunçgil v4 gerçek yanıtından kısaltılmış örnek (3 Ekim 2026).
const _truncgil = {
  'Update_Date': '2026-10-03 09:38:02',
  'USD': {'Buying': 49.0737, 'Type': 'Currency', 'Selling': 49.1791, 'Change': 0.08},
  'GRA': {'Selling': 6542.72, 'Type': 'Gold', 'Name': 'GRAMALTIN', 'Change': -0.76, 'Buying': 6541.91},
  'ONS': {'Buying': 0, 'Type': 'Gold', 'Name': 'ONS', 'Selling': 0, 'Change': -0.84},
  'CEYREKALTIN': {'Buying': 10600.05, 'Type': 'Gold', 'Selling': 10850.27, 'Change': 0.96},
  'YIA': {'Buying': 6042.03, 'Type': 'Gold', 'Selling': 6052.26, 'Change': 0.96},
  'RESATALTIN': {'Buying': 43725.19, 'Type': 'Gold', 'Selling': 44861.07, 'Change': 0.96},
  'HAMITALTIN': {'Buying': 43725.19, 'Type': 'Gold', 'Selling': 44861.07, 'Change': 0.96},
  'XU100': {'Selling': 12270.18, 'Type': 'Gold', 'Change': 0.17},
};

void main() {
  group('Trunçgil', () {
    final quotes = TruncgilProvider.parse(_truncgil);
    final byProduct = {for (final q in quotes) q.product: q};

    test('Beklenen ürünler ayrıştırılır', () {
      expect(byProduct.keys, containsAll([
        GoldProduct.gram,
        GoldProduct.ceyrek,
        GoldProduct.bilezik22,
        GoldProduct.usdTry,
      ]));
      expect(byProduct[GoldProduct.gram]!.buy, 6541.91);
      expect(byProduct[GoldProduct.gram]!.sell, 6542.72);
      expect(byProduct[GoldProduct.gram]!.changePercent, -0.76);
    });

    test('Ons (0 değerli) ve Reşat/Hamit dahil edilmez', () {
      expect(byProduct.containsKey(GoldProduct.ons), isFalse);
      expect(quotes.length, 4);
    });

    test('Zaman damgası İstanbul saatinden UTC ana çevrilir', () {
      expect(byProduct[GoldProduct.gram]!.asOf, DateTime.utc(2026, 10, 3, 6, 38, 2));
    });

    test('Geçersiz yanıtlar hata verir, çökmez', () {
      expect(() => TruncgilProvider.parse('x'), throwsA(isA<DataSourceException>()));
      expect(() => TruncgilProvider.parse({'GRA': {}}), throwsA(isA<DataSourceException>()));
      expect(() => TruncgilProvider.parse({'Update_Date': '2026-10-03 09:38:02'}),
          throwsA(isA<DataSourceException>()));
      expect(() => TruncgilProvider.parse({'Update_Date': 'bozuk', 'GRA': {'Buying': 1, 'Selling': 2}}),
          throwsA(isA<DataSourceException>()));
    });

    test('Alış > satış olan kayıt atlanır', () {
      final q = TruncgilProvider.parse({
        'Update_Date': '2026-10-03 09:38:02',
        'GRA': {'Buying': 7000, 'Selling': 6000},
        'USD': {'Buying': 49, 'Selling': 50},
      });
      expect(q.map((e) => e.product), [GoldProduct.usdTry]);
    });
  });

  group('XAUS', () {
    test('Spot', () {
      final s = XausProvider.parseSpot({
        'xau': {'price': 4141.8, 'currency': 'USD'},
        'spot_usd_oz': 4141.799805,
        'price_as_of': '2026-10-03T17:53:42.152Z',
        'data_state': {'status': 'fresh'},
        'stale': false,
      });
      expect(s.priceUsd, closeTo(4141.8, 0.001));
      expect(s.stale, isFalse);
      expect(s.asOf.isUtc, isTrue);
    });

    test('Eski veri işaretlenir', () {
      final s = XausProvider.parseSpot({
        'spot_usd_oz': 4000,
        'price_as_of': '2026-10-03T10:00:00Z',
        'stale': true,
      });
      expect(s.stale, isTrue);
    });

    test('Kullanılamayan kaynak ve eksik fiyat hata verir', () {
      expect(
          () => XausProvider.parseSpot({
                'spot_usd_oz': 1,
                'updated_at': '2026-10-03T10:00:00Z',
                'data_state': {'status': 'unavailable'}
              }),
          throwsA(isA<DataSourceException>()));
      expect(() => XausProvider.parseSpot({}), throwsA(isA<DataSourceException>()));
    });

    test('Geçmiş sıralanır, günlük aralık okunur', () {
      final h = XausProvider.parseHistory({
        'points': [
          {'d': '2026-07-02', 'c': 4010.0, 'h': 4020.0, 'l': 3990.0},
          {'d': '2026-07-01', 'c': 4007.2},
          {'d': 'bozuk', 'c': 1},
        ],
        'ranges': {'day': {'low': 3988.6, 'high': 4021.1}},
      });
      expect(h.bars.length, 2);
      expect(h.bars.first.date, DateTime.utc(2026, 7, 1));
      expect(h.dayHigh, 4021.1);
      expect(h.dayLow, 3988.6);
    });

    test('Gün içi: milisaniye, saniye ve ISO zaman damgaları', () {
      final pts = XausProvider.parseIntraday({
        'points': [
          {'t': 1790000120000, 'p': 4100.5},
          {'t': 1790000000, 'p': 4100.0},
          {'t': '2026-10-03T10:00:00Z', 'p': 4101.0},
        ]
      });
      expect(pts.length, 3);
      expect(pts.first.time.isBefore(pts.last.time), isTrue);
    });
  });

  group('Frankfurter', () {
    test('Zaman serisi ayrıştırılır', () {
      final pts = FrankfurterProvider.parse({
        'base': 'USD',
        'rates': {
          '2026-10-02': {'TRY': 49.1},
          '2026-10-01': {'TRY': 49.0},
        }
      });
      expect(pts.map((p) => p.value), [49.0, 49.1]);
    });
    test('Boş yanıt hata verir', () {
      expect(() => FrankfurterProvider.parse({'rates': {}}), throwsA(isA<DataSourceException>()));
    });
  });
}
