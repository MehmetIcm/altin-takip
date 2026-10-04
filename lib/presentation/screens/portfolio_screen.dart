import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../domain/calculators/gold_math.dart';
import '../../domain/entities/gold_product.dart';
import '../../domain/entities/portfolio_item.dart';
import '../state/providers.dart';
import '../widgets/common_widgets.dart';
import '../widgets/status_banner.dart';

class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(portfolioProvider);
    final snap = ref.watch(snapshotProvider).snapshot;
    final p = AppPalette.of(context);

    final rows = <(PortfolioItem, Valuation?)>[];
    for (final it in items) {
      final q = snap?[it.product];
      rows.add((it, q == null ? null : PortfolioMath.valueItem(it, q)));
    }
    final valued = [for (final r in rows) if (r.$2 != null) r.$2!];
    final totals = valued.isEmpty ? null : PortfolioMath.total(valued);
    final missing = rows.length - valued.length;

    return Scaffold(
      appBar: AppBar(title: const Text(S.navPortfolio)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Altın Ekle'),
      ),
      body: PageContainer(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
          children: [
            const StatusBanner(),
            if (items.isEmpty)
              const Panel(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('Portföyünüz boş. Sahip olduğunuz altınları ekleyin.')),
                ),
              )
            else ...[
              if (totals != null) _Summary(totals: totals),
              if (missing > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('$missing kalem için güncel fiyat olmadığından toplama dahil edilmedi.',
                      style: TextStyle(color: p.down, fontSize: 12)),
                ),
              if (valued.length > 1) _Distribution(rows: rows),
              const SectionTitle('Varlıklarım'),
              for (final r in rows) _ItemTile(item: r.$1, valuation: r.$2),
              const SizedBox(height: 12),
              Text(
                'Değerleme, ALIŞ fiyatı üzerinden yapılır (bozdurulursa elde edilecek yaklaşık tutar). '
                'Günlük değişim, sağlayıcının günlük yüzdesinden yaklaşık hesaplanır. '
                'Portföy bilgileri yalnızca bu cihazda saklanır.',
                style: TextStyle(color: p.muted, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _AddForm(),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.totals});
  final PortfolioTotals totals;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    Color? pc(double? v) => v == null ? null : (v > 0 ? p.up : (v < 0 ? p.down : null));
    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Toplam değer', style: TextStyle(color: p.muted, fontSize: 12)),
        Text(Fmt.tl(totals.value),
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: p.gold, fontFeatures: tabularFigures)),
        const SizedBox(height: 14),
        Wrap(spacing: 32, runSpacing: 14, children: [
          if (totals.dailyChange != null)
            StatItem('Günlük değişim (yakl.)', Fmt.signedTl(totals.dailyChange!), color: pc(totals.dailyChange)),
          if (totals.pnl != null) StatItem('Kâr / Zarar', Fmt.signedTl(totals.pnl!), color: pc(totals.pnl)),
          if (totals.pnlPercent != null)
            StatItem('Kâr / Zarar %', Fmt.percent(totals.pnlPercent!), color: pc(totals.pnlPercent)),
        ]),
      ]),
    );
  }
}

class _Distribution extends StatelessWidget {
  const _Distribution({required this.rows});
  final List<(PortfolioItem, Valuation?)> rows;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final byProduct = <GoldProduct, double>{};
    for (final r in rows) {
      if (r.$2 != null) byProduct[r.$1.product] = (byProduct[r.$1.product] ?? 0) + r.$2!.value;
    }
    final total = byProduct.values.fold<double>(0, (a, b) => a + b);
    if (total <= 0) return const SizedBox.shrink();
    final entries = byProduct.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final shades = [1.0, 0.75, 0.55, 0.4, 0.28, 0.2];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionTitle('Ürün dağılımı'),
      Panel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Row(children: [
                for (var i = 0; i < entries.length; i++)
                  Expanded(
                    flex: (entries[i].value / total * 1000).round().clamp(1, 1000),
                    child: Container(color: withOpacityValue(p.gold, shades[i % shades.length])),
                  ),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < entries.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(
                    color: withOpacityValue(p.gold, shades[i % shades.length]), shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(child: Text(entries[i].key.title)),
                Text('%${Fmt.number(entries[i].value / total * 100)}',
                    style: const TextStyle(fontFeatures: tabularFigures)),
              ]),
            ),
        ]),
      ),
    ]);
  }
}

class _ItemTile extends ConsumerWidget {
  const _ItemTile({required this.item, required this.valuation});
  final PortfolioItem item;
  final Valuation? valuation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = AppPalette.of(context);
    final v = valuation;
    final pnl = v?.pnl;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey(item.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(color: withOpacityValue(p.down, 0.3), borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.delete_outline),
        ),
        onDismissed: (_) => ref.read(portfolioProvider.notifier).remove(item.id),
        child: Panel(
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.product.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 2),
                Text(
                  '${Fmt.amount(item.amount)} ${item.product.unitLabel}'
                  '${item.buyPrice != null ? ' · alış ${Fmt.tl(item.buyPrice!)}' : ''}',
                  style: TextStyle(color: p.muted, fontSize: 13),
                ),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(v == null ? 'Veri yok' : Fmt.tl(v.value),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, fontFeatures: tabularFigures)),
              if (pnl != null)
                Text('${Fmt.signedTl(pnl)} (${Fmt.percent(v!.pnlPercent ?? 0)})',
                    style: TextStyle(color: pnl >= 0 ? p.up : p.down, fontSize: 12)),
            ]),
            IconButton(
              tooltip: 'Sil',
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => ref.read(portfolioProvider.notifier).remove(item.id),
            ),
          ]),
        ),
      ),
    );
  }
}

class _AddForm extends ConsumerStatefulWidget {
  const _AddForm();

  @override
  ConsumerState<_AddForm> createState() => _AddFormState();
}

class _AddFormState extends ConsumerState<_AddForm> {
  GoldProduct _product = GoldProduct.gram;
  final _amount = TextEditingController();
  final _price = TextEditingController();
  String? _amountError;
  String? _priceError;

  @override
  void dispose() {
    _amount.dispose();
    _price.dispose();
    super.dispose();
  }

  void _save() {
    final a = Fmt.parseNumber(_amount.text);
    final priceText = _price.text.trim();
    final bp = priceText.isEmpty ? null : Fmt.parseNumber(priceText);
    setState(() {
      _amountError = (a == null || a <= 0 || a > 1e7) ? 'Geçerli bir miktar girin.' : null;
      _priceError = (priceText.isNotEmpty && (bp == null || bp <= 0 || bp > 1e9))
          ? 'Geçerli bir fiyat girin.'
          : null;
    });
    if (_amountError != null || _priceError != null) return;
    ref.read(portfolioProvider.notifier).add(_product, a!, bp);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final holdables = GoldProduct.values.where((e) => e.isHoldable).toList();
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Altın ekle', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          DropdownButtonFormField<GoldProduct>(
            value: _product,
            decoration: const InputDecoration(labelText: 'Ürün'),
            items: [for (final p in holdables) DropdownMenuItem(value: p, child: Text(p.title))],
            onChanged: (v) => setState(() => _product = v ?? _product),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: 'Miktar (${_product.unitLabel})', errorText: _amountError),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _price,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Alış fiyatı (₺ / ${_product.unitLabel}) - isteğe bağlı',
              helperText: 'Kâr/zarar hesabı için. Örn: 5.900',
              errorText: _priceError,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: _save, child: const Text('Kaydet'))),
        ]),
      ),
    );
  }
}
