import 'brand_logo_service.dart';

class BrandPromotionPage {
  const BrandPromotionPage({
    required this.uri,
    required this.allowedHostSuffixes,
    this.alternativeUris = const [],
    this.storeHomeUri,
    this.isDirectPromotionPage = true,
    this.isAddressSuggested = false,
  });

  final Uri uri;
  final Set<String> allowedHostSuffixes;
  final List<Uri> alternativeUris;
  final Uri? storeHomeUri;
  final bool isDirectPromotionPage;
  final bool isAddressSuggested;

  bool allowsHost(String host) {
    final normalized = host.toLowerCase();
    return allowedHostSuffixes.any(
      (suffix) => normalized == suffix || normalized.endsWith('.$suffix'),
    );
  }
}

class BrandPromotionService {
  BrandPromotionService._();

  static BrandPromotionPage? pageFor(String storeName) {
    final key = _normalize(storeName);
    final promotionPage = _pages[key];
    if (promotionPage != null) return promotionPage;

    final knownDomain = BrandLogoService.officialDomain(storeName);
    if (knownDomain != null) {
      return BrandPromotionPage(
        uri: Uri.https('www.$knownDomain', '/'),
        allowedHostSuffixes: {knownDomain},
        isDirectPromotionPage: false,
      );
    }

    if (key.length < 2 || !RegExp(r'[a-z]').hasMatch(key)) return null;
    final frenchDomain = '$key.fr';
    final internationalDomain = '$key.com';
    return BrandPromotionPage(
      uri: Uri.https('www.$frenchDomain', '/'),
      alternativeUris: [Uri.https('www.$internationalDomain', '/')],
      allowedHostSuffixes: {frenchDomain, internationalDomain},
      isDirectPromotionPage: false,
      isAddressSuggested: true,
    );
  }

  static final Map<String, BrandPromotionPage> _pages = {
    for (final alias in const ['eleclerc', 'leclerc'])
      alias: _page('https://www.e.leclerc/prospectus?type=00', const {
        'e.leclerc',
      }),
    for (final alias in const [
      'carrefour',
      'carrefourmarket',
      'carrefourcity',
      'carrefourexpress',
      'carrefourcontact',
    ])
      alias: _page('https://www.carrefour.fr/catalogue', const {
        'carrefour.fr',
      }),
    'intermarche': _page(
      'https://www.intermarche.com/enseigne/bons-plans/promos',
      const {'intermarche.com'},
    ),
    'lidl': _page('https://www.lidl.fr/c/catalogues-en-ligne/s10017753', const {
      'lidl.fr',
    }),
    'auchan': _page('https://www.auchan.fr/catalogue/', const {'auchan.fr'}),
    for (final alias in const ['superu', 'hyperu', 'uexpress', 'magasinsu'])
      alias: _page('https://www.magasins-u.com/promotions', const {
        'magasins-u.com',
      }),
    'monoprix': _page(
      'https://www.monoprix.fr/offres-promotionnelles.html',
      const {'monoprix.fr'},
    ),
    'aldi': _page('https://www.aldi.fr/arrivages-semaine-actuelle.html', const {
      'aldi.fr',
    }),
    'decathlon': _page(
      'https://www.decathlon.fr/boutiques/bons-plans-des-marques',
      const {'decathlon.fr'},
    ),
    for (final alias in const ['fnac', 'fnacplus'])
      alias: _page(
        'https://www.fnac.com/Bons-plans/Toutes-nos-offres/nsh218554/w-4',
        const {'fnac.com'},
      ),
    'leroymerlin': _page(
      'https://www.leroymerlin.fr/produits/bonnes-affaires/',
      const {'leroymerlin.fr'},
    ),
    'castorama': _page(
      'https://www.castorama.fr/promotions/cat_id_0001464.cat',
      const {'castorama.fr'},
    ),
    'bricodepot': _page('https://www.bricodepot.fr/catalogues/', const {
      'bricodepot.fr',
    }),
    'kiabi': _page('https://www.kiabi.com/lp/bons-plans', const {'kiabi.com'}),
    'sephora': _page('https://www.sephora.fr/promotion-exclu-web-all/', const {
      'sephora.fr',
    }),
  };

  static BrandPromotionPage _page(String url, Set<String> hosts) {
    final pageUri = Uri.parse(url);
    final homeHost = pageUri.host.startsWith('www.')
        ? pageUri.host
        : 'www.${hosts.first}';
    return BrandPromotionPage(
      uri: pageUri,
      allowedHostSuffixes: hosts,
      storeHomeUri: Uri.https(homeHost, '/'),
    );
  }

  static String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9à-ÿ]'), '')
      .replaceAll(RegExp('[àáâãäå]'), 'a')
      .replaceAll(RegExp('[èéêë]'), 'e')
      .replaceAll(RegExp('[ìíîï]'), 'i')
      .replaceAll(RegExp('[òóôõö]'), 'o')
      .replaceAll(RegExp('[ùúûü]'), 'u')
      .replaceAll('ç', 'c')
      .replaceAll('œ', 'oe');
}
