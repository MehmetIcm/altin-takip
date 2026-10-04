import 'gold_product.dart';

enum AlertType {
  above('Üstüne çıkınca'),
  below('Altına düşünce'),
  percentChange('Yüzde değişince');

  const AlertType(this.label);
  final String label;
}

class PriceAlert {
  const PriceAlert({
    required this.id,
    required this.product,
    required this.type,
    required this.threshold,
    required this.createdAt,
    this.baseline,
    this.active = true,
    this.triggeredAt,
    this.triggeredPrice,
  });

  final String id;
  final GoldProduct product;
  final AlertType type;

  /// above/below: hedef fiyat. percentChange: yüzde eşiği.
  final double threshold;

  /// percentChange için alarm kurulduğu andaki fiyat.
  final double? baseline;
  final bool active;
  final DateTime createdAt;
  final DateTime? triggeredAt;
  final double? triggeredPrice;

  PriceAlert copyWith({bool? active, DateTime? triggeredAt, double? triggeredPrice}) =>
      PriceAlert(
        id: id,
        product: product,
        type: type,
        threshold: threshold,
        createdAt: createdAt,
        baseline: baseline,
        active: active ?? this.active,
        triggeredAt: triggeredAt ?? this.triggeredAt,
        triggeredPrice: triggeredPrice ?? this.triggeredPrice,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'product': product.name,
        'type': type.name,
        'threshold': threshold,
        'baseline': baseline,
        'active': active,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'triggeredAt': triggeredAt?.toUtc().toIso8601String(),
        'triggeredPrice': triggeredPrice,
      };

  static PriceAlert? fromJson(dynamic j) {
    if (j is! Map) return null;
    final product = GoldProduct.fromName(j['product'] as String?);
    final type = AlertType.values.asNameMap()['${j['type']}'];
    final th = j['threshold'];
    final created = DateTime.tryParse('${j['createdAt']}');
    if (product == null || type == null || th is! num || created == null) {
      return null;
    }
    double? n(dynamic v) => v is num ? v.toDouble() : null;
    return PriceAlert(
      id: '${j['id']}',
      product: product,
      type: type,
      threshold: th.toDouble(),
      baseline: n(j['baseline']),
      active: j['active'] != false,
      createdAt: created.toUtc(),
      triggeredAt: DateTime.tryParse('${j['triggeredAt']}')?.toUtc(),
      triggeredPrice: n(j['triggeredPrice']),
    );
  }
}
