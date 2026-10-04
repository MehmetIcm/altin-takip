# Veri Kaynakları

Uygulama **API anahtarı, backend veya proxy gerektirmez**. Hiçbir sahte/rastgele
fiyat üretilmez; veri alınamazsa durum kullanıcıya açıkça gösterilir.

| Amaç | Kaynak | Anahtar | Not |
|---|---|---|---|
| TL altın/sarrafiye alış-satış, USD/EUR/GBP, gümüş | Trunçgil Finans `finans.truncgil.com/v4/today.json` | Yok | Ücretsiz plan: ayda 100 bin istek (sağlayıcının duyurusu) |
| Ons altın spot, günlük geçmiş (5 yıl), gün içi | XAUS `xaus.com/api/v1/*` | Yok | Bağımsız küçük proje |
| Geçmiş USD/TRY | Frankfurter (ECB) `api.frankfurter.dev/v1` | Yok | Hafta sonu kur yayımlanmaz, önceki değerle doldurulur |

## Bilinçli sınırlamalar
- **Reşat / Hamit:** Trunçgil bu iki ürün için Ata altınla birebir aynı değeri döndürüyor; ayrı bir fiyat olarak doğrulanamadığı için **gösterilmez**.
- **Ons (TL kaynağında):** Trunçgil'de ons alış/satış 0 geliyor; ons XAUS'tan alınır (tek fiyat, USD).
- **24 Ayar:** "Has Altın (24 Ayar)" olarak gösterilir.
- **22 Ayar Altın:** Sağlayıcı yalnızca "22 Ayar Bilezik" fiyatı verir; işçilik verisi yoktur, uydurulmaz.
- **Günlük en yüksek/düşük:** Yalnızca ons için (XAUS). Diğerleri için kaynakta veri yok, gösterilmez.
- **Gram geçmiş grafiği:** Piyasa verisi değil, `ons × USD/TRY ÷ 31,1035` ile **hesaplanmış** seridir ve arayüzde öyle etiketlenir. Çeyrek, bilezik vb. için geçmiş grafik yoktur.
- **Ons günlük değişimi:** XAUS günlük kapanışına göre hesaplanır.
- Trunçgil `Update_Date` alanı İstanbul saati kabul edilir (doğrulanmadı).

## Yayın öncesi doğrulanması gerekenler
- Trunçgil'in ticari kullanım şartları ve limitin kullanıcı başına mı genel mi olduğu.
- XAUS'un geçmiş verisi Yahoo Finance kaynaklıdır; Yahoo şartları ticari yeniden dağıtıma izin vermeyebilir.
- Frankfurter v1 URL biçimi (`/v1/{başlangıç}..{bitiş}?base=USD&symbols=TRY`) entegrasyon sırasında canlı doğrulanmadı.
- Trunçgil ve XAUS'un tarayıcıdan (CORS) çağrılabilirliği. macOS/mobil/masaüstünde sorun yoktur; web için test edilmelidir.

## Kaynak değiştirmek
`lib/presentation/state/providers.dart` içindeki `repositoryProvider` listesine yeni bir
`QuoteProvider` eklenirse, birincil çökerse otomatik yedek olarak denenir.
