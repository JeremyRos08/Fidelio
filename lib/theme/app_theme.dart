import 'package:flutter/material.dart';

class AppTheme {
  static const primary = Color(0xFF5B46E8);
  static const secondary = Color(0xFF8D74F5);
  static const accent = Color(0xFFFFB14A);
  static const danger = Color(0xFFE0526F);
  static const ink = Color(0xFF1C1B2E);
  static const canvas = Color(0xFFF7F7FC);

  static const colorChoices = <AppColorChoice>[
    AppColorChoice(label: 'Violet', color: Color(0xFF5B46E8)),
    AppColorChoice(label: 'Bleu', color: Color(0xFF1565C0)),
    AppColorChoice(label: 'Vert', color: Color(0xFF198754)),
    AppColorChoice(label: 'Turquoise', color: Color(0xFF007F86)),
    AppColorChoice(label: 'Rose', color: Color(0xFFC43F70)),
    AppColorChoice(label: 'Orange', color: Color(0xFFD96424)),
  ];

  static ThemeData light(Color primaryColor) => _theme(
    brightness: Brightness.light,
    scaffold: canvas,
    surface: Colors.white,
    text: ink,
    primaryColor: primaryColor,
  );

  static ThemeData dark(Color primaryColor) => _theme(
    brightness: Brightness.dark,
    scaffold: const Color(0xFF11101C),
    surface: const Color(0xFF1B1928),
    text: const Color(0xFFF5F3FF),
    primaryColor: primaryColor,
  );

  static ThemeData _theme({
    required Brightness brightness,
    required Color scaffold,
    required Color surface,
    required Color text,
    required Color primaryColor,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: brightness,
      primary: primaryColor,
      surface: surface,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffold,
      visualDensity: VisualDensity.standard,
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: text,
          letterSpacing: -1,
        ),
        headlineMedium: TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.w800,
          color: text,
          letterSpacing: -.6,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: text,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: text,
        ),
        bodyLarge: TextStyle(fontSize: 16, height: 1.4, color: text),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.4,
          color: text.withValues(alpha: .72),
        ),
        labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: .48),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 74,
        backgroundColor: surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        indicatorColor: primaryColor.withValues(alpha: .14),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? primaryColor
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: .45),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: scaffold,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: text,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: .55),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: .55),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryColor, width: 1.6),
        ),
      ),
      searchBarTheme: SearchBarThemeData(
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: WidgetStatePropertyAll(surface),
        side: WidgetStatePropertyAll(
          BorderSide(color: colorScheme.outlineVariant.withValues(alpha: .58)),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        titleTextStyle: TextStyle(
          color: text,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        subtitleTextStyle: TextStyle(
          color: text.withValues(alpha: .7),
          fontSize: 13,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: brightness == Brightness.light
            ? const Color(0xFF25223A)
            : const Color(0xFFF1EEFF),
        contentTextStyle: TextStyle(
          color: brightness == Brightness.light ? Colors.white : ink,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
      ),
    );
  }
}

class AppColorChoice {
  const AppColorChoice({required this.label, required this.color});

  final String label;
  final Color color;
}
