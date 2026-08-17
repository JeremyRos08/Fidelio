import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'state/loyalty_controller.dart';
import 'theme/app_theme.dart';
import 'ui/main_shell.dart';

void main() => runApp(const FidelioApp());

class FidelioApp extends StatefulWidget {
  const FidelioApp({super.key});

  @override
  State<FidelioApp> createState() => _FidelioAppState();
}

class _FidelioAppState extends State<FidelioApp> {
  static const _darkModeStorageKey = 'fidelio.appearance.dark_mode';
  static const _primaryColorStorageKey = 'fidelio.appearance.primary_color';
  static const _textScaleStorageKey = 'fidelio.appearance.text_scale';

  late final LoyaltyController controller;
  ThemeMode themeMode = ThemeMode.light;
  Color primaryColor = AppTheme.primary;
  double textScale = 1;

  @override
  void initState() {
    super.initState();
    controller = LoyaltyController();
    unawaited(_loadAppearance());
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fidelio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(primaryColor),
      darkTheme: AppTheme.dark(primaryColor),
      themeMode: themeMode,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final systemScale = mediaQuery.textScaler.scale(16) / 16;
        final effectiveScale = (systemScale * textScale).clamp(.8, 2.2);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(effectiveScale),
          ),
          child: child!,
        );
      },
      home: MainShell(
        controller: controller,
        isDarkMode: themeMode == ThemeMode.dark,
        primaryColor: primaryColor,
        textScale: textScale,
        onThemeChanged: _changeThemeMode,
        onPrimaryColorChanged: _changePrimaryColor,
        onTextScaleChanged: _changeTextScale,
      ),
    );
  }

  Future<void> _loadAppearance() async {
    final preferences = await SharedPreferences.getInstance();
    final storedColor = preferences.getInt(_primaryColorStorageKey);
    final supportedColors = AppTheme.colorChoices.map((item) => item.color);
    final storedTextScale = preferences.getDouble(_textScaleStorageKey);
    if (!mounted) return;
    setState(() {
      themeMode = preferences.getBool(_darkModeStorageKey) == true
          ? ThemeMode.dark
          : ThemeMode.light;
      if (storedColor != null) {
        final candidate = Color(storedColor);
        if (supportedColors.contains(candidate)) primaryColor = candidate;
      }
      if (storedTextScale != null &&
          const [.9, 1.0, 1.15].contains(storedTextScale)) {
        textScale = storedTextScale;
      }
    });
  }

  void _changeThemeMode(bool isDark) {
    setState(() {
      themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
    unawaited(_saveBool(_darkModeStorageKey, isDark));
  }

  void _changePrimaryColor(Color color) {
    setState(() => primaryColor = color);
    unawaited(_saveInt(_primaryColorStorageKey, color.toARGB32()));
  }

  void _changeTextScale(double scale) {
    setState(() => textScale = scale);
    unawaited(_saveDouble(_textScaleStorageKey, scale));
  }

  Future<void> _saveBool(String key, bool value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(key, value);
  }

  Future<void> _saveInt(String key, int value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(key, value);
  }

  Future<void> _saveDouble(String key, double value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setDouble(key, value);
  }
}
