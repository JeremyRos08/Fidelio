import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/product_comparison_models.dart';
import '../../services/barcode_scan_service.dart';
import '../../services/price_history_service.dart';
import '../../services/product_lookup_service.dart';
import '../../services/product_search_uri_service.dart';
import '../../services/visual_search_service.dart';
import '../../state/loyalty_controller.dart';
import '../../theme/app_theme.dart';
import '../../services/brand_promotion_service.dart';
import 'scanner_screen.dart';
import 'store_webview_screen.dart';

class ProductCompareScreen extends StatefulWidget {
  const ProductCompareScreen({super.key, required this.controller});

  final LoyaltyController controller;

  @override
  State<ProductCompareScreen> createState() => _ProductCompareScreenState();
}

class _ProductCompareScreenState extends State<ProductCompareScreen> {
  final lookupService = ProductLookupService();
  final visualSearchService = VisualSearchService();
  final imagePicker = ImagePicker();
  List<PriceObservation> history = [];
  ProductInfo? product;
  bool loading = false;
  bool photoSearching = false;

  static final destinations = <ComparisonDestination>[
    ComparisonDestination(
      name: 'Google Web',
      domain: 'google.com',
      iconKey: 'search',
      uriBuilder: (query) => Uri.https('www.google.com', '/search', {
        'q': query,
        'hl': 'fr',
        'gl': 'fr',
      }),
    ),
    ComparisonDestination(
      name: 'Google Shopping',
      domain: 'google.com',
      iconKey: 'shopping',
      uriBuilder: (query) => Uri.https('www.google.com', '/search', {
        'tbm': 'shop',
        'q': query,
        'hl': 'fr',
        'gl': 'fr',
      }),
    ),
    ComparisonDestination(
      name: 'Idealo',
      domain: 'idealo.fr',
      iconKey: 'compare',
      uriBuilder: ProductSearchUriService.idealo,
    ),
    ComparisonDestination(
      name: 'Amazon',
      domain: 'amazon.fr',
      iconKey: 'store',
      uriBuilder: (query) => Uri.https('www.amazon.fr', '/s', {'k': query}),
    ),
    ComparisonDestination(
      name: 'Cdiscount',
      domain: 'cdiscount.com',
      iconKey: 'store',
      uriBuilder: (query) =>
          Uri.https('www.cdiscount.com', '/search/10/$query.html'),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    lookupService.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final loaded = await PriceHistoryService.load();
    if (mounted) setState(() => history = loaded);
  }

  Future<void> _scanProduct() async {
    final result = await Navigator.push<ScanResult>(
      context,
      MaterialPageRoute(builder: (_) => const ScannerScreen()),
    );
    if (!mounted || result == null) return;
    final code = _validScannedProductCode(result.value);
    if (code == null) {
      _showMessage('Ce code ne ressemble pas à un EAN ou UPC de produit.');
      return;
    }
    await _lookup(code);
  }

  Future<void> _enterCode() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Saisir un code ou une référence'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.text,
          autocorrect: false,
          enableSuggestions: false,
          decoration: const InputDecoration(
            labelText: 'EAN, UPC, GTIN ou référence',
            hintText: 'Ex. 3017620422003 ou 45888',
          ),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Rechercher'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || value == null) return;
    final code = ProductLookupService.normalizeReference(value);
    if (code == null) {
      _showMessage('Saisissez un code ou une référence de 3 à 40 caractères.');
      return;
    }
    await _lookup(code);
  }

