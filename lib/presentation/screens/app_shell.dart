import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/strings.dart';
import '../state/providers.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  static const _items = <(IconData, IconData, String)>[
    (Icons.home_outlined, Icons.home_rounded, S.navHome),
    (Icons.candlestick_chart_outlined, Icons.candlestick_chart, S.navMarkets),
    (Icons.show_chart_outlined, Icons.show_chart_rounded, S.navCharts),
    (Icons.account_balance_wallet_outlined, Icons.account_balance_wallet, S.navPortfolio),
    (Icons.calculate_outlined, Icons.calculate, S.navCalculate),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<String?>(alertToastProvider, (_, msg) {
      if (msg == null) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Alarm: $msg'),
        duration: const Duration(seconds: 8),
      ));
      ref.read(alertToastProvider.notifier).state = null;
    });

    final idx = navigationShell.currentIndex;
    void go(int i) => navigationShell.goBranch(i, initialLocation: i == idx);
    final wide = MediaQuery.of(context).size.width >= 800;

    if (wide) {
      return Scaffold(
        body: Row(children: [
          NavigationRail(
            selectedIndex: idx,
            onDestinationSelected: go,
            labelType: NavigationRailLabelType.all,
            destinations: [
              for (final e in _items)
                NavigationRailDestination(
                    icon: Icon(e.$1), selectedIcon: Icon(e.$2), label: Text(e.$3)),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: navigationShell),
        ]),
      );
    }
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: go,
        destinations: [
          for (final e in _items)
            NavigationDestination(icon: Icon(e.$1), selectedIcon: Icon(e.$2), label: e.$3),
        ],
      ),
    );
  }
}
