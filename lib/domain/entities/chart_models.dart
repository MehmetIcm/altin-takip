enum ChartRange {
  day('1G', '1 Gün', 1),
  week('1H', '1 Hafta', 7),
  month('1A', '1 Ay', 30),
  quarter('3A', '3 Ay', 90),
  halfYear('6A', '6 Ay', 182),
  year('1Y', '1 Yıl', 365),
  fiveYears('5Y', '5 Yıl', 1826);

  const ChartRange(this.label, this.title, this.days);
  final String label;
  final String title;
  final int days;
}

class ChartPoint {
  const ChartPoint(this.time, this.value);
  final DateTime time; // UTC an
  final double value;
}

class ChartSeries {
  const ChartSeries({
    required this.points,
    required this.title,
    required this.source,
    this.isComputed = false,
    this.note,
  });

  final List<ChartPoint> points;
  final String title;
  final String source;

  /// Doğrudan piyasa fiyatı değil, başka verilerden hesaplanmış seri.
  final bool isComputed;
  final String? note;
}

class DailyBar {
  const DailyBar(this.date, this.close, {this.high, this.low});
  final DateTime date; // UTC gün başı
  final double close;
  final double? high;
  final double? low;
}

class OnsSpot {
  const OnsSpot({required this.priceUsd, required this.asOf, this.stale = false});
  final double priceUsd;
  final DateTime asOf;
  final bool stale;
}

class OnsHistory {
  const OnsHistory({required this.bars, this.dayHigh, this.dayLow});
  final List<DailyBar> bars;
  final double? dayHigh;
  final double? dayLow;
}
