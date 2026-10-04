import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/gold_product.dart';
import '../../domain/entities/price_alert.dart';
import '../state/providers.dart';
import '../widgets/common_widgets.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(alertsProvider);
    final p = AppPalette.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Fiyat Alarmları')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAlertSheet(context),
        icon: const Icon(Icons.add_alert_outlined),
        label: const Text('Alarm Ekle'),
      ),
      body: PageContainer(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            Panel(
              child: Text(
                'Alarmlar yalnızca uygulama açıkken (veya arka planda çalışırken) '
                'güncel fiyatlarla kontrol edilir. Uygulama kapalıyken bildirim gönderilmez.',
                style: TextStyle(color: p.muted, fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),
            if (alerts.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('Henüz alarm yok. "Alarm Ekle" ile başlayın.')),
              ),
            for (final a in alerts)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Panel(
                  child: Row(children: [
                    Icon(a.active ? Icons.notifications_active_outlined : Icons.check_circle_outline,
                        color: a.active ? p.gold : p.up),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(a.product.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(
                          a.type == AlertType.percentChange
                              ? '%${Fmt.number(a.threshold)} değişince (başlangıç ${Fmt.price(a.product, a.baseline ?? 0)})'
                              : '${a.type.label}: ${Fmt.price(a.product, a.threshold)}',
                          style: TextStyle(color: p.muted, fontSize: 13),
                        ),
                        if (a.triggeredAt != null)
                          Text(
                              'Tetiklendi: ${Fmt.dateTime(a.triggeredAt!)}'
                              '${a.triggeredPrice != null ? ' · ${Fmt.price(a.product, a.triggeredPrice!)}' : ''}',
                              style: TextStyle(color: p.up, fontSize: 12)),
                      ]),
                    ),
                    IconButton(
                      tooltip: 'Alarmı sil',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => ref.read(alertsProvider.notifier).remove(a.id),
                    ),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Future<void> showAlertSheet(BuildContext context, {GoldProduct? product}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _AlertForm(initial: product),
  );
}

class _AlertForm extends ConsumerStatefulWidget {
  const _AlertForm({this.initial});
  final GoldProduct? initial;

  @override
  ConsumerState<_AlertForm> createState() => _AlertFormState();
}

class _AlertFormState extends ConsumerState<_AlertForm> {
  late GoldProduct _product = widget.initial ?? GoldProduct.gram;
  AlertType _type = AlertType.above;
  final _value = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  void _save() {
    final v = Fmt.parseNumber(_value.text);
    if (v == null || v <= 0) {
      setState(() => _error = 'Geçerli bir sayı girin.');
      return;
    }
    if (_type == AlertType.percentChange && v > 100) {
      setState(() => _error = 'Yüzde 0 ile 100 arasında olmalı.');
      return;
    }
    if (v > 1e9) {
      setState(() => _error = 'Değer çok büyük.');
      return;
    }
    double? baseline;
    if (_type == AlertType.percentChange) {
      baseline = ref.read(quoteProvider(_product))?.reference;
      if (baseline == null) {
        setState(() => _error = 'Güncel fiyat olmadan yüzde alarmı kurulamaz.');
        return;
      }
    }
    ref.read(alertsProvider.notifier).add(PriceAlert(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          product: _product,
          type: _type,
          threshold: v,
          baseline: baseline,
          createdAt: DateTime.now().toUtc(),
        ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(quoteProvider(_product))?.reference;
    final isPct = _type == AlertType.percentChange;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Yeni alarm', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          DropdownButtonFormField<GoldProduct>(
            value: _product,
            decoration: const InputDecoration(labelText: 'Ürün'),
            items: [
              for (final p in GoldProduct.values)
                DropdownMenuItem(value: p, child: Text(p.title)),
            ],
            onChanged: (v) => setState(() => _product = v ?? _product),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<AlertType>(
            value: _type,
            decoration: const InputDecoration(labelText: 'Koşul'),
            items: [for (final t in AlertType.values) DropdownMenuItem(value: t, child: Text(t.label))],
            onChanged: (v) => setState(() => _type = v ?? _type),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _value,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: isPct ? 'Yüzde (%)' : 'Hedef fiyat',
              helperText: current == null ? null : 'Güncel: ${Fmt.price(_product, current)}',
              errorText: _error,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: _save, child: const Text('Alarmı Kaydet'))),
        ]),
      ),
    );
  }
}
