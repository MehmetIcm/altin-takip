import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/json_client.dart';
import '../../core/utils/formatters.dart';
import '../../data/cache/snapshot_cache.dart';
import '../../data/providers/frankfurter_provider.dart';
import '../../data/providers/truncgil_provider.dart';
import '../../data/providers/xaus_provider.dart';
import '../../data/repositories/gold_repository.dart';
import '../../domain/calculators/gold_math.dart';
import '../../domain/entities/chart_models.dart';
import '../../domain/entities/gold_product.dart';
import '../../domain/entities/portfolio_item.dart';
import '../../domain/entities/price_alert.dart';
import '../../domain/entities/price_quote.dart';
import '../../domain/entities/price_snapshot.dart';

final sharedPrefsProvider = Provider<SharedPreferences>(
    (ref) => throw UnimplementedError('main() içinde override edilmeli'));

/// Veri kaynakları burada bağlanır. Kaynak değiştirmek için yalnızca bu
/// listeyi düzenlemek yeterlidir (yeni bir QuoteProvider eklenebilir).
final repositoryProvider = Provider<GoldRepository>((ref) {
  final client = JsonClient();
  return GoldRepository(
    quoteProviders: [TruncgilProvider(client: client)],
    ons: XausProvider(client: client),
    fx: FrankfurterProvider(client: client),
    cache: SnapshotCache(ref.watch(sharedPrefsProvider)),
  );
});

// ---------------------------------------------------------------- Ayarlar

class AppSettings {
  const AppSettings({this.themeMode = ThemeMode.dark, this.refreshSeconds = 60});
  final ThemeMode themeMode;
  final int refreshSeconds;
}

class SettingsNotifier extends Notifier<AppSettings> {
  static const _kTheme = 'settings_theme';
  static const _kRefresh = 'settings_refresh';

  @override
  AppSettings build() {
    final prefs = ref.read(sharedPrefsProvider);
    final theme = ThemeMode.values.asNameMap()[prefs.getString(_kTheme)] ?? ThemeMode.dark;
    final refresh = prefs.getInt(_kRefresh) ?? 60;
    return AppSettings(
        themeMode: theme, refreshSeconds: refresh < 30 ? 60 : refresh);
  }

  void setThemeMode(ThemeMode m) {
    state = AppSettings(themeMode: m, refreshSeconds: state.refreshSeconds);
    ref.read(sharedPrefsProvider).setString(_kTheme, m.name);
  }

  void setRefresh(int seconds) {
    state = AppSettings(themeMode: state.themeMode, refreshSeconds: seconds);
    ref.read(sharedPrefsProvider).setInt(_kRefresh, seconds);
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

// ------------------------------------------------------------ Canlı fiyatlar

class SnapshotState {
  const SnapshotState({this.snapshot, this.loading = false});
  final PriceSnapshot? snapshot;
  final bool loading;
}

class SnapshotController extends Notifier<SnapshotState> {
  Timer? _timer;
  bool _busy = false;

  @override
  SnapshotState build() {
    ref.onDispose(() => _timer?.cancel());
    ref.listen<int>(settingsProvider.select((s) => s.refreshSeconds),
        (_, __) => _schedule());
    _schedule();
    Future.microtask(refresh);
    // Açılışta son başarılı veri hemen gösterilir; "önbellek" olarak işaretlidir.
    final cached = ref.read(repositoryProvider).readCached();
    return SnapshotState(snapshot: cached, loading: true);
  }

  void _schedule() {
    _timer?.cancel();
    final secs = ref.read(settingsProvider).refreshSeconds;
    _timer = Timer.periodic(Duration(seconds: secs), (_) => refresh());
  }

  Future<void> refresh() async {
    if (_busy) return;
    _busy = true;
    state = SnapshotState(snapshot: state.snapshot, loading: true);
    try {
      final snap = await ref.read(repositoryProvider).loadSnapshot();
      state = SnapshotState(snapshot: snap);
      ref.read(alertsProvider.notifier).evaluate(snap);
    } catch (_) {
      state = SnapshotState(snapshot: state.snapshot);
    } finally {
      _busy = false;
    }
  }
}

final snapshotProvider =
    NotifierProvider<SnapshotController, SnapshotState>(SnapshotController.new);

final quoteProvider = Provider.family<PriceQuote?, GoldProduct>(
    (ref, p) => ref.watch(snapshotProvider.select((s) => s.snapshot?.quotes[p])));

// ------------------------------------------------------------------ Grafik

final chartProvider = FutureProvider.autoDispose
    .family<ChartSeries, (GoldProduct, ChartRange)>((ref, req) {
  final usd = ref.read(snapshotProvider).snapshot?[GoldProduct.usdTry];
  return ref
      .read(repositoryProvider)
      .series(req.$1, req.$2, usdTryNow: usd?.mid);
});

final onsHistoryProvider = FutureProvider.autoDispose<OnsHistory>(
    (ref) => ref.read(repositoryProvider).onsHistory());

// ---------------------------------------------------------------- Favoriler

class FavoritesNotifier extends Notifier<Set<GoldProduct>> {
  static const _k = 'favorites_v1';

  @override
  Set<GoldProduct> build() {
    final raw = ref.read(sharedPrefsProvider).getStringList(_k) ?? const [];
    return {
      for (final n in raw)
        if (GoldProduct.fromName(n) != null) GoldProduct.fromName(n)!
    };
  }

  void toggle(GoldProduct p) {
    final next = <GoldProduct>{...state};
    if (!next.add(p)) next.remove(p);
    state = next;
    ref.read(sharedPrefsProvider).setStringList(_k, next.map((e) => e.name).toList());
  }
}

final favoritesProvider =
    NotifierProvider<FavoritesNotifier, Set<GoldProduct>>(FavoritesNotifier.new);

// ----------------------------------------------------------------- Portföy

class PortfolioNotifier extends Notifier<List<PortfolioItem>> {
  static const _k = 'portfolio_v1';

  @override
  List<PortfolioItem> build() {
    final raw = ref.read(sharedPrefsProvider).getString(_k);
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw) as List;
      return [
        for (final j in list)
          if (PortfolioItem.fromJson(j) != null) PortfolioItem.fromJson(j)!
      ];
    } catch (_) {
      return const [];
    }
  }

