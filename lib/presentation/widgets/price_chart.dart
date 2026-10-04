import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/data_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/chart_models.dart';
import '../../domain/entities/gold_product.dart';
import '../state/providers.dart';
import 'common_widgets.dart';

/// Dokunmatik uyumlu fiyat grafiği + zaman aralığı seçici.
/// Hesaplanmış seriler (gram) açıkça etiketlenir.
class PriceChart extends ConsumerStatefulWidget {
  const PriceChart({super.key, required this.product});
  final GoldProduct product;

  @override
  ConsumerState<PriceChart> createState() => _PriceChartState();
}

class _PriceChartState extends ConsumerState<PriceChart> {
  ChartRange _range = ChartRange.month;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final req = (widget.product, _range);
    final async = ref.watch(chartProvider(req));

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (final r in ChartRange.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Semantics(
                label: r.title,
                selected: r == _range,
                button: true,
                child: ChoiceChip(
                  label: Text(r.label),
                  selected: r == _range,
                  onSelected: (_) => setState(() => _range = r),
                ),
              ),
            ),
        ]),
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 260,
        child: async.when(
          loading: () => const SkeletonBox(height: 260),
          error: (e, _) => _ChartError(
            error: e,
            onRetry: () => ref.invalidate(chartProvider(req)),
          ),
          data: (s) => _Chart(series: s, product: widget.product),
        ),
      ),
      async.maybeWhen(
        data: (s) => Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (s.isComputed)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: withOpacityValue(p.gold, 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Hesaplanmış veri',
                    style: TextStyle(color: p.gold, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            if (s.note != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(s.note!, style: TextStyle(color: p.muted, fontSize: 12)),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Kaynak: ${s.source}', style: TextStyle(color: p.muted, fontSize: 12)),
            ),
          ]),
        ),
        orElse: () => const SizedBox.shrink(),
      ),
    ]);
  }
}

class _ChartError extends StatelessWidget {
  const _ChartError({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final msg = error is DataSourceException
        ? (error as DataSourceException).userMessage
        : 'Grafik verisi alınamadı.';
    return Panel(
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.show_chart_rounded, color: p.muted, size: 32),
          const SizedBox(height: 8),
          const Text('Grafik verisi şu anda alınamıyor.'),
          const SizedBox(height: 4),
          Text(msg, style: TextStyle(color: p.muted, fontSize: 12), textAlign: TextAlign.center),
          TextButton(onPressed: onRetry, child: const Text('Tekrar Dene')),
        ]),
      ),
    );
  }
}

class _Chart extends StatelessWidget {
  const _Chart({required this.series, required this.product});
  final ChartSeries series;
  final GoldProduct product;

  static const _maxPoints = 300;

  List<ChartPoint> _downsample(List<ChartPoint> pts) {
    if (pts.length <= _maxPoints) return pts;
    final step = (pts.length / _maxPoints).ceil();
    final out = <ChartPoint>[
      for (var i = 0; i < pts.length; i += step) pts[i],
    ];
    if (out.last != pts.last) out.add(pts.last);
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final pts = _downsample(series.points);
    final spots = [
      for (final x in pts) FlSpot(x.time.millisecondsSinceEpoch.toDouble(), x.value)
    ];
    var minY = pts.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    var maxY = pts.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final pad = (maxY - minY) * 0.08 + 0.01;
    minY -= pad;
    maxY += pad;
    final minX = spots.first.x;
    final maxX = spots.last.x;
    final span = Duration(milliseconds: (maxX - minX).toInt());
    final up = pts.last.value >= pts.first.value;
    final lineColor = up ? p.up : p.down;

    String xLabel(double v) {
      final t = DateTime.fromMillisecondsSinceEpoch(v.toInt(), isUtc: true);
      return span.inHours <= 48 ? Fmt.time(t) : Fmt.date(t).replaceAll(RegExp(r' \d{4}$'), '');
    }

    return Semantics(
      label:
          '${series.title} grafiği. İlk değer ${Fmt.price(product, pts.first.value)}, son değer ${Fmt.price(product, pts.last.value)}',
      child: LineChart(
        LineChartData(
          minX: minX,
          maxX: maxX,
          minY: minY,
          maxY: maxY,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(color: p.line, strokeWidth: 0.6),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 60,
                getTitlesWidget: (v, meta) {
                  if (v == meta.min || v == meta.max) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Text(Fmt.number(v).split(',').first,
                        style: TextStyle(color: p.muted, fontSize: 11)),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                interval: (maxX - minX) / 3,
                getTitlesWidget: (v, meta) {
                  if (v == meta.min || v == meta.max) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(xLabel(v), style: TextStyle(color: p.muted, fontSize: 11)),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => p.surfaceHigh,
              getTooltipItems: (touched) => touched
                  .map<LineTooltipItem?>((s) {
                    final t = DateTime.fromMillisecondsSinceEpoch(s.x.toInt(), isUtc: true);
                    return LineTooltipItem(
                      '${Fmt.dateTime(t)}\n${Fmt.price(product, s.y)}',
                      TextStyle(color: p.text, fontWeight: FontWeight.w600, fontSize: 12),
                    );
                  })
                  .toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: false,
              color: lineColor,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [withOpacityValue(lineColor, 0.25), withOpacityValue(lineColor, 0.0)],
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 250),
      ),
    );
  }
}
