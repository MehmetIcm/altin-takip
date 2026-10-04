import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/gold_product.dart';
import '../../domain/entities/price_quote.dart';
import '../state/providers.dart';

/// Günlük değişim yüzdesi etiketi (yeşil/kırmızı, işaretli).
class ChangeChip extends StatelessWidget {
  const ChangeChip(this.percent, {super.key});
  final double? percent;

  @override
  Widget build(BuildContext context) {
    final v = percent;
    if (v == null) return const SizedBox.shrink();
    final p = AppPalette.of(context);
    final color = v > 0 ? p.up : (v < 0 ? p.down : p.muted);
    final icon = v > 0 ? Icons.arrow_drop_up : (v < 0 ? Icons.arrow_drop_down : Icons.remove);
    return Semantics(
      label: 'Günlük değişim ${Fmt.percent(v)}',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.fromLTRB(2, 2, 8, 2),
          decoration: BoxDecoration(
            color: withOpacityValue(color, 0.14),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 20, color: color),
            Text(Fmt.percent(v),
                style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFeatures: tabularFigures)),
          ]),
        ),
      ),
    );
  }
}

/// Değer değiştiğinde kısa süre yeşil/kırmızı yanıp sönen fiyat metni.
class FlashingPrice extends StatefulWidget {
  const FlashingPrice({super.key, required this.value, required this.text, this.style});
  final double value;
  final String text;
  final TextStyle? style;

  @override
  State<FlashingPrice> createState() => _FlashingPriceState();
}

class _FlashingPriceState extends State<FlashingPrice> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900), value: 1);
  Color _flash = Colors.transparent;

  @override
  void didUpdateWidget(FlashingPrice old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      final p = AppPalette.of(context);
      _flash = widget.value > old.value ? p.up : p.down;
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.style?.color ?? AppPalette.of(context).text;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Text(
        widget.text,
        style: (widget.style ?? const TextStyle())
            .copyWith(color: Color.lerp(_flash, base, Curves.easeOut.transform(_c.value))),
      ),
    );
  }
}

String quoteStatusText(PriceQuote q) {
  final parts = <String>['Son güncelleme: ${Fmt.time(q.asOf)}', q.source];
  if (q.cached) parts.add('önbellek');
  if (q.stale) parts.add('kaynakta eski veri');
  return parts.join(' · ');
}

class FavoriteButton extends ConsumerWidget {
  const FavoriteButton(this.product, {super.key});
  final GoldProduct product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fav = ref.watch(favoritesProvider.select((f) => f.contains(product)));
    final p = AppPalette.of(context);
    return IconButton(
      tooltip: fav ? 'Favorilerden çıkar' : 'Favorilere ekle',
      onPressed: () => ref.read(favoritesProvider.notifier).toggle(product),
      icon: Icon(fav ? Icons.star_rounded : Icons.star_border_rounded,
          color: fav ? p.gold : p.muted),
    );
  }
}

/// Liste satırı: ürün adı, alış, satış ve değişim.
class PriceTile extends ConsumerWidget {
  const PriceTile({super.key, required this.product, this.showSpread = false});
  final GoldProduct product;
  final bool showSpread;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final q = ref.watch(quoteProvider(product));
    final p = AppPalette.of(context);
    final main = q?.reference;

    String sub;
    if (q == null || main == null) {
      sub = 'Veri sağlayıcıda şu an yok';
    } else if (q.buy != null && q.sell != null) {
      sub = 'Alış ${Fmt.price(product, q.buy!)}';
      if (showSpread && q.spread != null) sub += ' · Makas ${Fmt.price(product, q.spread!)}';
    } else {
      sub = 'Spot · USD/ons';
    }
    if (q != null && q.cached) sub += ' · önbellek ${Fmt.time(q.asOf)}';

    return Material(
      color: p.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), side: BorderSide(color: p.line)),
      child: InkWell(
        onTap: () => context.push('/urun/${product.name}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(product.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(sub, style: TextStyle(color: p.muted, fontSize: 13)),
              ]),
            ),
            if (q != null && main != null)
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Semantics(
                  label: '${product.title} ${q.sell != null ? 'satış' : 'fiyat'} ${Fmt.price(product, main)}',
                  child: ExcludeSemantics(
                    child: FlashingPrice(
                      value: main,
                      text: Fmt.price(product, main),
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: p.text,
                          fontFeatures: tabularFigures),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                ChangeChip(q.changePercent),
              ]),
            FavoriteButton(product),
          ]),
        ),
      ),
    );
  }
}

/// Ana ekranın öne çıkan kartı: Gram Altın.
class HeroPriceCard extends ConsumerWidget {
  const HeroPriceCard({super.key, this.product = GoldProduct.gram});
  final GoldProduct product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final q = ref.watch(quoteProvider(product));
    final p = AppPalette.of(context);
    if (q == null || q.sell == null || q.buy == null) return const SizedBox.shrink();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => context.push('/urun/${product.name}'),
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [p.navy, p.surface],
            ),
            border: Border.all(color: withOpacityValue(p.gold, 0.45)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.workspace_premium_rounded, color: p.gold, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(product.title,
                    style: TextStyle(color: p.gold, fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              ChangeChip(q.changePercent),
              FavoriteButton(product),
            ]),
            const SizedBox(height: 8),
            Text('Satış', style: TextStyle(color: p.muted, fontSize: 12)),
            Semantics(
              label: 'Satış fiyatı ${Fmt.tl(q.sell!)}',
              child: ExcludeSemantics(
                child: FlashingPrice(
                  value: q.sell!,
                  text: Fmt.tl(q.sell!),
                  style: TextStyle(
                      color: p.text,
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      fontFeatures: tabularFigures),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: StatLine('Alış', Fmt.tl(q.buy!))),
              Expanded(child: StatLine('Makas', Fmt.tl(q.spread!))),
              if (q.spreadPercent != null)
                Expanded(child: StatLine('Makas %', Fmt.percent(q.spreadPercent!).replaceFirst('+', ''))),
            ]),
            const SizedBox(height: 14),
            Text(quoteStatusText(q),
                style: TextStyle(
                    color: q.cached || q.stale ? p.down : p.muted, fontSize: 12)),
          ]),
        ),
      ),
    );
  }
}

class StatLine extends StatelessWidget {
  const StatLine(this.label, this.value, {super.key});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Semantics(
      label: '$label $value',
      child: ExcludeSemantics(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: p.muted, fontSize: 12)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600, fontFeatures: tabularFigures)),
        ]),
      ),
    );
  }
}
