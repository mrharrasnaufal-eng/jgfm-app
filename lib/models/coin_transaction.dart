/// Types of coin transactions.
enum CoinTransactionType {
  adReward,
  mission,
  dailyLogin,
  withdrawal,
  adminAdjust,
}

/// Model for a coin transaction (placeholder for future backend).
class CoinTransaction {
  final String id;
  final CoinTransactionType type;
  final int amount; // positive = earned, negative = spent
  final String description;
  final DateTime createdAt;

  CoinTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Whether this is an earning transaction.
  bool get isEarning => amount > 0;

  String get typeLabel {
    switch (type) {
      case CoinTransactionType.adReward:
        return 'Tonton Iklan';
      case CoinTransactionType.mission:
        return 'Misi Harian';
      case CoinTransactionType.dailyLogin:
        return 'Login Harian';
      case CoinTransactionType.withdrawal:
        return 'Penarikan';
      case CoinTransactionType.adminAdjust:
        return 'Penyesuaian';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'amount': amount,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
      };

  factory CoinTransaction.fromJson(Map<String, dynamic> json) {
    return CoinTransaction(
      id: json['id']?.toString() ?? '',
      type: CoinTransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => CoinTransactionType.adminAdjust,
      ),
      amount: json['amount'] as int? ?? 0,
      description: json['description']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
