class ProductInfo {
  const ProductInfo({
    required this.code,
    this.name,
    this.brand,
    this.quantity,
    this.imageUrl,
    this.marketPrices = const [],
  });

  final String code;
  final String? name;
  final String? brand;
  final String? quantity;
  final String? imageUrl;
  final List<ProductMarketPrice> marketPrices;

  String get searchQuery {
    final primaryBrand = brand?.split(',').first.trim();
    return [?name, ?primaryBrand, code].join(' ');
  }
}

class ProductMarketPrice {
  const ProductMarketPrice({
    required this.price,
    required this.currency,
    required this.storeName,
    required this.date,
    this.city,
    this.isDiscounted = false,
  });

  final double price;
  final String currency;
  final String storeName;
  final String? city;
  final DateTime date;
  final bool isDiscounted;
}

class PriceObservation {
  const PriceObservation({
    required this.id,
    required this.productCode,
    required this.productName,
    required this.storeName,
    required this.price,
    required this.createdAt,
  });

  final String id;
  final String productCode;
  final String productName;
  final String storeName;
  final double price;
  final DateTime createdAt;

  Map<String, Object> toJson() => {
    'id': id,
    'productCode': productCode,
    'productName': productName,
    'storeName': storeName,
    'price': price,
    'createdAt': createdAt.toIso8601String(),
  };

  factory PriceObservation.fromJson(Map<String, dynamic> json) {
    return PriceObservation(
      id: json['id'] as String,
      productCode: json['productCode'] as String,
      productName: json['productName'] as String,
      storeName: json['storeName'] as String,
      price: (json['price'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class ComparisonDestination {
  const ComparisonDestination({
    required this.name,
    required this.domain,
    required this.iconKey,
    required this.uriBuilder,
  });

  final String name;
  final String domain;
  final String iconKey;
  final Uri Function(String query) uriBuilder;
}
