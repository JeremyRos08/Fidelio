import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class BrandLogoService {
  BrandLogoService._();

  static final CacheManager cacheManager = CacheManager(
    Config(
      'fidelio_brand_logos_hd_v2',
      stalePeriod: const Duration(days: 3650),
      maxNrOfCacheObjects: 250,
    ),
  );

  static Uri? logoUri(String storeName) {
    final key = _normalize(storeName);
    final highResolutionFile = _highResolutionLogos[key];
    if (highResolutionFile != null) {
      return Uri.https(
        'raw.githubusercontent.com',
        '/openfoodfacts/brand-images/main/xx/stores/$highResolutionFile',
      );
    }
    final domain = _domains[key];
    if (domain == null) return null;
    return Uri.https('www.google.com', '/s2/favicons', {
      'domain': domain,
      'sz': '256',
    });
  }

  static String? officialDomain(String storeName) {
    return _domains[_normalize(storeName)];
  }

  /// Télécharge le logo une seule fois et le conserve pour l'affichage
  /// hors connexion. Une erreur réseau ne doit jamais empêcher la carte
  /// d'être enregistrée.
  static Future<void> cacheLogo(String storeName) async {
    final uri = logoUri(storeName);
    if (uri == null) return;
    try {
      await cacheManager.getSingleFile(uri.toString());
    } on Object {
      // Les initiales de l'enseigne restent disponibles en secours.
    }
  }

  static String initials(String storeName) {
    final words = storeName
        .trim()
        .split(RegExp(r'[\s.&+_-]+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      final end = words.first.length >= 2 ? 2 : 1;
      return words.first.substring(0, end).toUpperCase();
    }
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }

  static const Map<String, String> _highResolutionLogos = {
    'eleclerc': 'e-leclerc.png',
    'leclerc': 'e-leclerc.png',
    'carrefour': 'carrefour.png',
    'carrefourmarket': 'carrefour-market.png',
    'carrefourcity': 'carrefour-city.png',
    'intermarche': 'intermarche.png',
    'lidl': 'lidl.png',
    'auchan': 'auchan.png',
    'superu': 'super-u.png',
    'hyperu': 'hyper-u-2009.png',
    'uexpress': 'u-express-2009.png',
    'monoprix': 'monoprix.png',
    'franprix': 'franprix.png',
    'aldi': 'aldi.png',
    'casino': 'casino.png',
    'netto': 'netto.png',
    'picard': 'picard.png',
    'grandfrais': 'grand-frais.png',
    'biocoop': 'biocoop.png',
    'naturalia': 'naturalia.png',
    'lavieclaire': 'la-vie-claire.png',
    'action': 'action.png',
    'gifi': 'gifi.png',
    'noz': 'noz.png',
    'stokomani': 'stokomani.png',
    'lafoirfouille': 'la-foirfouille.png',
    'decathlon': 'decathlon.png',
    'intersport': 'intersport.png',
    'gosport': 'go-sport.png',
    'sport2000': 'sport-2000.png',
    'jdsports': 'jd-sports.png',
    'nike': 'nike.png',
    'adidas': 'adidas.png',
    'fnac': 'fnac.png',
    'fnacplus': 'fnac.png',
    'darty': 'darty.png',
    'boulanger': 'boulanger.png',
    'cultura': 'cultura.png',
    'micromania': 'micromania.png',
    'sephora': 'sephora.png',
    'marionnaud': 'marionnaud.png',
    'nocibe': 'nocibe.png',
    'yvesrocher': 'yves-rocher.png',
    'kikomilano': 'kiko-milano.png',
    'kiko': 'kiko-milano.png',
    'ikea': 'ikea.png',
    'leroymerlin': 'leroy-merlin.png',
    'castorama': 'castorama.png',
    'bricodepot': 'brico-depot.png',
    'mrbricolage': 'mr-bricolage.png',
    'bricomarche': 'bricomarche.png',
    'conforama': 'conforama.png',
    'but': 'but.png',
    'maisonsdumonde': 'maisons-du-monde.png',
    'jardiland': 'jardiland.png',
    'truffaut': 'truffaut.png',
    'gammvert': 'gamm-vert.png',
    'kiabi': 'kiabi.png',
    'hm': 'h-m.png',
    'zara': 'zara.png',
    'ca': 'c-a.png',
    'celio': 'celio.png',
    'jules': 'jules.png',
    'etam': 'etam.png',
    'lahalle': 'la-halle.png',
    'primark': 'primark.png',
    'avia': 'avia.png',
    'shell': 'shell.png',
    'mcdonalds': 'mcdonalds.png',
    'burgerking': 'burger-king.png',
    'kfc': 'kfc.png',
    'starbucks': 'starbucks.png',
    'paul': 'paul.png',
    'briochedoree': 'brioche-doree.png',
  };

  static const Map<String, String> _domains = {
    'eleclerc': 'e.leclerc',
    'leclerc': 'e.leclerc',
    'carrefour': 'carrefour.fr',
    'carrefourmarket': 'carrefour.fr',
    'carrefourcity': 'carrefour.fr',
    'intermarche': 'intermarche.com',
    'lidl': 'lidl.fr',
    'auchan': 'auchan.fr',
    'superu': 'magasins-u.com',
    'hyperu': 'magasins-u.com',
    'uexpress': 'magasins-u.com',
    'monoprix': 'monoprix.fr',
    'franprix': 'franprix.fr',
    'aldi': 'aldi.fr',
    'casino': 'casino.fr',
    'netto': 'netto.fr',
    'picard': 'picard.fr',
    'grandfrais': 'grandfrais.com',
    'biocoop': 'biocoop.fr',
    'naturalia': 'naturalia.fr',
    'lavieclaire': 'lavieclaire.com',
    'action': 'action.com',
    'gifi': 'gifi.fr',
    'noz': 'nozarrivages.com',
    'stokomani': 'stokomani.fr',
    'lafoirfouille': 'lafoirfouille.fr',
    'decathlon': 'decathlon.fr',
    'intersport': 'intersport.fr',
    'gosport': 'go-sport.com',
    'sport2000': 'sport2000.fr',
    'courir': 'courir.com',
    'jdsports': 'jdsports.fr',
    'nike': 'nike.com',
    'adidas': 'adidas.fr',
    'fnac': 'fnac.com',
    'fnacplus': 'fnac.com',
    'darty': 'darty.com',
    'boulanger': 'boulanger.com',
    'cultura': 'cultura.com',
    'micromania': 'micromania.fr',
    'sephora': 'sephora.fr',
    'marionnaud': 'marionnaud.fr',
    'nocibe': 'nocibe.fr',
    'yvesrocher': 'yves-rocher.fr',
    'kikomilano': 'kikocosmetics.com',
    'kiko': 'kikocosmetics.com',
    'ikea': 'ikea.com',
    'leroymerlin': 'leroymerlin.fr',
    'castorama': 'castorama.fr',
    'bricodepot': 'bricodepot.fr',
    'mrbricolage': 'mr-bricolage.fr',
    'bricomarche': 'bricomarche.com',
    'conforama': 'conforama.fr',
    'but': 'but.fr',
    'maisonsdumonde': 'maisonsdumonde.com',
    'jardiland': 'jardiland.com',
    'truffaut': 'truffaut.com',
    'gammvert': 'gammvert.fr',
    'kiabi': 'kiabi.com',
    'hm': 'hm.com',
    'zara': 'zara.com',
    'ca': 'c-and-a.com',
    'celio': 'celio.com',
    'jules': 'jules.com',
    'etam': 'etam.com',
    'gemo': 'gemo.fr',
    'lahalle': 'lahalle.com',
    'primark': 'primark.com',
    'norauto': 'norauto.fr',
    'feuvert': 'feuvert.fr',
    'roady': 'roady.fr',
    'totalenergies': 'totalenergies.fr',
    'shell': 'shell.fr',
    'avia': 'avia-france.fr',
    'mcdonalds': 'mcdonalds.fr',
    'burgerking': 'burgerking.fr',
    'kfc': 'kfc.fr',
    'starbucks': 'starbucks.fr',
    'paul': 'paul.fr',
    'briochedoree': 'briochedoree.fr',
  };

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
