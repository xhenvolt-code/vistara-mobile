class AccessProduct {
  const AccessProduct({
    required this.id,
    required this.name,
    required this.durationDays,
    required this.priceUgx,
  });

  factory AccessProduct.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final durationDays = json['durationDays'];
    final priceUgx = json['priceUgx'];
    if (id is! String ||
        name is! String ||
        durationDays is! int ||
        priceUgx is! int) {
      throw const FormatException('The access pass response is invalid.');
    }

    return AccessProduct(
      id: id,
      name: name,
      durationDays: durationDays,
      priceUgx: priceUgx,
    );
  }

  final String id;
  final String name;
  final int durationDays;
  final int priceUgx;
}
