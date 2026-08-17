import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/product_comparison_models.dart';

class ProductLookupService {
  ProductLookupService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  static String? normalizeReference(String value) {
    final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.length < 3 || normalized.length > 40) return null;
    if (!RegExp(r'[A-Za-z0-9]').hasMatch(normalized)) return null;
    if (RegExp(r'[\r\n\t]').hasMatch(normalized)) return null;
    return normalized;
  }

  Future<ProductInfo> lookup(String code) async {
    final reference = normalizeReference(code) ?? code.trim();
    final compact = reference.replaceAll(RegExp(r'[\s-]'), '');
    if (!RegExp(r'^\d+$').hasMatch(compact) ||
        !const [8, 12, 13, 14].contains(compact.length)) {
      return ProductInfo(code: reference);
    }
    final normalized = compact;
    final results = await Future.wait<Object>([
      _lookupProduct(normalized),
      _lookupPrices(normalized),
    ]);
    final product = results[0] as ProductInfo;
    final prices = results[1] as List<ProductMarketPrice>;
    return ProductInfo(
      code: product.code,
      name: product.name,
      brand: product.brand,
      quantity: product.quantity,
      imageUrl: product.imageUrl,
      marketPrices: prices,
    );
  }

  Future<ProductInfo> _lookupProduct(String normalized) async {
    final uri = Uri.https(
      'world.openfoodfacts.org',
      '/api/v3.6/product/$normalized.json',
      {'fields': 'code,product_name,brands,quantity,image_front_small_url'},
    );
    try {
      final response = await _client
          .get(
            uri,
            headers: const {
              'User-Agent': 'Fidelio/1.0.0 (application mobile Fidelio)',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return ProductInfo(code: normalized);
      final decoded = jsonDecode(response.body);
      if (decoded is! Map || decoded['status'] != 'success') {
        return ProductInfo(code: normalized);
      }
      final rawProduct = decoded['product'];
      if (rawProduct is! Map) return ProductInfo(code: normalized);
      final product = Map<String, dynamic>.from(rawProduct);
      return ProductInfo(
        code: normalized,
        name: _text(product['product_name']),
        brand: _text(product['brands']),
        quantity: _text(product['quantity']),
        imageUrl: _text(product['image_front_small_url']),
      );
    } on Object {
      return ProductInfo(code: normalized);
    }
  }

  Future<List<ProductMarketPrice>> _lookupPrices(String normalized) async {
    final uri = Uri.https('prices.openfoodfacts.org', '/api/v1/prices', {
      'product_code': normalized,
      'size': '25',
      'order_by': '-date',
    });
    try {
      final response = await _client
          .get(
            uri,
            headers: const {
              'User-Agent': 'Fidelio/1.0.0 (application mobile Fidelio)',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return const [];
      final decoded = jsonDecode(response.body);
      if (decoded is! Map || decoded['items'] is! List) return const [];
      final prices = <ProductMarketPrice>[];
      final seen = <String>{};
      for (final rawItem in decoded['items'] as List) {
        if (rawItem is! Map) continue;
        final item = Map<String, dynamic>.from(rawItem);
        final rawPrice = item['price'];
        final currency = _text(item['currency']);
        final date = DateTime.tryParse(item['date']?.toString() ?? '');
        final rawLocation = item['location'];
        if (rawPrice is! num || currency == null || date == null) continue;
        if (rawPrice <= 0) continue;
        final location = rawLocation is Map
            ? Map<String, dynamic>.from(rawLocation)
            : const <String, dynamic>{};
        final countryCode = _text(location['osm_address_country_code']);
        if (countryCode != null && countryCode.toUpperCase() != 'FR') continue;
        final storeName =
            _text(location['osm_brand']) ??
            _text(location['osm_name']) ??
            'Magasin non précisé';
        final city = _text(location['osm_address_city']);
        final key =
            '${storeName.toLowerCase()}|${city?.toLowerCase()}|$rawPrice';
        if (!seen.add(key)) continue;
        prices.add(
          ProductMarketPrice(
            price: rawPrice.toDouble(),
            currency: currency,
            storeName: storeName,
            city: city,
            date: date,
            isDiscounted: item['price_is_discounted'] == true,
          ),
        );
        if (prices.length == 3) break;
      }
      prices.sort((a, b) => b.date.compareTo(a.date));
      return prices;
    } on Object {
      return const [];
    }
  }

  static String? _text(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  void dispose() => _client.close();
}
