import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/strings.dart';
import '../../core/theme/app_theme.dart';
import '../state/providers.dart';
import '../widgets/common_widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final p = AppPalette.of(context);
    final n = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: PageContainer(
        maxWidth: 700,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            const SectionTitle('Görünüm'),
            Panel(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Tema', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(value: ThemeMode.dark, label: Text('Koyu'), icon: Icon(Icons.dark_mode_outlined)),
                    ButtonSegment(value: ThemeMode.light, label: Text('Açık'), icon: Icon(Icons.light_mode_outlined)),
                    ButtonSegment(value: ThemeMode.system, label: Text('Sistem'), icon: Icon(Icons.brightness_auto_outlined)),
                  ],
                  selected: {s.themeMode},
                  onSelectionChanged: (x) => n.setThemeMode(x.first),
                ),
                const SizedBox(height: 16),
                const Text('Dil', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Türkçe (İngilizce desteği için altyapı hazır, henüz eklenmedi)',
                    style: TextStyle(color: p.muted, fontSize: 13)),
              ]),
            ),
            const SectionTitle('Veri ayarları'),
            Panel(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Yenileme sıklığı', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Wrap(spacing: 8, children: [
                  for (final sec in const [60, 120, 300])
                    ChoiceChip(
                      label: Text(sec < 120 ? '1 dk' : '${sec ~/ 60} dk'),
                      selected: s.refreshSeconds == sec,
                      onSelected: (_) => n.setRefresh(sec),
                    ),
                ]),
                const SizedBox(height: 8),
                Text(
                  'Ücretsiz veri kaynağının aylık istek limiti nedeniyle en sık 1 dakikada bir yenilenir.',
                  style: TextStyle(color: p.muted, fontSize: 12),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(repositoryProvider).clearCache();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(content: Text('Önbellek temizlendi.')));
                    }
                    await ref.read(snapshotProvider.notifier).refresh();
                  },
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: const Text('Önbelleği temizle'),
                ),
              ]),
            ),
            const SectionTitle('Bildirimler'),
            Panel(
              child: Text(
                'Fiyat alarmları şu an uygulama içinde, uygulama açıkken çalışır. '
                'Uygulama kapalıyken gönderilen anlık bildirimler (Android, iOS, Web) '
                'için sunucu altyapısı gerekir; mimari buna hazırdır ancak henüz eklenmedi.',
                style: TextStyle(color: p.muted, fontSize: 13),
              ),
            ),
            const SectionTitle('Gizlilik'),
            Panel(
              child: Text(
                'Portföy, favori ve alarm bilgileriniz yalnızca bu cihazda saklanır; '
                'hiçbir sunucuya gönderilmez. Uygulama hesap veya kişisel veri istemez. '
                'Fiyat verisi için üçüncü taraf servislere istek yapılır; bu servisler IP adresinizi görebilir.',
                style: TextStyle(color: p.muted, fontSize: 13),
              ),
            ),
            const SectionTitle('Hakkında'),
            Panel(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Altın Takip 0.1.0', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  'Veri kaynakları: Trunçgil Finans (Türkiye altın ve döviz fiyatları), '
                  'XAUS (ons altın), Frankfurter/ECB (geçmiş USD/TRY).\n\n'
                  'Gram altın geçmiş grafiği piyasa verisi değil, ons × USD/TRY ile hesaplanmış '
                  'göstergedir. Kaynakların kullanım şartları ve ticari kullanım koşulları '
                  'yayın öncesinde ayrıca doğrulanmalıdır.\n\n${S.disclaimer}',
                  style: TextStyle(color: p.muted, fontSize: 13),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
