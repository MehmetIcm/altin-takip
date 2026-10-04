import 'gold_product.dart';

class PortfolioItem {
  const PortfolioItem({
    required this.id,
    required this.product,
    required this.amount,
    required this.addedAt,
    this.buyPrice,
  });

  final String id;
  final GoldProduct product;

  /// Gram veya adet (ürüne göre).
  final double amount;

  /// Birim alış fiyatı (TL / gram veya TL / adet). Girilmediyse null.
  final double? buyPrice;
  final DateTime addedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'product': product.name,
        'amount': amount,
        'buyPrice': buyPrice,
        'addedAt': addedAt.toUtc().toIso8601String(),
      };

  static PortfolioItem? fromJson(dynamic j) {
    if (j is! Map) return null;
    final product = GoldProduct.fromName(j['product'] as String?);
    final amount = j['amount'];
    final at = DateTime.tryParse('${j['addedAt']}');
    if (product == null || amount is! num || at == null) return null;
    final bp = j['buyPrice'];
    return PortfolioItem(
      id: '${j['id']}',
      product: product,
      amount: amount.toDouble(),
      buyPrice: bp is num ? bp.toDouble() : null,
      addedAt: at.toUtc(),
    );
  }
}
