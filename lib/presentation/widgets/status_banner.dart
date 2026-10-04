import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/price_snapshot.dart';
import '../state/providers.dart';

/// Veri durumunu kullanıcıya açıkça gösterir: canlı, eski, kısmi veya yok.
class StatusBanner extends ConsumerWidget {
  const StatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(snapshotProvider);
    final snap = state.snapshot;
    final p = AppPalette.of(context);
    final retry = ref.read(snapshotProvider.notifier).refresh;

    if (snap == null) {
      return state.loading
          ? _bar(context, Icons.sync, p.muted, 'Fiyatlar yükleniyor...', null)
          : const SizedBox.shrink();
    }

    switch (snap.status) {
      case DataStatus.unavailable:
        return _bar(context, Icons.cloud_off_rounded, p.down,
            S.updateFailed, retry,
            detail: snap.issues.join('\n'), busy: state.loading);
      case DataStatus.cached:
        if (state.loading) {
          return _bar(context, Icons.sync, p.muted,
              'Güncelleniyor... Gösterilen veri önbellekten (${Fmt.time(snap.fetchedAt)}).', null);
        }
        return _bar(context, Icons.history_rounded, p.down,
            '${S.updateFailed} Son başarılı veri: ${Fmt.time(snap.fetchedAt)} (önbellek)',
            retry,
            detail: snap.issues.join('\n'));
      case DataStatus.partial:
        return _bar(context, Icons.warning_amber_rounded, p.gold,
            'Bazı veriler güncellenemedi; eksik değerler önbellekten gösteriliyor.', retry,
            detail: snap.issues.join('\n'), busy: state.loading);
      case DataStatus.live:
        final asOf = snap.latestAsOf;
        final age = asOf == null ? null : DateTime.now().toUtc().difference(asOf);
        if (age != null && age.inMinutes > 20) {
          return _bar(context, Icons.schedule_rounded, p.gold,
              'Veri sağlayıcının son güncellemesi ${Fmt.age(age)} (${Fmt.time(asOf!)}).', null);
        }
        return _bar(context, Icons.circle, p.up,
            asOf == null ? 'Güncel' : 'Güncel · Son güncelleme: ${Fmt.time(asOf)}', null,
            small: true);
    }
  }

  Widget _bar(BuildContext context, IconData icon, Color color, String text,
      Future<void> Function()? onRetry,
      {String? detail, bool small = false, bool busy = false}) {
    final p = AppPalette.of(context);
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: small ? 8 : 12),
        decoration: BoxDecoration(
          color: withOpacityValue(color, small ? 0.08 : 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: withOpacityValue(color, 0.4)),
        ),
        child: Row(children: [
          Icon(icon, size: small ? 10 : 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(text, style: TextStyle(fontSize: small ? 12 : 13, color: p.text)),
              if (detail != null && detail.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(detail, style: TextStyle(fontSize: 12, color: p.muted)),
                ),
            ]),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: busy ? null : onRetry,
              child: Text(busy ? '...' : S.retry),
            ),
        ]),
      ),
    );
  }
}
