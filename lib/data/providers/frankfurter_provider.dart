import '../../core/errors/data_exception.dart';
import '../../core/network/json_client.dart';
import '../../domain/entities/chart_models.dart';
import '../../domain/providers/data_providers.dart';

/// Frankfurter (ECB referans kurları, anahtarsız). Yalnızca geçmiş USD/TRY.
/// ECB hafta sonu ve tatillerde kur yayımlamaz; boşluklar çağıran tarafından
/// bir önceki değerle doldurulur.
class FrankfurterProvider implements FxHistoryProvider {
  FrankfurterProvider({JsonClient? client, String base = 'https://api.frankfurter.dev'})
      : _client = client ?? JsonClient(),
        _base = base;

  final JsonClient _client;
  final String _base;

  @override
  String get name => 'Frankfurter (ECB)';

  static String _d(DateTime d) => d.toUtc().toIso8601String().substring(0, 10);

  @override
  Future<List<ChartPoint>> usdTryHistory(DateTime from, DateTime to) async =>
      parse(await _client.getJson(
          Uri.parse('$_base/v1/${_d(from)}..${_d(to)}?base=USD&symbols=TRY')));

  static List<ChartPoint> parse(dynamic json) {
    if (json is! Map || json['rates'] is! Map) {
      throw const DataSourceException(DataErrorKind.invalidResponse);
    }
    final out = <ChartPoint>[];
    (json['rates'] as Map).forEach((k, v) {
      final d = DateTime.tryParse('${k}T00:00:00Z');
      final r = v is Map ? v['TRY'] : null;
      if (d != null && r is num && r > 0) out.add(ChartPoint(d.toUtc(), r.toDouble()));
    });
    if (out.isEmpty) throw const DataSourceException(DataErrorKind.empty);
    out.sort((a, b) => a.time.compareTo(b.time));
    return out;
  }
}
