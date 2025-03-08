/// Model representing a purchasable API request credit pack
class PaymentPackage {
  final String id;
  final String name;
  final int requestCount;
  final double price;
  final String description;
  final bool isBestValue;
  final String icon;
  final String? badgeText;
  final double valueRatio; // Higher is better value

  const PaymentPackage({
    required this.id,
    required this.name,
    required this.requestCount,
    required this.price,
    required this.description,
    this.isBestValue = false,
    required this.icon,
    this.badgeText,
    double? valueRatio,
  }) : valueRatio = valueRatio ?? (requestCount / price);
}
