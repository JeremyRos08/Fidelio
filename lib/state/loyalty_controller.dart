import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/loyalty_models.dart';
import '../services/brand_logo_service.dart';

class LoyaltyController extends ChangeNotifier {
  LoyaltyController() {
    unawaited(_loadData());
  }

  static const _cardsStorageKey = 'fidelio.loyalty_cards';
  static const _profileNameStorageKey = 'fidelio.profile_name';
  static const _profileFirstNameStorageKey = 'fidelio.profile_first_name';
  static const _profileLastNameStorageKey = 'fidelio.profile_last_name';
  static const _profileEmailStorageKey = 'fidelio.profile_email';
  static const _profileImageStorageKey = 'fidelio.profile_image';
  static const _hideCardPreviewsStorageKey =
      'fidelio.privacy.hide_card_previews';
  static const _legacyKeysToRemove = [
    'mes_cartes.store_offers',
    'mes_cartes.notifications_enabled',
    'mes_cartes.last_offer_refresh',
    'fidelio.offers.nearby_enabled',
    'fidelio.offers.nearby_radius_km',
    'fidelio.offers.last_latitude',
    'fidelio.offers.last_longitude',
    'fidelio.leclerc.offers.v2',
    'fidelio.leclerc.offers_date.v2',
    'fidelio.leclerc.drive_offers.v1',
    'intermarche_offers_cache_v1',
  ];

  final List<StoreLoyaltyCard> _cards = [];
  bool _isLoaded = false;
  String _profileFirstName = '';
  String _profileLastName = '';
  String _profileEmail = '';
  Uint8List? _profileImageBytes;
  bool _hideCardPreviews = false;

  bool get isLoaded => _isLoaded;
  String get profileFirstName => _profileFirstName;
  String get profileLastName => _profileLastName;
  String get profileEmail => _profileEmail;
  Uint8List? get profileImageBytes => _profileImageBytes;
  bool get hideCardPreviews => _hideCardPreviews;
  int get favoriteCount => _cards.where((card) => card.isFavorite).length;
  String get profileName => [
    _profileFirstName,
    _profileLastName,
  ].where((part) => part.isNotEmpty).join(' ');

  List<StoreLoyaltyCard> get cards {
    final sorted = [..._cards]
      ..sort((a, b) {
        if (a.isFavorite != b.isFavorite) return a.isFavorite ? -1 : 1;
        return a.storeName.toLowerCase().compareTo(b.storeName.toLowerCase());
      });
    return List.unmodifiable(sorted);
  }

  bool containsCard(String storeName, String number, {String? exceptId}) {
    final normalizedStore = _normalize(storeName);
    final normalizedNumber = _normalize(number);
    return _cards.any(
      (card) =>
          card.id != exceptId &&
          _normalize(card.storeName) == normalizedStore &&
          _normalize(card.cardNumber) == normalizedNumber,
    );
  }

