import 'package:flutter/material.dart';

class StoreLoyaltyCard {
  const StoreLoyaltyCard({
    required this.id,
    required this.storeName,
    required this.cardNumber,
    required this.colorValue,
    required this.codeFormat,
    required this.createdAt,
    this.notes = '',
    this.isFavorite = false,
    this.lastOpenedAt,
  });

  final String id;
  final String storeName;
  final String cardNumber;
  final int colorValue;
  final String codeFormat;
  final DateTime createdAt;
  final String notes;
  final bool isFavorite;
  final DateTime? lastOpenedAt;

  Color get color => Color(colorValue);

  StoreLoyaltyCard copyWith({
    String? storeName,
    String? cardNumber,
    int? colorValue,
    String? codeFormat,
    String? notes,
    bool? isFavorite,
    DateTime? lastOpenedAt,
  }) {
    return StoreLoyaltyCard(
      id: id,
      storeName: storeName ?? this.storeName,
      cardNumber: cardNumber ?? this.cardNumber,
      colorValue: colorValue ?? this.colorValue,
      codeFormat: codeFormat ?? this.codeFormat,
      createdAt: createdAt,
      notes: notes ?? this.notes,
      isFavorite: isFavorite ?? this.isFavorite,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
    );
  }

  Map<String, Object> toJson() => {
    'id': id,
    'storeName': storeName,
    'cardNumber': cardNumber,
    'colorValue': colorValue,
    'codeFormat': codeFormat,
    'createdAt': createdAt.toIso8601String(),
    'notes': notes,
    'isFavorite': isFavorite,
    if (lastOpenedAt != null) 'lastOpenedAt': lastOpenedAt!.toIso8601String(),
  };

  factory StoreLoyaltyCard.fromJson(Map<String, dynamic> json) {
    return StoreLoyaltyCard(
      id: json['id'] as String,
      storeName: json['storeName'] as String,
      cardNumber: json['cardNumber'] as String,
      colorValue: json['colorValue'] as int,
      codeFormat: json['codeFormat'] as String? ?? 'code128',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      notes: json['notes'] as String? ?? '',
      isFavorite: json['isFavorite'] as bool? ?? false,
      lastOpenedAt: DateTime.tryParse(json['lastOpenedAt'] as String? ?? ''),
    );
  }
}
