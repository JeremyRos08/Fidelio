import 'package:flutter/material.dart';

import '../state/loyalty_controller.dart';
import 'screens/cards_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/product_compare_screen.dart';
import 'screens/settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.controller,
    required this.isDarkMode,
    required this.primaryColor,
    required this.textScale,
    required this.onThemeChanged,
    required this.onPrimaryColorChanged,
    required this.onTextScaleChanged,
  });

  final LoyaltyController controller;
  final bool isDarkMode;
  final Color primaryColor;
  final double textScale;
  final ValueChanged<bool> onThemeChanged;
  final ValueChanged<Color> onPrimaryColorChanged;
  final ValueChanged<double> onTextScaleChanged;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;

  void _openProfile() {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(controller: widget.controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) => LayoutBuilder(
        builder: (context, constraints) {
          final pages = IndexedStack(
            index: index,
            children: [
              CardsScreen(
                controller: widget.controller,
                onOpenProfile: _openProfile,
              ),
              ProductCompareScreen(controller: widget.controller),
              SettingsScreen(
                controller: widget.controller,
                isDarkMode: widget.isDarkMode,
                primaryColor: widget.primaryColor,
                textScale: widget.textScale,
                onThemeChanged: widget.onThemeChanged,
                onPrimaryColorChanged: widget.onPrimaryColorChanged,
                onTextScaleChanged: widget.onTextScaleChanged,
              ),
            ],
          );
          if (constraints.maxWidth >= 840) {
            return Scaffold(
              body: SafeArea(
                child: Row(
                  children: [
                    NavigationRail(
                      selectedIndex: index,
                      extended: constraints.maxWidth >= 1120,
                      minExtendedWidth: 190,
                      groupAlignment: -.75,
                      onDestinationSelected: (value) =>
                          setState(() => index = value),
                      leading: Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.asset(
                            'assets/icon/fidelio_app_icon_v2.png',
                            width: 48,
                            height: 48,
                          ),
                        ),
                      ),
                      destinations: const [
                        NavigationRailDestination(
                          icon: Icon(Icons.credit_card_outlined),
                          selectedIcon: Icon(Icons.credit_card_rounded),
                          label: Text('Cartes'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.qr_code_scanner_outlined),
                          selectedIcon: Icon(Icons.price_check_rounded),
                          label: Text('Comparer'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.tune_outlined),
                          selectedIcon: Icon(Icons.tune_rounded),
                          label: Text('Réglages'),
                        ),
                      ],
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: pages),
                  ],
                ),
              ),
            );
          }
          return Scaffold(
            body: SafeArea(bottom: false, child: pages),
            bottomNavigationBar: NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (value) => setState(() => index = value),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.credit_card_outlined),
                  selectedIcon: Icon(Icons.credit_card_rounded),
                  label: 'Cartes',
                ),
                NavigationDestination(
                  icon: Icon(Icons.qr_code_scanner_outlined),
                  selectedIcon: Icon(Icons.price_check_rounded),
                  label: 'Comparer',
                ),
                NavigationDestination(
                  icon: Icon(Icons.tune_outlined),
                  selectedIcon: Icon(Icons.tune_rounded),
                  label: 'Réglages',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
