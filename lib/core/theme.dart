import 'package:flutter/material.dart';

class AppThemePreset {
  const AppThemePreset({
    required this.id,
    required this.name,
    required this.description,
    required this.seedColor,
    required this.scaffoldColor,
  });

  final String id;
  final String name;
  final String description;
  final Color seedColor;
  final Color scaffoldColor;
}

const themePresets = [
  AppThemePreset(
    id: 'fresh',
    name: 'Fresh Green',
    description: '落ち着いた食品アプリらしいグリーン',
    seedColor: Color(0xFF247158),
    scaffoldColor: Color(0xFFFAF9F4),
  ),
  AppThemePreset(
    id: 'market',
    name: 'Market Blue',
    description: '見やすく清潔感のあるブルー',
    seedColor: Color(0xFF2563A8),
    scaffoldColor: Color(0xFFF6F9FC),
  ),
  AppThemePreset(
    id: 'tomato',
    name: 'Tomato Red',
    description: '買い物メモが目に入りやすいレッド',
    seedColor: Color(0xFFC9493A),
    scaffoldColor: Color(0xFFFFF8F5),
  ),
  AppThemePreset(
    id: 'citrus',
    name: 'Citrus Yellow',
    description: '明るく親しみやすいイエロー',
    seedColor: Color(0xFFB7791F),
    scaffoldColor: Color(0xFFFFFBF0),
  ),
  AppThemePreset(
    id: 'mono',
    name: 'Calm Mono',
    description: '情報量が多くても読みやすいニュートラル',
    seedColor: Color(0xFF4B5563),
    scaffoldColor: Color(0xFFF8F8F7),
  ),
];

ThemeData buildAppTheme(AppThemePreset preset, Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: preset.seedColor,
    brightness: brightness,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(20));
  return base.copyWith(
    scaffoldBackgroundColor: dark ? scheme.surface : preset.scaffoldColor,
    textTheme: base.textTheme.copyWith(
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.5),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? scheme.surface : preset.scaffoldColor,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: base.textTheme.titleLarge?.copyWith(
        color: scheme.primary,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: dark ? scheme.surfaceContainerLow : Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      shape: shape,
      clipBehavior: Clip.antiAlias,
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLowest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: dark ? scheme.surface : preset.scaffoldColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: dark ? scheme.surfaceContainer : Colors.white,
      indicatorColor: scheme.primaryContainer,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: shape,
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant.withValues(alpha: 0.5),
      space: 1,
    ),
  );
}
