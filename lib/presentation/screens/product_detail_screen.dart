import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../domain/calculators/gold_math.dart';
import '../../domain/entities/gold_product.dart';
import '../state/providers.dart';
import '../widgets/common_widgets.dart';
import '../widgets/price_chart.dart';
import '../widgets/price_widgets.dart';
import '../widgets/status_banner.dart';
import 'alerts_screen.dart';

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.product});
  final GoldProduct product;

  static const _chartable = {GoldProduct.gram, GoldProduct.has, GoldProduct.ons};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final q = ref.watch(quoteProvider(product));
    final p = AppPalette.of(context);
    final main = q?.reference;

    final stats = <Widget>[];
    if (q != null) {
      if (q.buy != null) stats.add(StatItem('Alış', Fmt.price(product, q.buy!)));
      if (q.sell != null) stats.add(StatItem('Satış', Fmt.price(product, q.sell!)));
      if (q.spread != null) {
        stats.add(StatItem('Makas (Satış - Alış)', Fmt.price(product, q.spread!)));
      }
      if (q.spreadPercent != null) {
        stats.add(StatItem('Makas %', Fmt.percent(q.spreadPercent!).replaceFirst('+', '')));
      }
      if (q.changePercent != null) {
        final c = q.changePercent!;
        stats.add(StatItem('Günlük değişim %', Fmt.percent(c),
            color: c > 0 ? p.up : (c < 0 ? p.down : null)));
        if (main != null && c > -100 && product != GoldProduct.ons && product.group != ProductGroup.fx) {
          final prev = main / (1 + c / 100);
          stats.add(StatItem('Günlük değişim (yaklaşık)', Fmt.signedTl(main - prev)));
        }
      }
      if (q.high != null) stats.add(StatItem('Günlük en yüksek', Fmt.price(product, q.high!)));
      if (q.low != null) stats.add(StatItem('Günlük en düşük', Fmt.price(product, q.low!)));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(product.title),
        actions: [
          FavoriteButton(product),
          IconButton(
            tooltip: 'Alarm kur',
            icon: const Icon(Icons.add_alert_outlined),
            onPressed: () => showAlertSheet(context, product: product),
          ),
        ],
      ),
      body: PageContainer(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            const StatusBanner(),
            if (q == null || main == null)
              const Panel(child: Text('Bu ürün için şu anda veri yok.'))
            else ...[
              Panel(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(q.sell != null ? 'Satış' : 'Fiyat', style: TextStyle(color: p.muted, fontSize: 12)),
                  FlashingPrice(
                    value: main,
                    text: Fmt.price(product, main),
                    style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: p.text, fontFeatures: tabularFigures),
                  ),
                  const SizedBox(height: 8),
                  ChangeChip(q.changePercent),
                  const SizedBox(height: 12),
                  Wrap(spacing: 32, runSpacing: 16, children: stats),
                  const SizedBox(height: 14),
                  Text(quoteStatusText(q),
                      style: TextStyle(color: q.cached || q.stale ? p.down : p.muted, fontSize: 12)),
                ]),
              ),
              if (product == GoldProduct.ons) _OnsPeriods(currentPrice: main),
              if (product == GoldProduct.bilezik22) ...[
                const SectionTitle('Bilezik hesabı'),
                Panel(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      'Fiyat, sağlayıcının 22 ayar bilezik (gram) fiyatıdır. İşçilik bilgisi '
                      'veri kaynağında olmadığı için eklenmemiştir.',
                      style: TextStyle(color: p.muted, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => context.go('/hesapla?urun=${product.name}'),
                      icon: const Icon(Icons.calculate_outlined),
                      label: const Text('Gram girerek hesapla'),
                    ),
                  ]),
                ),
              ],
            ],
            if (_chartable.contains(product)) ...[
              const SectionTitle('Grafik'),
              PriceChart(product: product),
            ] else
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text('Bu ürün için geçmiş fiyat veri kaynağı bulunmuyor.',
                    style: TextStyle(color: p.muted, fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }
}

class _OnsPeriods extends ConsumerWidget {
  const _OnsPeriods({required this.currentPrice});
  final double currentPrice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hist = ref.watch(onsHistoryProvider);
    final p = AppPalette.of(context);
    return hist.maybeWhen(
      data: (h) {
        final now = DateTime.now().toUtc();
        final items = <Widget>[];
        for (final e in {'Haftalık': 7, 'Aylık': 30, 'Yıllık': 365}.entries) {
          final c = GoldCalc.changeOver(h.bars, currentPrice, now, e.value);
          if (c != null) {
            items.add(StatItem('${e.key} değişim', Fmt.percent(c), color: c > 0 ? p.up : (c < 0 ? p.down : null)));
          }
        }
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SectionTitle('Dönemsel değişim'),
          Panel(child: Wrap(spacing: 32, runSpacing: 16, children: items)),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('Günlük kapanış verilerine göre hesaplanır.',
                style: TextStyle(color: p.muted, fontSize: 12)),
          ),
        ]);
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
