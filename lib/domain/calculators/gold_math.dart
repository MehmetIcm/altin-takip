import '../entities/chart_models.dart';
import '../entities/portfolio_item.dart';
import '../entities/price_alert.dart';
import '../entities/price_quote.dart';

const double gramsPerTroyOunce = 31.1034768;

/// Basit dönüşümler. Alış/satış farkı çağıran tarafından seçilir:
/// altın alırken satış, bozdururken alış fiyatı kullanılır.
class GoldCalc {
  static double? amountToTl(double amount, double? unitPrice) =>
      unitPrice == null ? null : amount * unitPrice;

  static double? tlToAmount(double tl, double? unitPrice) =>
      (unitPrice == null || unitPrice <= 0) ? null : tl / unitPrice;

  /// Ons (USD) fiyatı ve USD/TRY'den gram (TL) fiyatı.
  static double gramTlFromOunce(double ounceUsd, double usdTry) =>
      ounceUsd * usdTry / gramsPerTroyOunce;

  /// [bars] içinde, hedef tarihte veya ondan önceki son kapanışa göre değişim %.
  static double? changeOver(
      List<DailyBar> bars, double current, DateTime nowUtc, int days) {
    final target = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day)
        .subtract(Duration(days: days));
    DailyBar? ref;
    for (final b in bars) {
      if (!b.date.isAfter(target)) ref = b;
    }
    if (ref == null || ref.close <= 0) return null;
    return (current - ref.close) / ref.close * 100;
  }
}

class Valuation {
  const Valuation({required this.value, this.cost, this.dailyChange});
  final double value;
  final double? cost;
  final double? dailyChange;

  double? get pnl => cost == null ? null : value - cost!;
  double? get pnlPercent =>
      (cost == null || cost! <= 0) ? null : (value - cost!) / cost! * 100;
}

class PortfolioTotals {
  const PortfolioTotals({
    required this.value,
    this.dailyChange,
    this.cost,
    this.pnl,
    this.pnlPercent,
  });
  final double value;
  final double? dailyChange;
  final double? cost;
  final double? pnl;
  final double? pnlPercent;
}

class PortfolioMath {
  /// Değerleme ALIŞ fiyatı üzerinden yapılır: bozdurulursa elde edilecek tutar.
  static Valuation? valueItem(PortfolioItem item, PriceQuote quote) {
    final bid = quote.bid;
    if (bid == null) return null;
    final value = item.amount * bid;
    final cost = item.buyPrice == null ? null : item.amount * item.buyPrice!;
    double? daily;
    final c = quote.changePercent;
    if (c != null && c > -100) daily = value - value / (1 + c / 100);
    return Valuation(value: value, cost: cost, dailyChange: daily);
  }

  static PortfolioTotals total(List<Valuation> items) {
    var value = 0.0;
    var daily = 0.0;
    var dailyKnown = items.isNotEmpty;
    var cost = 0.0;
    var valueOfCosted = 0.0;
    var anyCost = false;
    for (final v in items) {
      value += v.value;
      if (v.dailyChange == null) {
        dailyKnown = false;
      } else {
        daily += v.dailyChange!;
      }
      if (v.cost != null) {
        anyCost = true;
        cost += v.cost!;
        valueOfCosted += v.value;
      }
    }
    final pnl = anyCost ? valueOfCosted - cost : null;
    return PortfolioTotals(
      value: value,
      dailyChange: dailyKnown ? daily : null,
      cost: anyCost ? cost : null,
      pnl: pnl,
      pnlPercent: (anyCost && cost > 0) ? pnl! / cost * 100 : null,
    );
  }
}

class AlertEvaluator {
  static bool isTriggered(PriceAlert a, double price) {
    if (!a.active) return false;
    switch (a.type) {
      case AlertType.above:
        return price >= a.threshold;
      case AlertType.below:
        return price <= a.threshold;
      case AlertType.percentChange:
        final b = a.baseline;
        if (b == null || b <= 0) return false;
        return ((price - b) / b * 100).abs() >= a.threshold;
    }
  }
}

class ListingCheck {
  const ListingCheck({
    required this.goldValue,
    required this.premium,
    required this.premiumPercent,
    required this.pricePerGram,
  });

  /// Altın değeri: gram x güncel (satış) gram fiyatı.
  final double goldValue;

  /// İlan fiyatı - altın değeri. İşçilik, kâr payı, KDV vb. içerir.
  final double premium;
  final double premiumPercent;

  /// İlan fiyatının gram başına karşılığı.
  final double pricePerGram;
}

class BraceletMath {
  /// Bir bilezik ilanının güncel altın değerine göre ne kadar farklı olduğunu hesaplar.
  /// Veri uydurmaz: [goldPerGram] güncel piyasa fiyatından gelmelidir.
  static ListingCheck? compare({
    required double listingPrice,
    required double grams,
    required double? goldPerGram,
  }) {
    if (goldPerGram == null || goldPerGram <= 0 || grams <= 0 || listingPrice <= 0) {
      return null;
    }
    final value = grams * goldPerGram;
    final premium = listingPrice - value;
    return ListingCheck(
      goldValue: value,
      premium: premium,
      premiumPercent: premium / value * 100,
      pricePerGram: listingPrice / grams,
    );
  }
}
