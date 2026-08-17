import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/loyalty_models.dart';

class BrandDirectoryService {
  BrandDirectoryService._();

  static final BrandDirectoryService instance = BrandDirectoryService._();

  static const _cacheKey = 'mes_cartes.brand_directory.nsi.v9';
  static final Uri _directoryUri = Uri.parse(
    'https://cdn.jsdelivr.net/npm/name-suggestion-index@8/'
    'dist/json/filtered/brands_keep.min.json',
  );

  static const List<String> popularBrands = [
    'E.Leclerc',
    'Carrefour',
    'Intermarché',
    'Lidl',
    'Auchan',
    'Super U',
    'Hyper U',
    'U Express',
    'Monoprix',
    'Franprix',
    'Aldi',
    'Casino',
    'Netto',
    'Picard',
    'Grand Frais',
    'Biocoop',
    'Naturalia',
    'La Vie Claire',
    'Action',
    'GiFi',
    'NOZ',
    'Stokomani',
    'La Foir’Fouille',
    'Decathlon',
    'Intersport',
    'Go Sport',
    'Sport 2000',
    'Fnac',
    'Darty',
    'Boulanger',
    'Cultura',
    'Micromania',
    'Sephora',
    'Marionnaud',
    'Nocibé',
    'Yves Rocher',
    'Kiko Milano',
    'IKEA',
    'Leroy Merlin',
    'Castorama',
    'Brico Dépôt',
    'Mr.Bricolage',
    'Bricomarché',
    'Conforama',
    'BUT',
    'Maisons du Monde',
    'Jardiland',
    'Truffaut',
    'Gamm vert',
    'Kiabi',
    'H&M',
    'Zara',
    'C&A',
    'Celio',
    'Jules',
    'Etam',
    'Gémo',
    'La Halle',
    'Primark',
    'Nike',
    'Adidas',
    'Courir',
    'JD Sports',
    'Norauto',
    'Feu Vert',
    'Roady',
    'TotalEnergies',
    'Shell',
    'Avia',
    'Pharmacie',
    'SNCF',
    'Air France',
    'Accor',
    'McDonald’s',
    'Burger King',
    'KFC',
    'Starbucks',
    'Columbus Café',
    'Paul',
    'Brioche Dorée',
  ];

  Future<List<String>>? _loading;

  Future<List<String>> loadBrands({bool forceRefresh = false}) {
    if (forceRefresh) _loading = null;
    return _loading ??= _loadBrands();
  }

  Future<List<String>> _loadBrands() async {
    final preferences = await SharedPreferences.getInstance();
    final cached = preferences.getStringList(_cacheKey);
    if (cached != null && cached.isNotEmpty) {
      return _mergeWithPopular(cached);
    }

    try {
      final response = await http
          .get(_directoryUri)
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return popularBrands;
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final entries = Map<String, dynamic>.from(decoded['keep'] as Map);
      final candidates = <({String name, int popularity})>[];

      for (final entry in entries.entries) {
        final separator = entry.key.indexOf('|');
        if (separator == -1) continue;
        final category = entry.key.substring(0, separator);
        if (!_isUsefulCategory(category)) continue;
        final name = entry.key.substring(separator + 1).trim();
        if (name.length < 2 || !RegExp(r'[A-Za-zÀ-ɏ]').hasMatch(name)) {
          continue;
        }
        candidates.add((name: name, popularity: entry.value as int));
      }

      candidates.sort((a, b) => b.popularity.compareTo(a.popularity));
      final names = candidates
          .map((entry) => entry.name)
          .toSet()
          .take(3000)
          .toList();
      await preferences.setStringList(_cacheKey, names);
      return _mergeWithPopular(names);
    } on Object {
      return popularBrands;
    }
  }

  List<String> _mergeWithPopular(Iterable<String> remote) {
    final seen = <String>{};
    final result = <String>[];
    for (final name in [...popularBrands, ...remote]) {
      if (seen.add(_normalize(name))) result.add(name);
    }
    return List.unmodifiable(result);
  }

  bool _isUsefulCategory(String category) {
    return category.startsWith('shop/') ||
        category == 'amenity/cafe' ||
        category == 'amenity/fast_food' ||
        category == 'amenity/restaurant' ||
        category == 'amenity/pharmacy' ||
        category == 'amenity/cinema' ||
        category == 'amenity/fuel';
  }

  static String? detectBrand(
    String scannedValue,
    Iterable<StoreLoyaltyCard> existingCards,
  ) {
    final lowerValue = scannedValue.toLowerCase();
    final uri = Uri.tryParse(scannedValue);
    if (uri != null && uri.host.isNotEmpty) {
      final host = uri.host.toLowerCase().replaceFirst('www.', '');
      for (final entry in _knownDomains.entries) {
        if (host == entry.key || host.endsWith('.${entry.key}')) {
          return entry.value;
        }
      }
      for (final brand in popularBrands) {
        final token = _normalize(brand);
        if (token.length >= 4 && _normalize(host).contains(token)) return brand;
      }
    }

    for (final entry in _knownDomains.entries) {
      if (lowerValue.contains(entry.key)) return entry.value;
    }

    final normalizedCode = _normalize(scannedValue);
    if (normalizedCode.length >= 8) {
      final prefixLength = normalizedCode.length >= 12 ? 6 : 4;
      final prefix = normalizedCode.substring(0, prefixLength);
      for (final card in existingCards) {
        final knownCode = _normalize(card.cardNumber);
        if (knownCode.length >= prefixLength && knownCode.startsWith(prefix)) {
          return card.storeName;
        }
      }
    }
    return null;
  }

  static const Map<String, String> _knownDomains = {
    'carrefour.fr': 'Carrefour',
    'e.leclerc': 'E.Leclerc',
    'leclercdrive.fr': 'E.Leclerc',
    'intermarche.com': 'Intermarché',
    'lidl.fr': 'Lidl',
    'auchan.fr': 'Auchan',
    'magasins-u.com': 'Super U',
    'monoprix.fr': 'Monoprix',
    'franprix.fr': 'Franprix',
    'aldi.fr': 'Aldi',
    'casino.fr': 'Casino',
    'picard.fr': 'Picard',
    'decathlon.fr': 'Decathlon',
    'fnac.com': 'Fnac',
    'darty.com': 'Darty',
    'boulanger.com': 'Boulanger',
    'sephora.fr': 'Sephora',
    'yves-rocher.fr': 'Yves Rocher',
    'ikea.com': 'IKEA',
    'leroymerlin.fr': 'Leroy Merlin',
    'castorama.fr': 'Castorama',
    'norauto.fr': 'Norauto',
    'feuvert.fr': 'Feu Vert',
    'mcdonalds.fr': 'McDonald’s',
    'starbucks.fr': 'Starbucks',
  };

  static String _normalize(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9à-ɏ]'), '');
}