  Future<void> _loadData() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final encoded = preferences.getString(_cardsStorageKey);
      if (encoded != null) {
        final decoded = jsonDecode(encoded) as List<dynamic>;
        _cards
          ..clear()
          ..addAll(
            decoded.map(
              (item) => StoreLoyaltyCard.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            ),
          );
      }
      _profileFirstName =
          preferences.getString(_profileFirstNameStorageKey)?.trim() ?? '';
      _profileLastName =
          preferences.getString(_profileLastNameStorageKey)?.trim() ?? '';
      _profileEmail =
          preferences.getString(_profileEmailStorageKey)?.trim() ?? '';
      _hideCardPreviews =
          preferences.getBool(_hideCardPreviewsStorageKey) ?? false;
      if (_profileFirstName.isEmpty && _profileLastName.isEmpty) {
        _migrateLegacyProfileName(
          preferences.getString(_profileNameStorageKey)?.trim() ?? '',
        );
      }
      final encodedProfileImage = preferences.getString(
        _profileImageStorageKey,
      );
      if (encodedProfileImage != null) {
        try {
          _profileImageBytes = base64Decode(encodedProfileImage);
        } on FormatException {
          _profileImageBytes = null;
        }
      }
      await Future.wait(_legacyKeysToRemove.map(preferences.remove));
    } on Object {
      _cards.clear();
    } finally {
      _isLoaded = true;
      notifyListeners();
      for (final card in _cards) {
        unawaited(BrandLogoService.cacheLogo(card.storeName));
      }
    }
  }

  Future<void> _saveCards() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_cards.map((card) => card.toJson()).toList());
    await preferences.setString(_cardsStorageKey, encoded);
  }

  Future<void> setProfile({
    required String firstName,
    required String lastName,
    required String email,
  }) async {
    _profileFirstName = firstName.trim();
    _profileLastName = lastName.trim();
    _profileEmail = email.trim();
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await Future.wait([
      preferences.setString(_profileFirstNameStorageKey, _profileFirstName),
      preferences.setString(_profileLastNameStorageKey, _profileLastName),
      preferences.setString(_profileEmailStorageKey, _profileEmail),
      preferences.remove(_profileNameStorageKey),
    ]);
  }

  Future<void> setProfileImage(Uint8List? bytes) async {
    _profileImageBytes = bytes;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    if (bytes == null) {
      await preferences.remove(_profileImageStorageKey);
    } else {
      await preferences.setString(_profileImageStorageKey, base64Encode(bytes));
    }
  }

  Future<void> setHideCardPreviews(bool value) async {
    _hideCardPreviews = value;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_hideCardPreviewsStorageKey, value);
  }

  void addCard({
    required String storeName,
    required String cardNumber,
    required Color color,
    required String codeFormat,
    String notes = '',
  }) {
    _cards.add(
      StoreLoyaltyCard(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        storeName: storeName.trim(),
        cardNumber: cardNumber.trim(),
        colorValue: color.toARGB32(),
        codeFormat: codeFormat,
        createdAt: DateTime.now(),
        notes: notes.trim(),
      ),
    );
    notifyListeners();
    unawaited(_saveCards());
    unawaited(BrandLogoService.cacheLogo(storeName.trim()));
  }

  void updateCard(StoreLoyaltyCard card) {
    final index = _cards.indexWhere((item) => item.id == card.id);
    if (index == -1) return;
    _cards[index] = card;
    notifyListeners();
    unawaited(_saveCards());
    unawaited(BrandLogoService.cacheLogo(card.storeName));
  }

  Future<int> importCards(Iterable<StoreLoyaltyCard> importedCards) async {
    final knownCards = _cards
        .map(
          (card) =>
              '${_normalize(card.storeName)}|${_normalize(card.cardNumber)}',
        )
        .toSet();
    var added = 0;
    var sequence = 0;
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    for (final card in importedCards) {
      final key =
          '${_normalize(card.storeName)}|${_normalize(card.cardNumber)}';
      if (!knownCards.add(key)) continue;
      _cards.add(
        StoreLoyaltyCard(
          id: 'import-${timestamp + sequence++}',
          storeName: card.storeName.trim(),
          cardNumber: card.cardNumber.trim(),
          colorValue: card.colorValue,
          codeFormat: card.codeFormat,
          createdAt: card.createdAt,
          notes: card.notes.trim(),
          isFavorite: card.isFavorite,
          lastOpenedAt: card.lastOpenedAt,
        ),
      );
      added++;
      unawaited(BrandLogoService.cacheLogo(card.storeName));
    }
    if (added == 0) return 0;
    notifyListeners();
    await _saveCards();
    return added;
  }

  void toggleFavorite(String id) {
    final index = _cards.indexWhere((item) => item.id == id);
    if (index == -1) return;
    _cards[index] = _cards[index].copyWith(
      isFavorite: !_cards[index].isFavorite,
    );
    notifyListeners();
    unawaited(_saveCards());
  }

  void markCardOpened(String id) {
    final index = _cards.indexWhere((item) => item.id == id);
    if (index == -1) return;
    _cards[index] = _cards[index].copyWith(lastOpenedAt: DateTime.now());
    notifyListeners();
    unawaited(_saveCards());
  }

  void removeCard(String id) {
    _cards.removeWhere((card) => card.id == id);
    notifyListeners();
    unawaited(_saveCards());
  }

  void clearAll() {
    _cards.clear();
    notifyListeners();
    unawaited(_saveCards());
  }

  void _migrateLegacyProfileName(String legacyName) {
    if (legacyName.isEmpty) return;
    final parts = legacyName.split(RegExp(r'\s+'));
    _profileFirstName = parts.first;
    _profileLastName = parts.skip(1).join(' ');
  }

  String _normalize(String value) =>
      value.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toLowerCase();
}
