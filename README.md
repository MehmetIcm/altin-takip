# Altın Takip

Türkiye'deki kullanıcılar için Flutter ile yazılmış altın takip uygulaması
(Android, iOS, Web, macOS, Windows, Linux). Gerçek veri, anahtarsız kaynaklar.

## Çalıştırma (macOS)
```bash
cd AltinTakip
bash kur_ve_calistir.sh      # platform klasörleri + paketler + analiz + test
flutter run -d macos
```

## Mimari
`UI (presentation) → GoldRepository → QuoteProvider/OnsProvider/FxHistoryProvider → dış API`
- `lib/core` tema, biçimleyiciler, ağ istemcisi, hatalar
- `lib/domain` varlıklar, saf hesaplamalar (makas, kâr/zarar, alarm), sağlayıcı arayüzleri
- `lib/data` sağlayıcılar (Trunçgil, XAUS, Frankfurter), önbellek, repository
- `lib/presentation` Riverpod durumu, ekranlar, widget'lar

Veri kaynakları ve sınırlamalar: `docs/DATA_PROVIDERS.md`

## Durum (v0.1)
Çalışır: ana ekran, piyasalar, grafikler (ons gerçek, gram hesaplanmış), ürün detayı,
favoriler, portföy + kâr/zarar, hesap makinesi, uygulama içi alarmlar, ayarlar,
önbellek ve hata durumları, responsive navigasyon.
Henüz yok: PWA manifest/offline ayarı, OS bildirimleri (kapalıyken alarm), İngilizce,
widget testleri, entegrasyon testi, uygulama ikonu.

## Yayın (GitHub Pages)
`main` dalına her push, `.github/workflows/deploy.yml` ile web sürümünü derleyip yayınlar.
Depo ayarlarında Settings > Pages > Source: "GitHub Actions" seçilmelidir.
