import '../../core/errors/data_exception.dart';
import '../../core/network/json_client.dart';
import '../../domain/entities/chart_models.dart';
import '../../domain/providers/data_providers.dart';

/// XAUS (anahtarsız). XAU/USD spot, günlük geçmiş ve gün içi kayıt.
/// Fiyatlar gösterge niteliğindeki mid-market oranlarıdır.
class XausProvider implements OnsProvider {
  XausProvider({JsonClient? client, String base = 'https://xaus.com'})
      : _client = client ?? JsonClient(),
        _base = base;

  final JsonClient _client;
  final String _base;

  @override
  String get name => 'XAUS';

  @override
  Future<OnsSpot> fetchSpot() async => parseSpot(
      await _client.getJson(Uri.parse('$_base/api/v1/spot?compact=1')));

  @override
  Future<OnsHistory> fetchHistory() async =>
      parseHistory(await _client.getJson(Uri.parse('$_base/api/v1/history')));

  @override
  Future<List<ChartPoint>> fetchIntraday({int hours = 24}) async =>
      parseIntraday(await _client
          .getJson(Uri.parse('$_base/api/v1/intraday?symbol=xau&hours=$hours')));

  static OnsSpot parseSpot(dynamic json) {
    if (json is! Map) {
      throw const DataSourceException(DataErrorKind.invalidResponse);
    }
    final xau = json['xau'];
    final price = _num(json['spot_usd_oz']) ?? (xau is Map ? _num(xau['price']) : null);
    if (price == null || price <= 0) {
      throw const DataSourceException(
          DataErrorKind.invalidResponse, 'Ons fiyatı yok');
    }
    final asOfRaw = json['price_as_of'] ?? json['updated_at'];
    final asOf = asOfRaw is String ? DateTime.tryParse(asOfRaw)?.toUtc() : null;
    if (asOf == null) {
      throw const DataSourceException(
          DataErrorKind.invalidResponse, 'Zaman damgası yok');
    }
    final state = json['data_state'];
    final status = state is Map ? state['status'] : null;
    if (status == 'unavailable') {
      throw const DataSourceException(DataErrorKind.server, 'Kaynak kullanılamıyor');
    }
    return OnsSpot(
      priceUsd: price,
      asOf: asOf,
      stale: json['stale'] == true || status == 'stale',
    );
  }

  static OnsHistory parseHistory(dynamic json) {
    if (json is! Map || json['points'] is! List) {
      throw const DataSourceException(DataErrorKind.invalidResponse);
    }
    final bars = <DailyBar>[];
    for (final p in json['points'] as List) {
      if (p is! Map) continue;
      final d = p['d'] is String ? DateTime.tryParse('${p['d']}T00:00:00Z') : null;
      final c = _num(p['c']);
      if (d == null || c == null || c <= 0) continue;
      bars.add(DailyBar(d.toUtc(), c, high: _num(p['h']), low: _num(p['l'])));
    }
    if (bars.isEmpty) throw const DataSourceException(DataErrorKind.empty);
    bars.sort((a, b) => a.date.compareTo(b.date));
    final ranges = json['ranges'];
    final day = ranges is Map ? ranges['day'] : null;
    return OnsHistory(
      bars: bars,
      dayHigh: day is Map ? _num(day['high']) : null,
      dayLow: day is Map ? _num(day['low']) : null,
    );
  }

  static List<ChartPoint> parseIntraday(dynamic json) {
    final raw = json is Map ? json['points'] : json;
    if (raw is! List) {
      throw const DataSourceException(DataErrorKind.invalidResponse);
    }
    final out = <ChartPoint>[];
    for (final p in raw) {
      if (p is! Map) continue;
      final t = _time(p['t']);
      final v = _num(p['p']);
      if (t == null || v == null || v <= 0) continue;
      out.add(ChartPoint(t, v));
    }
    if (out.length < 2) throw const DataSourceException(DataErrorKind.empty);
    out.sort((a, b) => a.time.compareTo(b.time));
    return out;
  }

  static DateTime? _time(dynamic t) {
    if (t is num) {
      final ms = t > 1e12 ? t.toInt() : (t * 1000).toInt();
      return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
    }
    if (t is String) return DateTime.tryParse(t)?.toUtc();
    return null;
  }

  static double? _num(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}
