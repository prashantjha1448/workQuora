class WalletTransactionModel {
  const WalletTransactionModel({
    required this.id,
    required this.type,
    required this.source,
    required this.amountPaise,
    required this.status,
    this.description = '',
    required this.createdAt,
    this.breakdown,
  });

  final String id;
  final String type; // 'credit' | 'debit'
  final String source; // 'add_money' | 'withdrawal' | ...
  final int amountPaise;
  final String status; // 'pending' | 'completed' | 'failed'
  final String description;
  final DateTime createdAt;
  final Map<String, dynamic>? breakdown;

  num get amountRupees => amountPaise / 100;
  bool get isCredit => type == 'credit';

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      id: (json['_id'] ?? '').toString(),
      type: json['type'] as String? ?? 'debit',
      source: json['source'] as String? ?? '',
      amountPaise: (json['amount'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'pending',
      description: json['description'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      breakdown: json['breakdown'] is Map ? Map<String, dynamic>.from(json['breakdown'] as Map) : null,
    );
  }
}
