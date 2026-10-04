import '../../core/errors/data_exception.dart';
import '../../core/network/json_client.dart';
import '../../core/utils/istanbul_time.dart';
import '../../domain/entities/gold_product.dart';
import '../../domain/entities/price_quote.dart';
import '../../domain/providers/data_providers.dart';

/// Trunçgil Finans (anahtarsız). Türkiye altın ve döviz alış/satış fiyatları.
/// Ons ve Reşat/Hamit bilinçli olarak eşlenmemiştir (bkz. docs/DATA_PROVIDERS.md).
class TruncgilProvider implements QuoteProvider {
  TruncgilProvider({JsonClient? client, Uri? endpoint})
      : _client = client ?? JsonClient(),
        _endpoint = endpoint ?? defaultEndpoint;

  static final Uri defaultEndpoint =
      Uri.parse('https://finans.truncgil.com/v4/today.json');

  final JsonClient _client;
  final Uri _endpoint;

  @override
  String get name => 'Trunçgil';

  @override
  Future<List<PriceQuote>> fetchQuotes() async =>
      parse(await _client.getJson(_endpoint));

  static const Map<String, GoldProduct> _keys = {
    'GRA': GoldProduct.gram,
    'HAS': GoldProduct.has,
    'CEYREKALTIN': GoldProduct.ceyrek,
    'YARIMALTIN': GoldProduct.yarim,
    'TAMALTIN': GoldProduct.tam,
    'CUMHURIYETALTINI': GoldProduct.cumhuriyet,
    'ATAALTIN': GoldProduct.ata,
    '14AYARALTIN': GoldProduct.ayar14,
    '18AYARALTIN': GoldProduct.ayar18,
    'YIA': GoldProduct.bilezik22,
    'GUMUS': GoldProduct.gumus,
    'USD': GoldProduct.usdTry,
    'EUR': GoldProduct.eurTry,
    'GBP': GoldProduct.gbpTry,
  };

  /// Yanıtı ayrıştırır. Alış/satış değeri eksik, sıfır veya mantıksız
  /// (alış > satış) olan ürünler atlanır; hiçbiri kalmazsa hata fırlatır.
  static List<PriceQuote> parse(dynamic json) {
    if (json is! Map) {
      throw const DataSourceException(
          DataErrorKind.invalidResponse, 'Kök nesne değil');
    }
    final dateRaw = json['Update_Date'];
    if (dateRaw is! String) {
      throw const DataSourceException(
          DataErrorKind.invalidResponse, 'Update_Date yok');
    }
    final DateTime asOf;
    try {
      asOf = IstanbulTime.parseWall(dateRaw);
    } on FormatException {
      throw const DataSourceException(
          DataErrorKind.invalidResponse, 'Update_Date çözümlenemedi');
    }
    final out = <PriceQuote>[];
    _keys.forEach((key, product) {
      final e = json[key];
      if (e is! Map) return;
      final buy = _num(e['Buying']);
      final sell = _num(e['Selling']);
      if (buy == null || sell == null || buy <= 0 || sell <= 0 || buy > sell) {
        return;
      }
      var change = _num(e['Change']);
      if (change != null && change.abs() > 25) change = null; // mantıksız
      out.add(PriceQuote(
        product: product,
        buy: buy,
        sell: sell,
        changePercent: change,
        asOf: asOf,
        source: 'Trunçgil',
      ));
    });
    if (out.isEmpty) throw const DataSourceException(DataErrorKind.empty);
    return out;
  }

  static double? _num(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}
