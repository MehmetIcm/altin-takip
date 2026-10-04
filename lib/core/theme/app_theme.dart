import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

Color withOpacityValue(Color c, double o) => c.withAlpha((o * 255).round());

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.bg,
    required this.surface,
    required this.surfaceHigh,
    required this.navy,
    required this.gold,
    required this.onGold,
    required this.text,
    required this.muted,
    required this.up,
    required this.down,
    required this.line,
  });

  final Color bg;
  final Color surface;
  final Color surfaceHigh;
  final Color navy;
  final Color gold;
  final Color onGold;
  final Color text;
  final Color muted;
  final Color up;
  final Color down;
  final Color line;

  /// Siyah, antrasit, koyu lacivert, altın; kontrollü yeşil/kırmızı.
  static const dark = AppPalette(
    bg: Color(0xFF0A0C11),
    surface: Color(0xFF14171F),
    surfaceHigh: Color(0xFF1C212C),
    navy: Color(0xFF111C36),
    gold: Color(0xFFD1A94F),
    onGold: Color(0xFF1A1405),
    text: Color(0xFFF2F0EA),
    muted: Color(0xFF9BA1AF),
    up: Color(0xFF3DB88C),
    down: Color(0xFFE5675F),
    line: Color(0xFF262B38),
  );

  static const light = AppPalette(
    bg: Color(0xFFF6F4EF),
    surface: Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFF0EDE5),
    navy: Color(0xFFE9EDF7),
    gold: Color(0xFF8A6417),
    onGold: Color(0xFFFFFFFF),
    text: Color(0xFF15171D),
    muted: Color(0xFF5E6472),
    up: Color(0xFF16805C),
    down: Color(0xFFC0392F),
    line: Color(0xFFE1DDD2),
  );

  static AppPalette of(BuildContext context) =>
      Theme.of(context).extension<AppPalette>() ?? AppPalette.dark;

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) => this;
}

ThemeData buildTheme(Brightness brightness) {
  final p = brightness == Brightness.dark ? AppPalette.dark : AppPalette.light;
  final base = ThemeData(brightness: brightness, useMaterial3: true);
  final scheme = ColorScheme.fromSeed(seedColor: p.gold, brightness: brightness)
      .copyWith(
    primary: p.gold,
    onPrimary: p.onGold,
    surface: p.surface,
    onSurface: p.text,
    error: p.down,
  );
  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: p.bg,
    extensions: [p],
    textTheme: base.textTheme.apply(bodyColor: p.text, displayColor: p.text),
    appBarTheme: AppBarTheme(
      backgroundColor: p.bg,
      foregroundColor: p.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
          color: p.text, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 0.2),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.surface,
      indicatorColor: withOpacityValue(p.gold, 0.18),
      labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
            fontSize: 12,
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: s.contains(WidgetState.selected) ? p.gold : p.muted,
          )),
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
          color: s.contains(WidgetState.selected) ? p.gold : p.muted)),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: p.surface,
      indicatorColor: withOpacityValue(p.gold, 0.18),
      selectedIconTheme: IconThemeData(color: p.gold),
      unselectedIconTheme: IconThemeData(color: p.muted),
      selectedLabelTextStyle: TextStyle(color: p.gold, fontWeight: FontWeight.w700),
      unselectedLabelTextStyle: TextStyle(color: p.muted),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.surfaceHigh,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.gold, width: 1.5)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.gold,
        foregroundColor: p.onGold,
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      selectedColor: withOpacityValue(p.gold, 0.22),
      side: BorderSide(color: p.line),
      labelStyle: TextStyle(color: p.text),
    ),
    dividerColor: p.line,
    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.surfaceHigh,
      contentTextStyle: TextStyle(color: p.text),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

/// Rakamların hizalı görünmesi için sabit genişlikli rakamlar.
const List<FontFeature> tabularFigures = [FontFeature.tabularFigures()];
