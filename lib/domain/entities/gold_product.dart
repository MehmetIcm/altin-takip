enum ProductGroup { gold, coin, metal, fx }

enum ProductUnit { gram, piece, ounce, currency }

/// Desteklenen ürünler. Reşat ve Hamit altın bilinçli olarak yoktur:
/// veri sağlayıcı Ata altınla aynı değeri döndürdüğü için ayrı bir fiyat
/// olarak doğrulanamadı.
enum GoldProduct {
  gram('Gram Altın', ProductGroup.gold, ProductUnit.gram),
  has('Has Altın (24 Ayar)', ProductGroup.gold, ProductUnit.gram),
  ceyrek('Çeyrek Altın', ProductGroup.coin, ProductUnit.piece),
  yarim('Yarım Altın', ProductGroup.coin, ProductUnit.piece),
  tam('Tam Altın', ProductGroup.coin, ProductUnit.piece),
  cumhuriyet('Cumhuriyet Altını', ProductGroup.coin, ProductUnit.piece),
  ata('Ata Altın', ProductGroup.coin, ProductUnit.piece),
  ayar14('14 Ayar Altın', ProductGroup.gold, ProductUnit.gram),
  ayar18('18 Ayar Altın', ProductGroup.gold, ProductUnit.gram),
  bilezik22('22 Ayar Bilezik', ProductGroup.gold, ProductUnit.gram),
  ons('Ons Altın', ProductGroup.gold, ProductUnit.ounce),
  gumus('Gümüş', ProductGroup.metal, ProductUnit.gram),
  usdTry('USD/TRY', ProductGroup.fx, ProductUnit.currency),
  eurTry('EUR/TRY', ProductGroup.fx, ProductUnit.currency),
  gbpTry('GBP/TRY', ProductGroup.fx, ProductUnit.currency);

  const GoldProduct(this.title, this.group, this.unit);

  final String title;
  final ProductGroup group;
  final ProductUnit unit;

  String get unitLabel {
    switch (unit) {
      case ProductUnit.gram:
        return 'gram';
      case ProductUnit.piece:
        return 'adet';
      case ProductUnit.ounce:
        return 'ons';
      case ProductUnit.currency:
        return 'birim';
    }
  }

  /// Portföy ve hesap makinesinde kullanılabilen ürünler.
  bool get isHoldable =>
      this != GoldProduct.ons &&
      (group == ProductGroup.gold || group == ProductGroup.coin);

  static GoldProduct? fromName(String? name) =>
      name == null ? null : GoldProduct.values.asNameMap()[name];
}
