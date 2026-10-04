import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/strings.dart';
import '../../domain/entities/gold_product.dart';
import '../widgets/common_widgets.dart';
import '../widgets/price_chart.dart';

class ChartsScreen extends ConsumerStatefulWidget {
  const ChartsScreen({super.key});

  @override
  ConsumerState<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends ConsumerState<ChartsScreen> {
  GoldProduct _product = GoldProduct.gram;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(S.navCharts)),
      body: PageContainer(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            SegmentedButton<GoldProduct>(
              segments: const [
                ButtonSegment(value: GoldProduct.gram, label: Text('Gram Altın')),
                ButtonSegment(value: GoldProduct.ons, label: Text('Ons Altın')),
              ],
              selected: {_product},
              onSelectionChanged: (s) => setState(() => _product = s.first),
            ),
            const SizedBox(height: 16),
            PriceChart(key: ValueKey(_product), product: _product),
            const SizedBox(height: 16),
            const Text(
              'Diğer ürünler (çeyrek, bilezik vb.) için geçmiş fiyat veri kaynağı bulunmuyor; '
              'bu nedenle grafikleri gösterilmiyor.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