  Future<void> _openPhotoSearch() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Text(
                'Choisir la photo du produit',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Prendre une photo'),
              subtitle: const Text('Photographier le produit maintenant'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choisir dans la galerie'),
              subtitle: const Text('Utiliser une image déjà enregistrée'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 18),
              child: Text(
                'Aucune image n’est envoyée avant votre confirmation.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
    if (!mounted || source == null) return;

    try {
      final image = await imagePicker.pickImage(
        source: source,
        maxWidth: 2500,
        maxHeight: 2500,
        imageQuality: 90,
        requestFullMetadata: false,
      );
      if (!mounted || image == null) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Envoyer cette photo ?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.memory(
                  bytes,
                  height: 260,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const SizedBox(
                    height: 120,
                    child: Center(child: Icon(Icons.broken_image_outlined)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'La photo sera envoyée à Google Lens pour rechercher ce produit. Fidelio n’en conservera pas de copie.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.send_rounded),
              label: const Text('Envoyer'),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;

      setState(() => photoSearching = true);
      final uploadPage = visualSearchService.createUploadPage(
        bytes: bytes,
        filename: image.name.isEmpty ? 'photo-produit.jpg' : image.name,
      );
      if (!mounted) return;
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => StoreWebViewScreen(
            storeName: 'Google Lens',
            title: 'Résultats de la photo',
            allowExternalNavigation: true,
            initialHtml: uploadPage,
            initialBaseUrl: 'https://lens.google.com/',
            page: BrandPromotionPage(
              uri: Uri.parse('https://lens.google.com/'),
              allowedHostSuffixes: const {'google.com'},
              isDirectPromotionPage: false,
            ),
          ),
        ),
      );
    } on VisualSearchException catch (error) {
      if (mounted) _showMessage(error.message);
    } on Object {
      if (mounted) {
        _showMessage('Impossible d’ouvrir cette photo. Réessayez.');
      }
    } finally {
      if (mounted) setState(() => photoSearching = false);
    }
  }

  Future<void> _lookup(String code) async {
    setState(() {
      loading = true;
      product = ProductInfo(code: code);
    });
    final result = await lookupService.lookup(code);
    if (!mounted) return;
    setState(() {
      product = result;
      loading = false;
    });
  }

  Future<void> _addObservedPrice() async {
    final current = product;
    if (current == null) return;
    final storeController = TextEditingController();
    final priceController = TextEditingController();
    String? error;
    final stores = widget.controller.cards
        .map((card) => card.storeName)
        .toSet()
        .take(6)
        .toList();
    final result = await showModalBottomSheet<({String store, double price})>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              0,
              20,
              MediaQuery.viewInsetsOf(context).bottom + 22,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enregistrer le prix vu',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: storeController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Enseigne'),
                ),
                if (stores.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 7,
                    children: [
                      for (final store in stores)
                        ActionChip(
                          label: Text(store),
                          onPressed: () => storeController.text = store,
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  autofocus: stores.isEmpty,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Prix constaté',
                    suffixText: '€',
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      final store = storeController.text.trim();
                      final price = double.tryParse(
                        priceController.text.replaceAll(',', '.').trim(),
                      );
                      if (store.isEmpty || price == null || price <= 0) {
                        setSheetState(
                          () => error =
                              'Indiquez une enseigne et un prix valide.',
                        );
                        return;
                      }
                      Navigator.pop(context, (store: store, price: price));
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Ajouter à l’historique'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    storeController.dispose();
    priceController.dispose();
    if (!mounted || result == null) return;
    final observation = PriceObservation(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      productCode: current.code,
      productName: current.name ?? 'Produit ${current.code}',
      storeName: result.store,
      price: result.price,
      createdAt: DateTime.now(),
    );
    final updated = await PriceHistoryService.add(history, observation);
    if (mounted) setState(() => history = updated);
  }

  void _openDestination(ComparisonDestination destination) {
    final current = product;
    if (current == null) return;
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => StoreWebViewScreen(
          storeName: destination.name,
          title: destination.name,
          allowExternalNavigation: true,
          page: BrandPromotionPage(
            uri: destination.uriBuilder(current.searchQuery),
            allowedHostSuffixes: {destination.domain},
            isDirectPromotionPage: false,
          ),
        ),
      ),
    );
  }

  Future<void> _removeObservation(PriceObservation observation) async {
    final updated = await PriceHistoryService.remove(history, observation.id);
    if (mounted) setState(() => history = updated);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final current = product;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          key: const PageStorageKey('product-compare-scroll'),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
          children: [
            Text(
              'Comparer un produit',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 5),
            Text(
              'Scannez son code-barres pour rechercher le produit et comparer les offres.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D8F87), Color(0xFF086C73)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF086C73),
                          ),
                          onPressed: loading ? null : _scanProduct,
                          icon: const Icon(Icons.qr_code_scanner_rounded),
                          label: const Text('Scanner'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                          ),
                          onPressed: loading ? null : _enterCode,
                          icon: const Icon(Icons.keyboard_rounded),
                          label: const Text('Saisir'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white70),
                      ),
                      onPressed: photoSearching ? null : _openPhotoSearch,
                      icon: photoSearching
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.camera_alt_rounded),
                      label: Text(
                        photoSearching
                            ? 'Envoi de la photo…'
                            : 'Rechercher avec une photo',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (loading) ...[
              const SizedBox(height: 20),
              const LinearProgressIndicator(),
            ],
            if (current != null && !loading) ...[
              const SizedBox(height: 22),
              _ProductCard(product: current),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _addObservedPrice,
                  icon: const Icon(Icons.euro_rounded),
                  label: const Text('Enregistrer le prix vu'),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Comparer ailleurs',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 5),
              Text(
                'Fidelio transmet uniquement la recherche produit au site choisi.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: MediaQuery.sizeOf(context).width >= 600 ? 4 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.15,
                children: [
                  for (final destination in destinations)
                    OutlinedButton.icon(
                      onPressed: () => _openDestination(destination),
                      icon: Icon(
                        destination.iconKey == 'search'
                            ? Icons.search_rounded
                            : destination.iconKey == 'compare'
                            ? Icons.compare_arrows_rounded
                            : destination.iconKey == 'shopping'
                            ? Icons.shopping_bag_outlined
                            : Icons.storefront_outlined,
                      ),
                      label: Text(
                        destination.name,
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 28),
            Text(
              'Historique local',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 5),
            Text(
              'Les prix que vous notez restent uniquement sur cet appareil.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            if (history.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text('Aucun prix enregistré pour le moment.'),
                ),
              )
            else
              for (final observation in history)
                Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text('${observation.price.toStringAsFixed(0)}€'),
                    ),
                    title: Text(observation.productName),
                    subtitle: Text(
                      '${observation.storeName} · ${_formatPrice(observation.price)} · ${_formatDate(observation.createdAt)}',
                    ),
                    onTap: () => _lookup(observation.productCode),
                    trailing: IconButton(
                      tooltip: 'Supprimer ce prix',
                      onPressed: () => _removeObservation(observation),
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  static String? _validScannedProductCode(String value) {
    final code = value.replaceAll(RegExp(r'[\s-]'), '');
    if (!RegExp(r'^\d{6,14}$').hasMatch(code)) return null;
    if (const [8, 12, 13, 14].contains(code.length) &&
        !BarcodeScanService.hasValidGtinCheckDigit(code)) {
      return null;
    }
    return code;
  }

  static String _formatPrice(double price) =>
      '${price.toStringAsFixed(2).replaceAll('.', ',')} €';

  static String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final ProductInfo product;

  @override
  Widget build(BuildContext context) {
    final identified = product.name != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: product.imageUrl == null
                      ? const Icon(
                          Icons.inventory_2_outlined,
                          color: AppTheme.primary,
                        )
                      : CachedNetworkImage(
                          imageUrl: product.imageUrl!,
                          fit: BoxFit.contain,
                          errorWidget: (_, _, _) =>
                              const Icon(Icons.inventory_2_outlined),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name ?? 'Produit non identifié',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      if (product.brand != null) Text(product.brand!),
                      if (product.quantity != null) Text(product.quantity!),
                      const SizedBox(height: 7),
                      SelectableText(
                        product.code,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      if (!identified) ...[
                        const SizedBox(height: 5),
                        Text(
                          'La comparaison reste possible avec le code-barres.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),
            if (product.marketPrices.isEmpty)
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 20),
                    SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Aucun prix public récent trouvé pour ce code. Vous pouvez noter le prix vu en magasin.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Prix récents signalés',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.price_check_rounded,
                    color: AppTheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 9),
              for (var index = 0; index < product.marketPrices.length; index++)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: index == product.marketPrices.length - 1 ? 0 : 8,
                  ),
                  child: _MarketPriceRow(price: product.marketPrices[index]),
                ),
              const SizedBox(height: 9),
              Text(
                'Relevés collaboratifs Open Prices · Vérifiez le tarif en magasin.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MarketPriceRow extends StatelessWidget {
  const _MarketPriceRow({required this.price});

  final ProductMarketPrice price;

  @override
  Widget build(BuildContext context) {
    final location = [price.storeName, ?price.city].join(' · ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary.withValues(alpha: .14)),
      ),
      child: Row(
        children: [
          Text(
            _formatMarketPrice(price),
            style: const TextStyle(
              color: AppTheme.primary,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  '${price.isDiscounted ? 'Promotion · ' : ''}Relevé le ${_formatMarketDate(price.date)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatMarketPrice(ProductMarketPrice price) {
    final value = price.price.toStringAsFixed(2).replaceAll('.', ',');
    return price.currency == 'EUR' ? '$value €' : '$value ${price.currency}';
  }

  static String _formatMarketDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
