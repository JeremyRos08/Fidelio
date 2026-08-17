import 'dart:convert';
import 'dart:typed_data';

import '../models/loyalty_models.dart';

class CardBackupException implements Exception {
  const CardBackupException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CardBackupService {
  CardBackupService._();

  static const format = 'fidelio-card-backup';
  static const schemaVersion = 1;

  static Uint8List createFile(Iterable<StoreLoyaltyCard> cards) {
    final document = <String, Object>{
      'format': format,
      'schemaVersion': schemaVersion,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'cards': cards.map((card) => card.toJson()).toList(),
    };
    return Uint8List.fromList(
      utf8.encode(const JsonEncoder.withIndent('  ').convert(document)),
    );
  }

  static List<StoreLoyaltyCard> readFile(List<int> bytes) {
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map) throw const CardBackupException('Fichier invalide.');
      final document = Map<String, dynamic>.from(decoded);
      if (document['format'] != format || document['schemaVersion'] != 1) {
        throw const CardBackupException(
          'Ce fichier n’est pas une sauvegarde Fidelio compatible.',
        );
      }
      final rawCards = document['cards'];
      if (rawCards is! List || rawCards.length > 1000) {
        throw const CardBackupException('Liste de cartes invalide.');
      }
      final cards = <StoreLoyaltyCard>[];
      final seen = <String>{};
      for (final rawCard in rawCards) {
        if (rawCard is! Map) {
          throw const CardBackupException('Une carte est endommagée.');
        }
        final card = StoreLoyaltyCard.fromJson(
          Map<String, dynamic>.from(rawCard),
        );
        if (card.storeName.trim().isEmpty ||
            card.storeName.length > 100 ||
            card.cardNumber.trim().isEmpty ||
            card.cardNumber.length > 512 ||
            card.notes.length > 2000) {
          throw const CardBackupException(
            'Une carte contient des informations invalides.',
          );
        }
        final key = _cardKey(card.storeName, card.cardNumber);
        if (seen.add(key)) cards.add(card);
      }
      return cards;
    } on CardBackupException {
      rethrow;
    } on Object {
      throw const CardBackupException(
        'Impossible de lire cette sauvegarde Fidelio.',
      );
    }
  }

  static String fileName(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return 'fidelio-sauvegarde-${date.year}-$month-$day.json';
  }

  static String _cardKey(String storeName, String cardNumber) =>
      '${_normalize(storeName)}|${_normalize(cardNumber)}';

  static String _normalize(String value) =>
      value.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toLowerCase();
}
