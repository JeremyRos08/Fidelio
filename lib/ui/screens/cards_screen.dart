import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/loyalty_models.dart';
import '../../services/brand_directory_service.dart';
import '../../services/brand_logo_service.dart';
import '../../services/brand_promotion_service.dart';
import '../../state/loyalty_controller.dart';
import '../../theme/app_theme.dart';
import '../widgets/card_code_widget.dart';
import '../widgets/card_editor_sheet.dart';
import '../widgets/profile_button.dart';
import 'checkout_mode_screen.dart';
import 'scanner_screen.dart';
import 'store_webview_screen.dart';

enum _CardSort { favorites, recentlyUsed, alphabetical, newest }

class CardsScreen extends StatefulWidget {
  const CardsScreen({
    super.key,
    required this.controller,
    required this.onOpenProfile,
  });

  final LoyaltyController controller;
  final VoidCallback onOpenProfile;

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  final searchController = TextEditingController();
  String query = '';
  bool favoritesOnly = false;
  _CardSort sort = _CardSort.favorites;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _scanCard() async {
    final result = await Navigator.push<ScanResult>(
      context,
      MaterialPageRoute(builder: (_) => const ScannerScreen()),
    );
    if (!mounted || result == null) return;
    final suggestedStore = BrandDirectoryService.detectBrand(
      result.value,
      widget.controller.cards,
    );
    await showCardEditor(
      context,
      controller: widget.controller,
      scannedValue: result.value,
      scannedFormat: result.format,
      suggestedStoreName: suggestedStore,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final cards = widget.controller.cards.where((card) {
          final search = query.trim().toLowerCase();
          final matchesSearch =
              search.isEmpty ||
              card.storeName.toLowerCase().contains(search) ||
              card.cardNumber.toLowerCase().contains(search) ||
              card.notes.toLowerCase().contains(search);
          return matchesSearch && (!favoritesOnly || card.isFavorite);
        }).toList();
        switch (sort) {
          case _CardSort.favorites:
            cards.sort((a, b) {
              if (a.isFavorite != b.isFavorite) return a.isFavorite ? -1 : 1;
              return a.storeName.toLowerCase().compareTo(
                b.storeName.toLowerCase(),
              );
            });
          case _CardSort.recentlyUsed:
            cards.sort((a, b) {
              final aDate = a.lastOpenedAt;
              final bDate = b.lastOpenedAt;
              if (aDate == null && bDate == null) {
                return a.storeName.toLowerCase().compareTo(
                  b.storeName.toLowerCase(),
                );
              }
              if (aDate == null) return 1;
              if (bDate == null) return -1;
              return bDate.compareTo(aDate);
            });
          case _CardSort.alphabetical:
            cards.sort(
              (a, b) => a.storeName.toLowerCase().compareTo(
                b.storeName.toLowerCase(),
              ),
            );
          case _CardSort.newest:
            cards.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        }

        return CustomScrollView(
          key: const PageStorageKey('cards-scroll'),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.asset(
                        'assets/icon/fidelio_app_icon_v2.png',
                        width: 48,
                        height: 48,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fidelio',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          Text(
                            '${widget.controller.cards.length} carte${widget.controller.cards.length > 1 ? 's enregistrées' : ' enregistrée'}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    ProfileButton(
                      controller: widget.controller,
                      onPressed: widget.onOpenProfile,
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              sliver: SliverToBoxAdapter(
                child: _AddCardPanel(
                  onScan: _scanCard,
                  onManual: () =>
                      showCardEditor(context, controller: widget.controller),
                ),
              ),
            ),
            if (!widget.controller.isLoaded)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (widget.controller.cards.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyWallet(),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                sliver: SliverToBoxAdapter(
                  child: SearchBar(
                    controller: searchController,
                    hintText: 'Rechercher une carte',
                    leading: const Icon(Icons.search_rounded),
                    trailing: [
                      if (query.isNotEmpty)
                        IconButton(
                          tooltip: 'Effacer',
                          onPressed: () {
                            searchController.clear();
                            setState(() => query = '');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                    ],
                    onChanged: (value) => setState(() => query = value),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                sliver: SliverToBoxAdapter(
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        selected: favoritesOnly,
                        avatar: Icon(
                          favoritesOnly
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 18,
                        ),
                        label: const Text('Favoris uniquement'),
                        onSelected: (value) =>
                            setState(() => favoritesOnly = value),
                      ),
                      PopupMenuButton<_CardSort>(
                        tooltip: 'Trier les cartes',
                        initialValue: sort,
                        onSelected: (value) => setState(() => sort = value),
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: _CardSort.favorites,
                            child: Text('Favoris en premier'),
                          ),
                          PopupMenuItem(
                            value: _CardSort.recentlyUsed,
                            child: Text('Utilisées récemment'),
                          ),
                          PopupMenuItem(
                            value: _CardSort.alphabetical,
                            child: Text('Ordre alphabétique'),
                          ),
                          PopupMenuItem(
                            value: _CardSort.newest,
                            child: Text('Ajoutées récemment'),
                          ),
                        ],
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.sort_rounded, size: 19),
                              const SizedBox(width: 7),
                              Text(_sortLabel(sort)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (cards.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'Aucune carte ne correspond à votre recherche.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.crossAxisExtent;
                      final columnCount = switch (width) {
                        < 320 => 1,
                        < 700 => 2,
                        < 1060 => 3,
                        _ => 4,
                      };
                      final baseRatio = switch (columnCount) {
                        1 => 1.38,
                        2 => .82,
                        3 => 1.02,
                        _ => 1.14,
                      };
                      final textScale = MediaQuery.textScalerOf(
                        context,
                      ).scale(1).clamp(1.0, 1.35);
                      return SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columnCount,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: baseRatio / textScale,
                        ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final card = cards[index];
                          return _CardListTile(
                            key: ValueKey('loyalty-card-${card.id}'),
                            card: card,
                            hideSensitiveData:
                                widget.controller.hideCardPreviews,
                            onTap: () => _showCard(context, card),
                            onLongPress: () => _openCheckoutMode(card),
                            onFavorite: () =>
                                widget.controller.toggleFavorite(card.id),
                          );
                        }, childCount: cards.length),
                      );
                    },
                  ),
                ),
            ],
          ],
        );
      },
    );
  }

  static String _sortLabel(_CardSort value) => switch (value) {
    _CardSort.favorites => 'Favoris',
    _CardSort.recentlyUsed => 'Récentes',
    _CardSort.alphabetical => 'A–Z',
    _CardSort.newest => 'Nouvelles',
  };

  void _openCheckoutMode(StoreLoyaltyCard card) {
    widget.controller.markCardOpened(card.id);
    Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => CheckoutModeScreen(card: card)),
    );
  }

  void _showCard(BuildContext context, StoreLoyaltyCard card) {
    widget.controller.markCardOpened(card.id);
    final promotionPage = BrandPromotionService.pageFor(card.storeName);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  width: 62,
                  height: 62,
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(19),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: _BrandLogo(
                    storeName: card.storeName,
                    color: card.color,
                  ),
                ),
                const SizedBox(height: 13),
                Text(
                  card.storeName,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                if (card.notes.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    card.notes,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                const SizedBox(height: 22),
                CardCodeWidget(card: card),
                const SizedBox(height: 12),
                SelectableText(
                  card.cardNumber,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: card.cardNumber),
                    );
                    if (!sheetContext.mounted) return;
                    ScaffoldMessenger.of(sheetContext).showSnackBar(
                      const SnackBar(content: Text('Numéro de carte copié.')),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 19),
                  label: const Text('Copier le numéro'),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      Navigator.pop(sheetContext);
                      await Future<void>.delayed(
                        const Duration(milliseconds: 220),
                      );
                      if (!mounted) return;
                      _openCheckoutMode(card);
                    },
                    icon: const Icon(Icons.fullscreen_rounded),
                    label: const Text('Afficher en grand'),
                  ),
                ),
                if (promotionPage != null) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        Navigator.push<void>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StoreWebViewScreen(
                              storeName: card.storeName,
                              page: promotionPage,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.local_offer_outlined),
                      label: Text(
                        promotionPage.isDirectPromotionPage
                            ? 'Voir les promotions'
                            : 'Voir le site et les offres',
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          showCardEditor(
                            context,
                            controller: widget.controller,
                            card: card,
                          );
                        },
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Modifier'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFE45F7C),
                        ),
                        onPressed: () async {
                          final remove = await _confirmDelete(context, card);
                          if (remove && sheetContext.mounted) {
                            Navigator.pop(sheetContext);
                            widget.controller.removeCard(card.id);
                          }
                        },
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text('Supprimer'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(
    BuildContext context,
    StoreLoyaltyCard card,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Supprimer cette carte ?'),
            content: Text('${card.storeName} sera retirée de l’application.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE45F7C),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Supprimer'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _AddCardPanel extends StatelessWidget {
  const _AddCardPanel({required this.onScan, required this.onManual});

  final VoidCallback onScan;
  final VoidCallback onManual;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF705CF3), Color(0xFF4C38D2)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ajouter une carte',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Scannez son code ou saisissez son numéro.',
            style: TextStyle(color: Colors.white.withValues(alpha: .76)),
          ),
          const SizedBox(height: 17),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primary,
                  ),
                  onPressed: onScan,
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text('Scanner'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: .5)),
                    minimumSize: const Size(0, 50),
                  ),
                  onPressed: onManual,
                  icon: const Icon(Icons.keyboard_rounded),
                  label: const Text('Manuel'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardListTile extends StatelessWidget {
  const _CardListTile({
    super.key,
    required this.card,
    required this.hideSensitiveData,
    required this.onTap,
    required this.onLongPress,
    required this.onFavorite,
  });

  final StoreLoyaltyCard card;
  final bool hideSensitiveData;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final darkColor = Color.lerp(card.color, Colors.black, .28)!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 220;
        final padding = compact ? 12.0 : 16.0;
        final logoSize = compact ? 44.0 : 52.0;
        return Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          elevation: 3,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [card.color, darkColor],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -46,
                    top: -58,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: .08),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 18,
                    bottom: -72,
                    child: Container(
                      width: 145,
                      height: 145,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: .06),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(padding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: logoSize,
                              height: logoSize,
                              padding: EdgeInsets.all(compact ? 6 : 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(
                                  compact ? 13 : 16,
                                ),
                              ),
                              child: _BrandLogo(
                                storeName: card.storeName,
                                color: card.color,
                              ),
                            ),
                            SizedBox(width: compact ? 8 : 12),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  card.storeName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: compact ? 15 : 18,
                                    height: 1.05,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: compact ? 34 : 40,
                              height: compact ? 34 : 40,
                              child: IconButton(
                                tooltip: card.isFavorite
                                    ? 'Retirer des favoris'
                                    : 'Ajouter aux favoris',
                                padding: EdgeInsets.zero,
                                onPressed: onFavorite,
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white.withValues(
                                    alpha: .12,
                                  ),
                                ),
                                iconSize: compact ? 20 : 23,
                                icon: Icon(
                                  card.isFavorite
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  color: card.isFavorite
                                      ? const Color(0xFFFFD166)
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (hideSensitiveData)
                          Container(
                            height: 66,
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .94),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.lock_outline_rounded,
                                  color: AppTheme.ink,
                                  size: 18,
                                ),
                                SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Touchez pour afficher',
                                    maxLines: 2,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppTheme.ink,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          CompactCardCodeWidget(card: card),
                        const SizedBox(height: 7),
                        Text(
                          hideSensitiveData ? 'Numéro masqué' : card.cardNumber,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BrandLogo extends StatelessWidget {
  const _BrandLogo({required this.storeName, required this.color});

  final String storeName;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final uri = BrandLogoService.logoUri(storeName);
    final fallback = Center(
      child: Text(
        BrandLogoService.initials(storeName),
        style: TextStyle(
          color: color,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
    if (uri == null) return fallback;
    return CachedNetworkImage(
      imageUrl: uri.toString(),
      cacheManager: BrandLogoService.cacheManager,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      fadeInDuration: const Duration(milliseconds: 160),
      placeholder: (_, _) => fallback,
      errorWidget: (_, _, _) => fallback,
    );
  }
}

class _EmptyWallet extends StatelessWidget {
  const _EmptyWallet();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(30, 10, 30, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: .1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_card_rounded,
                color: AppTheme.primary,
                size: 42,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Aucune carte enregistrée',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'Utilisez Scanner ou Manuel pour ajouter votre première carte.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
