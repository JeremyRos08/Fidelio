import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/product_comparison_models.dart';

class PriceHistoryService {
  PriceHistoryService._();

  static const _storageKey = 'fidelio.product_price_history.v1';
  static const maxEntries = 80;

  static Future<List<PriceObservation>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_storageKey);
    if (encoded == null) return [];
    try {
      final decoded = jsonDecode(encoded) as List<dynamic>;
      final entries = decoded
          .whereType<Map>()
          .map(
            (item) =>
                PriceObservation.fromJson(Map<String, dynamic>.from(item)),
          )
          .where(
            (item) =>
                item.price > 0 &&
                item.storeName.isNotEmpty &&
                item.productCode.isNotEmpty,
          )
          .take(maxEntries)
          .toList();
      return entries;
    } on Object {
      return [];
    }
  }

  static Future<List<PriceObservation>> add(
    List<PriceObservation> current,
    PriceObservation observation,
  ) async {
    final updated = [observation, ...current].take(maxEntries).toList();
    await _save(updated);
    return updated;
  }

  static Future<List<PriceObservation>> remove(
    List<PriceObservation> current,
    String id,
  ) async {
    final updated = current.where((item) => item.id != id).toList();
    await _save(updated);
    return updated;
  }

  static Future<void> _save(List<PriceObservation> entries) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _storageKey,
      jsonEncode(entries.map((item) => item.toJson()).toList()),
    );
  }
}
