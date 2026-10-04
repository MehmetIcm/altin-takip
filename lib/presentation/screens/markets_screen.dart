import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/strings.dart';
import '../../domain/entities/gold_product.dart';
import '../state/providers.dart';
import '../widgets/common_widgets.dart';
import '../widgets/price_widgets.dart';
import '../widgets/status_banner.dart';

class MarketsScreen extends ConsumerStatefulWidget {
  const MarketsScreen({super.key});

  @override
  ConsumerState<MarketsScreen> createState() => _MarketsScreenState();
}

class _MarketsScreenState extends ConsumerState<MarketsScreen> {
  ProductGroup? _filter;

  static const _labels = {
    null: 'Tümü',
    ProductGroup.gold: 'Altın',
    ProductGroup.coin: 'Sarrafiye',
    ProductGroup.metal: 'Gümüş',
    ProductGroup.fx: 'Döviz',
  };

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(snapshotProvider);
    final waiting = state.snapshot == null && state.loading;
    final products = [
      for (final p in GoldProduct.values)
        if (_filter == null || p.group == _filter) p
    ];
    return Scaffold(
      appBar: AppBar(title: const Text(S.navMarkets)),
      body: RefreshIndicator(
        onRefresh: () => ref.read(snapshotProvider.notifier).refresh(),
        child: PageContainer(
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            children: [
              const StatusBanner(),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  for (final e in _labels.entries)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(e.value),
                        selected: _filter == e.key,
                        onSelected: (_) => setState(() => _filter = e.key),
                      ),
                    ),
                ]),
              ),
              const SizedBox(height: 12),
              if (waiting)
                const SkeletonList(count: 8)
              else
                ResponsiveWrap(children: [
                  for (final p in products) PriceTile(product: p, showSpread: true),
                ]),
            ],
          ),
        ),
      ),
    );
  }
}
