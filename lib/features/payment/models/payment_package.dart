/// Model representing a purchasable API request package
class PaymentPackage {
  final String id;
  final String name;
  final int requestCount;
  final double price;
  final String description;
  final bool isBestValue;

  const PaymentPackage({
    required this.id,
    required this.name,
    required this.requestCount,
    required this.price,
    required this.description,
    this.isBestValue = false,
  });
}
