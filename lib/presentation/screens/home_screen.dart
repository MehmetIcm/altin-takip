import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/gold_product.dart';
import '../../domain/entities/price_quote.dart';
import '../../domain/entities/price_snapshot.dart';
import '../state/providers.dart';
import '../widgets/common_widgets.dart';
import '../widgets/price_widgets.dart';
import '../widgets/status_banner.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(snapshotProvider);
    final snap = state.snapshot;
    final favs = ref.watch(favoritesProvider);
    final waiting = snap == null && state.loading;

    final goldList = [
      for (final p in GoldProduct.values)
        if ((p.group == ProductGroup.gold || p.group == ProductGroup.coin) &&
            p != GoldProduct.gram)
          p
    ];
    final otherList = [
      for (final p in GoldProduct.values)
        if (p.group == ProductGroup.fx || p.group == ProductGroup.metal) p
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(S.appName),
        actions: [
          IconButton(
            tooltip: 'Alarmlar',
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => context.push('/alarmlar'),
          ),
          IconButton(
            tooltip: 'Ayarlar',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/ayarlar'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(snapshotProvider.notifier).refresh(),
        child: PageContainer(
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            children: [
              const StatusBanner(),
              if (waiting) const SkeletonBox(height: 190, radius: 24),
              if (!waiting) const HeroPriceCard(),
              if (waiting) const Padding(padding: EdgeInsets.only(top: 16), child: SkeletonList()),
              if (favs.isNotEmpty && snap != null) ...[
                const SectionTitle('Favorilerim'),
                ResponsiveWrap(children: [
                  for (final p in GoldProduct.values)
                    if (favs.contains(p)) PriceTile(product: p),
                ]),
              ],
              if (snap != null) _MarketSummary(snap: snap),
              if (snap != null && snap.hasData) ...[
                const SectionTitle('Altın ve sarrafiye'),
                ResponsiveWrap(children: [for (final p in goldList) PriceTile(product: p)]),
                const SectionTitle('Döviz ve diğer'),
                ResponsiveWrap(children: [for (final p in otherList) PriceTile(product: p)]),
              ],
              const SizedBox(height: 24),
              const Text(S.disclaimer, style: TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Bugünün Piyasası": yalnızca gerçek verilerden hesaplanan özet.
/// Yeterli veri yoksa bölüm hiç gösterilmez.
class _MarketSummary extends StatelessWidget {
  const _MarketSummary({required this.snap});
  final PriceSnapshot snap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final live = snap.quotes.values.where((q) =>
        !q.cached &&
        q.changePercent != null &&
        (q.product.group == ProductGroup.gold || q.product.group == ProductGroup.coin));
    final list = live.toList();
    PriceQuote? top;
    PriceQuote? bottom;
    for (final q in list) {
      if (q.changePercent! > 0 && (top == null || q.changePercent! > top.changePercent!)) top = q;
      if (q.changePercent! < 0 && (bottom == null || q.changePercent! < bottom.changePercent!)) bottom = q;
    }
    final ons = snap[GoldProduct.ons];

    final items = <Widget>[
      if (top != null) _SummaryItem('En çok yükselen', top.product.title, Fmt.percent(top.changePercent!), p.up),
      if (bottom != null) _SummaryItem('En çok düşen', bottom.product.title, Fmt.percent(bottom.changePercent!), p.down),
      if (ons != null && !ons.cached && ons.high != null && ons.low != null)
        _SummaryItem('Ons günlük yüksek', Fmt.usd(ons.high!), 'Düşük ${Fmt.usd(ons.low!)}', p.muted),
    ];
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionTitle('Bugünün Piyasası'),
      ResponsiveWrap(children: items),
    ]);
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem(this.label, this.title, this.value, this.color);
  final String label;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Panel(
      child: Semantics(
        label: '$label: $title, $value',
        child: ExcludeSemantics(
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: TextStyle(color: p.muted, fontSize: 12)),
                const SizedBox(height: 4),
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ]),
            ),
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 16, fontWeight: FontWeight.w800, fontFeatures: tabularFigures)),
          ]),
        ),
      ),
    );
  }
}
