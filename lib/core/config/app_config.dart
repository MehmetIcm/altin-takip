/// Derleme zamanında verilir:
/// flutter build ... --dart-define=PRIVACY_URL=https://.../gizlilik.html
/// GitHub Actions bunu otomatik doldurur; verilmezse düğme gizlenir.
class AppConfig {
  static const String privacyUrl = String.fromEnvironment('PRIVACY_URL');
  static const String appVersion = '0.2.0';
}
