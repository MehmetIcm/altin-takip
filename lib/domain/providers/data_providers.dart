import '../entities/chart_models.dart';
import '../entities/price_quote.dart';

/// Türkiye altın/döviz fiyatları (alış/satış) sağlayıcısı.
/// Yeni bir kaynak eklemek için bu arayüzü uygulamak yeterlidir.
abstract class QuoteProvider {
  String get name;
  Future<List<PriceQuote>> fetchQuotes();
}

/// Ons altın (XAU/USD) sağlayıcısı.
abstract class OnsProvider {
  String get name;
  Future<OnsSpot> fetchSpot();
  Future<OnsHistory> fetchHistory();
  Future<List<ChartPoint>> fetchIntraday({int hours = 24});
}

/// USD/TRY geçmiş verisi sağlayıcısı.
abstract class FxHistoryProvider {
  String get name;
  Future<List<ChartPoint>> usdTryHistory(DateTime from, DateTime to);
}
