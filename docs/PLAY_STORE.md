# Google Play'e yayın rehberi

## Bir kez yapılacaklar
1. **Geliştirici hesabı:** play.google.com/console adresinden Google hesabınla kayıt ol (tek seferlik kayıt ücreti vardır; güncel tutarı ve kimlik doğrulama adımlarını Play Console gösterir).
2. **İmza anahtarı üret** (Mac Terminal). Java yoksa önce: `brew install --cask temurin@17`
   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
   Sorulan şifreleri bir yere **not et**. `upload-keystore.jks` dosyasını ve şifreleri güvenli bir yerde yedekle; GitHub'a **yükleme**.
3. **GitHub Secrets** (Depo > Settings > Secrets and variables > Actions > New repository secret):
   | Ad | Değer |
   |---|---|
   | `ANDROID_KEYSTORE_BASE64` | `base64 -i ~/upload-keystore.jks \| pbcopy` komutunun kopyaladığı metin |
   | `ANDROID_KEYSTORE_PASSWORD` | keystore şifresi |
   | `ANDROID_KEY_ALIAS` | `upload` |
   | `ANDROID_KEY_PASSWORD` | anahtar şifresi |
4. **Derle:** Actions > "Android (APK ve AAB)" > Run workflow. Bitince "altin-takip-android" çıktısını indir; içinde `app-release.aab` (Play için) ve `app-release.apk` (telefona kurmak için) var.
5. Her yeni sürümde `pubspec.yaml` içindeki `version` değerini artır (örn. 0.2.0 → 0.2.1). Derleme numarasını GitHub otomatik artırır.

## Play Console'da uygulama oluşturma
- Yeni uygulama: ad "Altın Takip", dil Türkçe, uygulama (oyun değil), ücretsiz.
- **Mağaza girişi:** `store/store_listing_tr.md` metinlerini, `store/play_icon_512.png` ve `store/feature_graphic_1024x500.png` dosyalarını kullan. En az 2 telefon ekran görüntüsü ekle.
- **Gizlilik politikası URL'si:** `https://KULLANICI-ADIN.github.io/altin-takip/gizlilik.html`
- **Veri güvenliği formu:** Uygulama kişisel veri toplamaz ve paylaşmaz; portföy/favori/alarm yalnızca cihazda kalır. Form sorularını buna göre doldur ve sorular değiştiyse güncel haline göre kontrol et.
- **Finansal özellikler beyanı:** Uygulama bilgi amaçlıdır; alım satım, kredi, ödeme veya hesap sunmaz. Formda bunu belirt.
- **İçerik derecelendirme ve hedef kitle:** 18 yaş ve üzeri öner. Reklam yok.
- **Uygulama imzalama:** Play App Signing'i kabul et (varsayılan).

## Test ve yayın
1. **Kapalı test** > yeni sürüm oluştur > `app-release.aab` dosyasını yükle.
2. **12 test kullanıcısı** ekle (Google Group veya e-posta listesi). Hepsi test bağlantısından katılıp uygulamayı yüklemeli ve **14 gün kesintisiz** kayıtlı kalmalı; kimse çıkmamalı (sayaç sıfırlanır). 12'den fazla kişi (örn. 15-20) eklemek güvenlidir.
3. 14 gün bitince Play Console'da **Üretim erişimi için başvur**, sonra üretim sürümü oluşturup aynı AAB'yi yayınla. Google'ın incelemesi birkaç gün sürebilir.

## Veri kaynakları notu
Trunçgil ve XAUS'un ticari kullanım şartları doğrulanmadı (bkz. DATA_PROVIDERS.md). Uygulamayı ücretsiz ve reklamsız tutmak riski düşürür. Reklam/abonelik eklenecekse önce kaynaklardan yazılı izin alın.
