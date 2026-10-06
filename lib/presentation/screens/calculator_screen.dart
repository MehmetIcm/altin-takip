import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../domain/calculators/gold_math.dart';
import '../../domain/entities/gold_product.dart';
import '../state/providers.dart';
import '../widgets/common_widgets.dart';
import '../widgets/status_banner.dart';

enum _Mode { goldToTl, tlToGold, listing }

class CalculatorScreen extends ConsumerStatefulWidget {
  const CalculatorScreen({super.key, this.initialProduct});
  final GoldProduct? initialProduct;

  @override
  ConsumerState<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends ConsumerState<CalculatorScreen> {
  late GoldProduct _product =
      (widget.initialProduct?.isHoldable ?? false) ? widget.initialProduct! : GoldProduct.gram;
  _Mode _mode = _Mode.goldToTl;
  final _input = TextEditingController(text: '10');
  final _listing = TextEditingController();

  static const _quick = [5, 10, 20, 25, 50, 100];

  @override
  void dispose() {
    _input.dispose();
    _listing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final isListing = _mode == _Mode.listing;
    final product = isListing ? GoldProduct.bilezik22 : _product;
    final q = ref.watch(quoteProvider(product));
    final parsed = Fmt.parseNumber(_input.text);
    final v = (parsed != null && parsed > 0) ? parsed : null;
    final holdables = GoldProduct.values.where((e) => e.isHoldable).toList();
    final unit = product.unitLabel;

    final rows = <Widget>[];
    if (q != null && v != null && !isListing) {
      if (_mode == _Mode.goldToTl) {
        rows.add(_Result('Altını bozdurursan (alış fiyatı)', GoldCalc.amountToTl(v, q.buy), p));
        rows.add(_Result('Altını satın alırsan (satış fiyatı)', GoldCalc.amountToTl(v, q.sell), p));
      } else {
        rows.add(_Result('Bu tutarla alabileceğin (satış fiyatı)', GoldCalc.tlToAmount(v, q.sell), p, unit: unit));
        rows.add(_Result('Bu tutar için bozdurman gereken (alış fiyatı)', GoldCalc.tlToAmount(v, q.buy), p, unit: unit));
      }
    }

    final listingPrice = Fmt.parseNumber(_listing.text);
    final check = (isListing && q != null)
        ? BraceletMath.compare(
            listingPrice: listingPrice ?? 0, grams: v ?? 0, goldPerGram: q.sell)
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text(S.navCalculate)),
      body: PageContainer(
        maxWidth: 700,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            const StatusBanner(),
            SegmentedButton<_Mode>(
              segments: const [
                ButtonSegment(value: _Mode.goldToTl, label: Text('Altın → TL')),
                ButtonSegment(value: _Mode.tlToGold, label: Text('TL → Altın')),
                ButtonSegment(value: _Mode.listing, label: Text('İlan Kontrolü')),
              ],
              selected: {_mode},
              onSelectionChanged: (s) => setState(() => _mode = s.first),
            ),
            const SizedBox(height: 16),
            if (!isListing) ...[
              DropdownButtonFormField<GoldProduct>(
                value: _product,
                decoration: const InputDecoration(labelText: 'Ürün'),
                items: [for (final e in holdables) DropdownMenuItem(value: e, child: Text(e.title))],
                onChanged: (x) => setState(() => _product = x ?? _product),
              ),
              const SizedBox(height: 12),
            ] else ...[
              Panel(
                child: Text(
                  'Bir alışveriş sitesinde veya kuyumcuda gördüğünüz 22 ayar bilezik ilanının, '
                  'güncel altın değerinden ne kadar farklı olduğunu hesaplar. Fark; işçilik, '
                  'kâr payı ve vergileri içerir. Uygulama ilan aramaz; fiyatı siz girersiniz.',
                  style: TextStyle(color: p.muted, fontSize: 13),
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _input,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: _mode == _Mode.tlToGold ? 'Tutar (₺)' : 'Miktar ($unit)',
              ),
            ),
            if (_mode != _Mode.tlToGold && product.unit == ProductUnit.gram) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final g in _quick)
                  ActionChip(
                    label: Text('$g gram'),
                    onPressed: () => setState(() => _input.text = '$g'),
                  ),
              ]),
            ],
            if (isListing) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _listing,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(labelText: 'İlan fiyatı (₺)', helperText: 'Örn: 72.500'),
              ),
            ],
            const SizedBox(height: 20),
            if (q == null)
              const Panel(child: Text('Hesaplama için güncel fiyat verisi yok.'))
            else if (v == null)
              const Panel(child: Text('Geçerli bir sayı girin.'))
            else if (isListing)
              ..._listingResult(check, q.sell, p)
            else ...[
              ...rows,
              const SizedBox(height: 8),
              Text(
                'Birim fiyatlar: alış ${Fmt.tl(q.buy ?? 0)} · satış ${Fmt.tl(q.sell ?? 0)} / $unit. '
                'Alış ve satış fiyatı farklıdır; alırken satış, bozdururken alış fiyatı geçerlidir.',
                style: TextStyle(color: p.muted, fontSize: 12),
              ),
              if (product == GoldProduct.bilezik22)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('Bilezik işçiliği hesaba dahil değildir (veri kaynağında yok).',
                      style: TextStyle(color: p.gold, fontSize: 12)),
                ),
            ],
            if (q != null && v != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Son güncelleme: ${Fmt.time(q.asOf)} · ${q.source}${q.cached ? ' · önbellek' : ''}',
                    style: TextStyle(color: q.cached ? p.down : p.muted, fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _listingResult(ListingCheck? c, double? goldPerGram, AppPalette p) {
    if (c == null) {
      return const [Panel(child: Text('İlan fiyatını girin.'))];
    }
    final cheaper = c.premium < 0;
    return [
      _Result('Güncel altın değeri (satış fiyatı üzerinden)', c.goldValue, p),
      _Result(
        cheaper ? 'İlan, altın değerinin altında' : 'İlan fiyatı - altın değeri (işçilik, kâr, vergi)',
        c.premium,
        p,
        extra: Fmt.percent(c.premiumPercent),
      ),
      _Result('İlanın gram başına fiyatı', c.pricePerGram, p,
          extra: goldPerGram == null ? null : 'Altın: ${Fmt.tl(goldPerGram)}/gr'),
      Text(
        cheaper
            ? 'İlan altın değerinin altında görünüyor. Ayar, gram ve satıcı bilgisini mutlaka doğrulayın.'
            : 'Fark, bilezik işçiliği ve satıcı payıdır. Farklı ilanları bu değere göre kıyaslayabilirsiniz.',
        style: TextStyle(color: p.muted, fontSize: 12),
      ),
    ];
  }
}

class _Result extends StatelessWidget {
  const _Result(this.label, this.value, this.p, {this.unit, this.extra});
  final String label;
  final double? value;
  final AppPalette p;
  final String? unit;
  final String? extra;

  @override
  Widget build(BuildContext context) {
    final text = value == null
        ? '—'
        : (unit == null
            ? (value! < 0 ? Fmt.signedTl(value!) : Fmt.tl(value!))
            : '${Fmt.amount(double.parse(value!.toStringAsFixed(4)))} $unit');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Panel(
        child: Semantics(
          label: '$label: $text${extra != null ? ', $extra' : ''}',
          child: ExcludeSemantics(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: TextStyle(color: p.muted, fontSize: 13)),
              const SizedBox(height: 4),
              Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                Text(text,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: p.gold, fontFeatures: tabularFigures)),
                if (extra != null) ...[
                  const SizedBox(width: 10),
                  Text(extra!, style: TextStyle(color: p.muted, fontSize: 14)),
                ],
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}
