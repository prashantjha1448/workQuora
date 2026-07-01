/// Backend stores balance in paise — see memory notes: a 100x rupee/paise
/// bug was found and fixed during this project's backend review. Client
/// NEVER does its own rupee<->paise math; it only ever displays
/// `formattedBalance` (already converted server-side) and sends rupee
/// amounts up for add-money/withdraw (the server converts to paise).
class WalletModel {
  const WalletModel({
    required this.balancePaise,
    required this.formattedBalance,
    this.currency = 'INR',
    this.bankAccounts = const [],
  });

  final int balancePaise;
  final num formattedBalance;
  final String currency;
  final List<BankAccountModel> bankAccounts;

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      balancePaise: (json['balance'] as num?)?.toInt() ?? 0,
      formattedBalance: json['formattedBalance'] as num? ?? 0,
      currency: json['currency'] as String? ?? 'INR',
      bankAccounts: (json['bankAccounts'] as List?)
              ?.map((e) => BankAccountModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

class BankAccountModel {
  const BankAccountModel({
    required this.id,
    required this.bankName,
    required this.accountEnding,
    this.isPrimary = false,
  });

  final String id;
  final String bankName;

  /// Already masked server-side as "XXXX1234" — never the full number.
  final String accountEnding;
  final bool isPrimary;

  factory BankAccountModel.fromJson(Map<String, dynamic> json) {
    return BankAccountModel(
      id: (json['_id'] ?? '').toString(),
      bankName: json['bankName'] as String? ?? 'Bank Account',
      accountEnding: json['accountEnding'] as String? ?? '',
      isPrimary: json['isPrimary'] as bool? ?? false,
    );
  }
}
