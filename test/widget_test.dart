import 'dart:convert';

import 'package:fidelio/main.dart';
import 'package:fidelio/models/loyalty_models.dart';
import 'package:fidelio/models/product_comparison_models.dart';
import 'package:fidelio/services/barcode_scan_service.dart';
import 'package:fidelio/services/brand_directory_service.dart';
import 'package:fidelio/services/brand_logo_service.dart';
import 'package:fidelio/services/brand_promotion_service.dart';
import 'package:fidelio/services/card_backup_service.dart';
import 'package:fidelio/services/price_history_service.dart';
import 'package:fidelio/services/product_lookup_service.dart';
import 'package:fidelio/services/product_search_uri_service.dart';
import 'package:fidelio/services/visual_search_service.dart';
import 'package:fidelio/theme/app_theme.dart';
import 'package:fidelio/ui/screens/about_screen.dart';
import 'package:fidelio/ui/screens/brand_picker_screen.dart';
import 'package:fidelio/ui/screens/checkout_mode_screen.dart';
import 'package:fidelio/ui/screens/help_screen.dart';
import 'package:fidelio/ui/screens/store_webview_screen.dart';
import 'package:fidelio/ui/widgets/card_code_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Fidelio',
      packageName: 'fr.fidelio.fidelio',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  testWidgets('affiche un portefeuille vide centré sur les cartes', (
    tester,
  ) async {
    await tester.pumpWidget(const FidelioApp());
    await tester.pumpAndSettle();

    expect(find.text('Aucune carte enregistrée'), findsOneWidget);
    expect(find.text('Scanner'), findsOneWidget);
    expect(find.text('Manuel'), findsOneWidget);
    expect(find.text('Cartes'), findsOneWidget);
    expect(find.text('Comparer'), findsOneWidget);
    expect(find.text('Réglages'), findsOneWidget);
    expect(find.text('Offres'), findsNothing);
  });

  testWidgets('ajoute une carte manuellement et affiche un code compact', (
    tester,
  ) async {
    await tester.pumpWidget(const FidelioApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Manuel'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(3));
    expect(find.byTooltip('Scanner le numéro'), findsOneWidget);
    await tester.enterText(fields.at(0), 'Boutique Test');
    await tester.enterText(fields.at(1), '123456789');
    await tester.tap(find.byTooltip('Bleu nuit'));
    tester.testTextInput.hide();
    await tester.ensureVisible(find.text('Enregistrer la carte'));
    await tester.tap(find.text('Enregistrer la carte'));
    await tester.pumpAndSettle();

    expect(find.text('Boutique Test'), findsOneWidget);
    expect(find.text('123456789'), findsOneWidget);
    expect(find.text('Favoris uniquement'), findsOneWidget);
    expect(find.byTooltip('Trier les cartes'), findsOneWidget);
    await tester.tap(find.byTooltip('Trier les cartes'));
    await tester.pumpAndSettle();
    expect(find.text('Utilisées récemment'), findsOneWidget);
    await tester.tap(find.text('Utilisées récemment'));
    await tester.pumpAndSettle();
    expect(find.textContaining('offre', findRichText: true), findsNothing);
    expect(find.byType(CompactCardCodeWidget), findsOneWidget);
    final compactCodeSize = tester.getSize(
      find.byKey(const ValueKey('compact-linear-code')),
    );
    expect(compactCodeSize.width, lessThanOrEqualTo(240));
    expect(compactCodeSize.height, 52);

    final preferences = await SharedPreferences.getInstance();
    final savedCards =
        jsonDecode(preferences.getString('fidelio.loyalty_cards')!)
            as List<dynamic>;
    expect(
      (savedCards.single as Map<String, dynamic>)['colorValue'],
      const Color(0xFF173F5F).toARGB32(),
    );

    await tester.tap(find.text('Boutique Test'));
    await tester.pumpAndSettle();
    expect(find.text('Copier le numéro'), findsOneWidget);
    expect(find.text('Afficher en grand'), findsOneWidget);
    expect(find.text('Voir le site et les offres'), findsOneWidget);
    final refreshedCards =
        jsonDecode(preferences.getString('fidelio.loyalty_cards')!)
            as List<dynamic>;
    expect(
      (refreshedCards.single as Map<String, dynamic>)['lastOpenedAt'],
      isNotNull,
    );
  });

  testWidgets('organise les cartes en grille sur un téléphone', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final cards = [
      StoreLoyaltyCard(
        id: 'grid-card-1',
        storeName: 'Carrefour',
        cardNumber: '123456789',
        colorValue: Colors.blue.toARGB32(),
        codeFormat: 'code128',
        createdAt: DateTime(2026, 8, 3),
      ),
      StoreLoyaltyCard(
        id: 'grid-card-2',
        storeName: 'Decathlon',
        cardNumber: '987654321',
        colorValue: Colors.teal.toARGB32(),
        codeFormat: 'code128',
        createdAt: DateTime(2026, 8, 2),
      ),
    ];
    SharedPreferences.setMockInitialValues({
      'fidelio.loyalty_cards': jsonEncode(
        cards.map((card) => card.toJson()).toList(),
      ),
    });

    await tester.pumpWidget(const FidelioApp());
    await tester.pumpAndSettle();

    final first = find.byKey(const ValueKey('loyalty-card-grid-card-1'));
    final second = find.byKey(const ValueKey('loyalty-card-grid-card-2'));
    expect(first, findsOneWidget);
    expect(second, findsOneWidget);
    final firstPosition = tester.getTopLeft(first);
    final secondPosition = tester.getTopLeft(second);
    expect(secondPosition.dy, closeTo(firstPosition.dy, .1));
    expect(secondPosition.dx, greaterThan(firstPosition.dx));
  });

  testWidgets('propose la page directe pour une enseigne reconnue', (
    tester,
  ) async {
    await tester.pumpWidget(const FidelioApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Manuel'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'E.Leclerc');
    await tester.enterText(fields.at(1), '123456789');
    tester.testTextInput.hide();
    await tester.ensureVisible(find.text('Enregistrer la carte'));
    await tester.tap(find.text('Enregistrer la carte'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('E.Leclerc'));
    await tester.pumpAndSettle();
    expect(find.text('Voir les promotions'), findsOneWidget);
  });

  testWidgets('nettoie les anciennes données liées aux offres', (tester) async {
    SharedPreferences.setMockInitialValues({
      'mes_cartes.store_offers': '[]',
      'mes_cartes.notifications_enabled': true,
      'fidelio.offers.nearby_enabled': true,
      'fidelio.offers.last_latitude': 48.8,
    });

    await tester.pumpWidget(const FidelioApp());
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.containsKey('mes_cartes.store_offers'), isFalse);
    expect(
      preferences.containsKey('mes_cartes.notifications_enabled'),
      isFalse,
    );
    expect(preferences.containsKey('fidelio.offers.nearby_enabled'), isFalse);
    expect(preferences.containsKey('fidelio.offers.last_latitude'), isFalse);
  });

  testWidgets('ouvre les pages à propos et confidentialité', (tester) async {
    await tester.pumpWidget(const FidelioApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Réglages'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('À propos de Fidelio'), 300);
    expect(
      find.widgetWithText(ListTile, 'À propos de Fidelio'),
      findsOneWidget,
    );

    await tester.pumpWidget(const MaterialApp(home: AboutScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Fidelio, c’est quoi ?'), findsOneWidget);
    expect(find.text('Version 1.0 (1)'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Confidentialité'), 250);
    await tester.tap(find.text('Confidentialité'));
    await tester.pumpAndSettle();
    expect(find.text('Vos cartes vous appartiennent'), findsOneWidget);
    expect(find.text('Localisation facultative'), findsNothing);
    expect(find.text('Notifications facultatives'), findsNothing);
  });

  testWidgets('ouvre et personnalise le profil local', (tester) async {
    await tester.pumpWidget(const FidelioApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Mon compte'));
    await tester.pumpAndSettle();
    expect(find.text('Aucun compte connecté'), findsOneWidget);
    expect(find.text('Favoris'), findsOneWidget);
    expect(find.text('Offres'), findsNothing);
    await tester.tap(find.byTooltip('Modifier le profil'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Jérémy');
    await tester.enterText(fields.at(1), 'Rossignol');
    await tester.enterText(fields.at(2), 'jeremy@example.fr');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(find.text('Jérémy Rossignol'), findsOneWidget);
    expect(find.text('jeremy@example.fr'), findsOneWidget);
  });

  testWidgets('personnalise et mémorise l’apparence', (tester) async {
    await tester.pumpWidget(const FidelioApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Réglages'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(SwitchListTile, 'Mode sombre'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Couleur de l’interface'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bleu'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Taille du texte'), 250);
    await tester.drag(find.byType(ListView).last, const Offset(0, -25));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Taille du texte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Grande'));
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool('fidelio.appearance.dark_mode'), isTrue);
    expect(
      preferences.getInt('fidelio.appearance.primary_color'),
      const Color(0xFF1565C0).toARGB32(),
    );
    expect(preferences.getDouble('fidelio.appearance.text_scale'), 1.15);
  });

  testWidgets('masque les codes des cartes dans le portefeuille', (
    tester,
  ) async {
    final card = StoreLoyaltyCard(
      id: 'private-card',
      storeName: 'Carrefour',
      cardNumber: '123456789',
      colorValue: Colors.blue.toARGB32(),
      codeFormat: 'code128',
      createdAt: DateTime(2026, 8, 3),
    );
    SharedPreferences.setMockInitialValues({
      'fidelio.loyalty_cards': jsonEncode([card.toJson()]),
    });
    await tester.pumpWidget(const FidelioApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Réglages'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(SwitchListTile, 'Masquer les codes dans la liste'),
    );
    await tester.pumpAndSettle();
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool('fidelio.privacy.hide_card_previews'), isTrue);

    await tester.tap(find.text('Cartes'));
    await tester.pumpAndSettle();
    expect(find.text('Touchez pour afficher'), findsOneWidget);
    expect(find.text('Numéro masqué'), findsOneWidget);
    expect(find.byType(CompactCardCodeWidget), findsNothing);
  });

  testWidgets('affiche une carte dans un mode caisse agrandi', (tester) async {
    final card = StoreLoyaltyCard(
      id: 'checkout-card',
      storeName: 'Decathlon',
      cardNumber: '123456789',
      colorValue: Colors.blue.toARGB32(),
      codeFormat: 'code128',
      createdAt: DateTime(2026, 8, 3),
    );
    await tester.pumpWidget(MaterialApp(home: CheckoutModeScreen(card: card)));
    await tester.pumpAndSettle();

    expect(find.text('Decathlon'), findsOneWidget);
    expect(find.byType(CardCodeWidget), findsOneWidget);
    expect(find.byTooltip('Fermer le mode caisse'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('ouvre le comparateur et son aide dédiée', (tester) async {
    await tester.pumpWidget(const FidelioApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Comparer'));
    await tester.pumpAndSettle();
    expect(find.text('Comparer un produit'), findsOneWidget);
    expect(find.text('Scanner'), findsOneWidget);
    expect(find.text('Saisir'), findsOneWidget);
    expect(find.text('Rechercher avec une photo'), findsOneWidget);
    expect(find.text('Historique local'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: HelpScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Aide et mode d’emploi'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Comparer un produit'), 250);
    expect(find.text('Comparer un produit'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('À savoir'), 300);
    expect(find.text('À savoir'), findsOneWidget);
  });

  testWidgets('réserve le bas de l’écran dans les WebViews', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      await tester.pumpWidget(
        MaterialApp(
          home: StoreWebViewScreen(
            storeName: 'Boutique test',
            page: BrandPromotionPage(
              uri: Uri.parse('https://example.com'),
              allowedHostSuffixes: const {'example.com'},
              isDirectPromotionPage: false,
            ),
          ),
        ),
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }

    final safeArea = tester.widget<SafeArea>(
      find.byKey(const ValueKey('webview-bottom-safe-area')),
    );
    expect(safeArea.top, isFalse);
    expect(safeArea.bottom, isTrue);
    expect(safeArea.minimum.bottom, 12);
  });

  testWidgets('affiche les enseignes lisiblement sans mention technique', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'mes_cartes.brand_directory.nsi.v9': ['Carrefour', 'Decathlon'],
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(AppTheme.primary),
        home: const BrandPickerScreen(),
      ),
    );
    await tester.pumpAndSettle();

    final carrefour = find.text('Carrefour');
    expect(carrefour, findsOneWidget);
    expect(
      tester.widget<Text>(carrefour).style?.color,
      Theme.of(tester.element(carrefour)).colorScheme.onSurface,
    );
    expect(find.textContaining('OpenStreetMap'), findsNothing);
  });

  test('détecte une enseigne depuis le domaine d’un QR code', () {
    expect(
      BrandDirectoryService.detectBrand(
        'https://www.carrefour.fr/ma-carte/123456',
        const [],
      ),
      'Carrefour',
    );
  });

  test('valide un EAN-13 et conserve son format détecté', () {
    final scan = BarcodeScanService.validate(
      rawValue: '4006381333931',
      rawFormat: 'ean13',
    );
    expect(scan, isNotNull);
    expect(scan!.value, '4006381333931');
    expect(scan.format, 'ean13');
  });

  test('refuse un EAN-13 comportant une erreur de lecture', () {
    expect(
      BarcodeScanService.validate(
        rawValue: '4006381333932',
        rawFormat: 'ean13',
      ),
      isNull,
    );
  });

  test('demande davantage de stabilité pour un code-barres', () {
    expect(BarcodeScanService.requiredConfirmations('ean13'), 5);
    expect(BarcodeScanService.requiredConfirmations('qrCode'), 2);
    expect(
      BarcodeScanService.requiredStableDuration('ean13'),
      greaterThan(const Duration(milliseconds: 900)),
    );
  });

  test('associe un logo connu et crée des initiales de secours', () {
    final logo = BrandLogoService.logoUri('Leroy Merlin');
    expect(logo?.host, 'raw.githubusercontent.com');
    expect(BrandLogoService.initials('Boutique Test'), 'BT');
  });

  test('associe les enseignes reconnues à leur page officielle', () {
    final leclerc = BrandPromotionService.pageFor('E.Leclerc');
    expect(leclerc, isNotNull);
    expect(leclerc!.uri.host, 'www.e.leclerc');
    expect(leclerc.allowsHost('nos-catalogues-promos-v2.e.leclerc'), isTrue);
    expect(leclerc.storeHomeUri, Uri.parse('https://www.e.leclerc/'));
    final suggested = BrandPromotionService.pageFor('Boutique Test');
    expect(suggested, isNotNull);
    expect(suggested!.uri.host, 'www.boutiquetest.fr');
    expect(suggested.alternativeUris.single.host, 'www.boutiquetest.com');
    expect(suggested.isAddressSuggested, isTrue);
  });

  test('crée un lien pour toutes les enseignes proposées', () {
    for (final brand in BrandDirectoryService.popularBrands) {
      expect(
        BrandPromotionService.pageFor(brand),
        isNotNull,
        reason: 'Lien absent pour $brand',
      );
    }
  });

  test('exporte puis relit une sauvegarde Fidelio', () {
    final original = StoreLoyaltyCard(
      id: 'card-backup',
      storeName: 'Decathlon',
      cardNumber: '1234 5678',
      colorValue: Colors.blue.toARGB32(),
      codeFormat: 'code128',
      createdAt: DateTime(2026, 8, 1),
      notes: 'Carte principale',
      isFavorite: true,
      lastOpenedAt: DateTime(2026, 8, 2, 18, 30),
    );
    final restored = CardBackupService.readFile(
      CardBackupService.createFile([original]),
    );
    expect(restored, hasLength(1));
    expect(restored.single.storeName, original.storeName);
    expect(restored.single.isFavorite, isTrue);
    expect(restored.single.lastOpenedAt, original.lastOpenedAt);
  });

  test('refuse une sauvegarde incompatible', () {
    expect(
      () => CardBackupService.readFile(
        utf8.encode('{"format":"autre-format","cards":[]}'),
      ),
      throwsA(isA<CardBackupException>()),
    );
  });

  test('identifie un produit alimentaire à partir de son EAN', () async {
    final client = MockClient((request) async {
      expect(request.headers['User-Agent'], contains('Fidelio/1.0.0'));
      if (request.url.host == 'prices.openfoodfacts.org') {
        expect(request.url.queryParameters['product_code'], '3017620422003');
        expect(request.url.queryParameters['order_by'], '-date');
        return http.Response(
          jsonEncode({
            'items': [
              {
                'price': 3.65,
                'currency': 'EUR',
                'date': '2026-07-31',
                'price_is_discounted': false,
                'location': {
                  'osm_brand': 'Auchan',
                  'osm_name': 'Auchan Sedan',
                  'osm_address_city': 'Sedan',
                  'osm_address_country_code': 'FR',
                },
              },
            ],
          }),
          200,
        );
      }
      expect(request.url.host, 'world.openfoodfacts.org');
      return http.Response(
        jsonEncode({
          'status': 'success',
          'product': {
            'product_name': 'Pâte à tartiner',
            'brands': 'Marque test, Autre marque',
            'quantity': '400 g',
            'image_front_small_url': 'https://example.com/product.jpg',
          },
        }),
        200,
      );
    });
    final service = ProductLookupService(client: client);

    final product = await service.lookup('3017620422003');

    expect(product.code, '3017620422003');
    expect(product.name, 'Pâte à tartiner');
    expect(product.brand, 'Marque test, Autre marque');
    expect(product.searchQuery, 'Pâte à tartiner Marque test 3017620422003');
    expect(product.marketPrices, hasLength(1));
    expect(product.marketPrices.single.price, 3.65);
    expect(product.marketPrices.single.storeName, 'Auchan');
    expect(product.marketPrices.single.city, 'Sedan');
    service.dispose();
  });

  test('accepte les références produit saisies manuellement', () async {
    expect(ProductLookupService.normalizeReference('45888'), '45888');
    expect(
      ProductLookupService.normalizeReference('  AB-123 / FR  '),
      'AB-123 / FR',
    );
    expect(ProductLookupService.normalizeReference('12'), isNull);
    expect(ProductLookupService.normalizeReference('   '), isNull);

    final service = ProductLookupService(
      client: MockClient((_) async => throw StateError('appel inattendu')),
    );
    final product = await service.lookup('45888');
    expect(product.code, '45888');
    expect(product.name, isNull);
    service.dispose();
  });

  test('conserve puis supprime un prix constaté localement', () async {
    final observation = PriceObservation(
      id: 'price-1',
      productCode: '3017620422003',
      productName: 'Produit test',
      storeName: 'Magasin test',
      price: 3.49,
      createdAt: DateTime(2026, 8, 3, 12),
    );

    await PriceHistoryService.add(const [], observation);
    final loaded = await PriceHistoryService.load();
    expect(loaded, hasLength(1));
    expect(loaded.single.price, 3.49);

    await PriceHistoryService.remove(loaded, observation.id);
    expect(await PriceHistoryService.load(), isEmpty);
  });

  test('crée exactement la recherche Idealo demandée', () {
    final uri = ProductSearchUriService.idealo('lunette');
    expect(uri.host, 'www.idealo.fr');
    expect(uri.path, '/prechcat.html');
    expect(uri.queryParameters['q'], 'lunette');
    expect(uri.toString(), 'https://www.idealo.fr/prechcat.html?q=lunette');
  });

  test('prépare la photo dans un formulaire Lens intégré', () {
    final service = VisualSearchService();

    final page = service.createUploadPage(
      bytes: const [0xFF, 0xD8, 0xFF, 0xD9],
      filename: 'produit.jpg',
    );

    expect(page, contains('https://lens.google.com/v3/upload'));
    expect(page, contains('name="encoded_image"'));
    expect(page, contains('multipart/form-data'));
    expect(page, contains('ucbcb=1'));
    expect(page, contains("document.getElementById('lens-form').submit()"));
  });
}
