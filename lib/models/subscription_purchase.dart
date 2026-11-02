class SubscriptionPurchase {
  const SubscriptionPurchase({
    required this.purchaseId,
    required this.status,
    required this.message,
  });

  factory SubscriptionPurchase.fromJson(Map<String, dynamic> json) {
    final purchaseId = json['purchaseId'];
    final status = json['status'];
    final message = json['message'];
    if (purchaseId is! String || status is! String || message is! String) {
      throw const FormatException(
        'The subscription payment response is invalid.',
      );
    }

    return SubscriptionPurchase(
      purchaseId: purchaseId,
      status: status,
      message: message,
    );
  }

  final String purchaseId;
  final String status;
  final String message;
}
