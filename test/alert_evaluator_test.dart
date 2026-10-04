import 'package:altin_takip/domain/calculators/gold_math.dart';
import 'package:altin_takip/domain/entities/gold_product.dart';
import 'package:altin_takip/domain/entities/price_alert.dart';
import 'package:flutter_test/flutter_test.dart';

PriceAlert alert(AlertType t, double th, {double? baseline, bool active = true}) =>
    PriceAlert(
      id: 'a',
      product: GoldProduct.gram,
      type: t,
      threshold: th,
      baseline: baseline,
      active: active,
      createdAt: DateTime.utc(2026),
    );

void main() {
  test('Üstüne çıkınca', () {
    final a = alert(AlertType.above, 7000);
    expect(AlertEvaluator.isTriggered(a, 6999.99), isFalse);
    expect(AlertEvaluator.isTriggered(a, 7000), isTrue);
    expect(AlertEvaluator.isTriggered(a, 7100), isTrue);
  });

  test('Altına düşünce', () {
    final a = alert(AlertType.below, 6000);
    expect(AlertEvaluator.isTriggered(a, 6001), isFalse);
    expect(AlertEvaluator.isTriggered(a, 6000), isTrue);
  });

  test('Yüzde değişince her iki yönde', () {
    final a = alert(AlertType.percentChange, 2, baseline: 6000);
    expect(AlertEvaluator.isTriggered(a, 6100), isFalse);
    expect(AlertEvaluator.isTriggered(a, 6120), isTrue);
    expect(AlertEvaluator.isTriggered(a, 5880), isTrue);
  });

  test('Yüzde alarmı başlangıç fiyatı olmadan tetiklenmez', () {
    expect(AlertEvaluator.isTriggered(alert(AlertType.percentChange, 1), 9999), isFalse);
  });

  test('Pasif alarm tetiklenmez', () {
    expect(AlertEvaluator.isTriggered(alert(AlertType.above, 1, active: false), 100), isFalse);
  });

  test('JSON gidiş-dönüş', () {
    final a = alert(AlertType.percentChange, 2.5, baseline: 6000);
    final b = PriceAlert.fromJson(a.toJson())!;
    expect(b.type, AlertType.percentChange);
    expect(b.threshold, 2.5);
    expect(b.baseline, 6000);
  });
}