  void add(GoldProduct product, double amount, double? buyPrice) {
    final item = PortfolioItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      product: product,
      amount: amount,
      buyPrice: buyPrice,
      addedAt: DateTime.now().toUtc(),
    );
    state = [...state, item];
    _save();
  }

  void remove(String id) {
    state = state.where((e) => e.id != id).toList();
    _save();
  }

  void _save() => ref
      .read(sharedPrefsProvider)
      .setString(_k, jsonEncode([for (final e in state) e.toJson()]));
}

final portfolioProvider =
    NotifierProvider<PortfolioNotifier, List<PortfolioItem>>(PortfolioNotifier.new);

// ------------------------------------------------------------------ Alarmlar

/// Tetiklenen alarm mesajı; kabuk (shell) bunu SnackBar olarak gösterir.
final alertToastProvider = StateProvider<String?>((ref) => null);

class AlertsNotifier extends Notifier<List<PriceAlert>> {
  static const _k = 'alerts_v1';

  @override
  List<PriceAlert> build() {
    final raw = ref.read(sharedPrefsProvider).getString(_k);
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw) as List;
      return [
        for (final j in list)
          if (PriceAlert.fromJson(j) != null) PriceAlert.fromJson(j)!
      ];
    } catch (_) {
      return const [];
    }
  }

  void add(PriceAlert a) {
    state = [...state, a];
    _save();
  }

  void remove(String id) {
    state = state.where((e) => e.id != id).toList();
    _save();
  }

  /// Yalnızca bu turda canlı alınmış fiyatlarla değerlendirir; önbellek ve
  /// "eski" işaretli veriyle alarm tetiklenmez.
  void evaluate(PriceSnapshot snap) {
    if (snap.status == DataStatus.cached || snap.status == DataStatus.unavailable) {
      return;
    }
    final next = [...state];
    final messages = <String>[];
    for (var i = 0; i < next.length; i++) {
      final a = next[i];
      if (!a.active) continue;
      final q = snap[a.product];
      final price = q?.reference;
      if (q == null || price == null || q.cached || q.stale) continue;
      if (AlertEvaluator.isTriggered(a, price)) {
        next[i] = a.copyWith(
            active: false, triggeredAt: DateTime.now().toUtc(), triggeredPrice: price);
        messages.add('${a.product.title}: ${describe(a)} - şu an ${Fmt.price(a.product, price)}');
      }
    }
    if (messages.isEmpty) return;
    state = next;
    _save();
    ref.read(alertToastProvider.notifier).state = messages.join('\n');
  }

  static String describe(PriceAlert a) {
    switch (a.type) {
      case AlertType.above:
        return '${Fmt.price(a.product, a.threshold)} üzerine çıktı';
      case AlertType.below:
        return '${Fmt.price(a.product, a.threshold)} altına düştü';
      case AlertType.percentChange:
        return '%${Fmt.number(a.threshold)} değişti';
    }
  }

  void _save() => ref
      .read(sharedPrefsProvider)
      .setString(_k, jsonEncode([for (final e in state) e.toJson()]));
}

final alertsProvider =
    NotifierProvider<AlertsNotifier, List<PriceAlert>>(AlertsNotifier.new);
