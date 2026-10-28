class AccountSession {
  const AccountSession({
    required this.user,
    required this.purchases,
    this.entitlement,
  });

  factory AccountSession.fromJson(Map<String, dynamic> json) {
    final userData = json['user'];
    if (userData is! Map<String, dynamic>) {
      throw const FormatException('The account response is invalid.');
    }

    final purchasesData = json['purchases'];
    final purchases = purchasesData is List
        ? purchasesData.whereType<Map<String, dynamic>>().toList(
            growable: false,
          )
        : <Map<String, dynamic>>[];
    final entitlementData = json['entitlement'];

    return AccountSession(
      user: AccountUser.fromJson(userData),
      purchases: purchases
          .map(PurchaseSummary.fromJson)
          .toList(growable: false),
      entitlement: entitlementData is Map<String, dynamic>
          ? ActiveEntitlement.fromJson(entitlementData)
          : null,
    );
  }

  final AccountUser user;
  final List<PurchaseSummary> purchases;
  final ActiveEntitlement? entitlement;
}

class AccountUser {
  const AccountUser({
    required this.id,
    required this.name,
    required this.email,
    required this.accountStatus,
  });

  factory AccountUser.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final email = json['email'];
    if (id is! String || email is! String) {
      throw const FormatException('The account profile is invalid.');
    }

    return AccountUser(
      id: id,
      name: json['name'] is String ? json['name'] as String : '',
      email: email,
      accountStatus: json['accountStatus'] is String
          ? json['accountStatus'] as String
          : 'ACTIVE',
    );
  }

  final String id;
  final String name;
  final String email;
  final String accountStatus;
}

class ActiveEntitlement {
  const ActiveEntitlement({
    required this.productName,
    required this.startsAt,
    required this.expiresAt,
  });

  factory ActiveEntitlement.fromJson(Map<String, dynamic> json) {
    final purchase = json['purchase'];
    return ActiveEntitlement(
      productName:
          purchase is Map<String, dynamic> && purchase['productName'] is String
          ? purchase['productName'] as String
          : 'Viewing pass',
      startsAt: DateTime.parse(json['startsAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }

  final String productName;
  final DateTime startsAt;
  final DateTime expiresAt;
}

class PurchaseSummary {
  const PurchaseSummary({
    required this.productName,
    required this.amountUgx,
    required this.currency,
    required this.status,
    required this.createdAt,
  });

  factory PurchaseSummary.fromJson(Map<String, dynamic> json) {
    final productName = json['productName'];
    final amountUgx = json['amountUgx'];
    final currency = json['currency'];
    final status = json['status'];
    final createdAt = json['createdAt'];
    if (productName is! String ||
        amountUgx is! int ||
        currency is! String ||
        status is! String ||
        createdAt is! String) {
      throw const FormatException('A purchase record is invalid.');
    }

    return PurchaseSummary(
      productName: productName,
      amountUgx: amountUgx,
      currency: currency,
      status: status,
      createdAt: DateTime.parse(createdAt),
    );
  }

  final String productName;
  final int amountUgx;
  final String currency;
  final String status;
  final DateTime createdAt;
}
