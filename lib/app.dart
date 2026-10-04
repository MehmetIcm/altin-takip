import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/l10n/strings.dart';
import 'core/theme/app_theme.dart';
import 'domain/entities/gold_product.dart';
import 'presentation/screens/alerts_screen.dart';
import 'presentation/screens/app_shell.dart';
import 'presentation/screens/calculator_screen.dart';
import 'presentation/screens/charts_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/markets_screen.dart';
import 'presentation/screens/portfolio_screen.dart';
import 'presentation/screens/product_detail_screen.dart';
import 'presentation/screens/settings_screen.dart';
import 'presentation/state/providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/piyasalar', builder: (_, __) => const MarketsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/grafikler', builder: (_, __) => const ChartsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/portfoy', builder: (_, __) => const PortfolioScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/hesapla',
              builder: (_, state) => CalculatorScreen(
                key: ValueKey(state.uri.queryParameters['urun']),
                initialProduct: GoldProduct.fromName(state.uri.queryParameters['urun']),
              ),
            ),
          ]),
        ],
      ),
      GoRoute(
        path: '/urun/:key',
        builder: (_, state) => ProductDetailScreen(
          product: GoldProduct.fromName(state.pathParameters['key']) ?? GoldProduct.gram,
        ),
      ),
      GoRoute(path: '/alarmlar', builder: (_, __) => const AlertsScreen()),
      GoRoute(path: '/ayarlar', builder: (_, __) => const SettingsScreen()),
    ],
  );
});

class AltinTakipApp extends ConsumerWidget {
  const AltinTakipApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return MaterialApp.router(
      title: S.appName,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: settings.themeMode,
      routerConfig: ref.watch(routerProvider),
      locale: const Locale('tr', 'TR'),
      supportedLocales: const [Locale('tr', 'TR'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
