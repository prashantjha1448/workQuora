import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/wallet_model.dart';
import '../models/wallet_transaction_model.dart';

class AddMoneyOrder {
  const AddMoneyOrder({required this.orderId, required this.amountPaise, required this.currency, required this.keyId});
  final String orderId;
  final int amountPaise;
  final String currency;
  final String keyId;

  factory AddMoneyOrder.fromJson(Map<String, dynamic> json) => AddMoneyOrder(
        orderId: json['orderId'] as String,
        amountPaise: (json['amount'] as num).toInt(),
        currency: json['currency'] as String? ?? 'INR',
        keyId: json['keyId'] as String? ?? '',
      );
}

class PaginatedTransactions {
  const PaginatedTransactions({required this.transactions, required this.page, required this.totalPages});
  final List<WalletTransactionModel> transactions;
  final int page;
  final int totalPages;
  bool get hasMore => page < totalPages;
}

class WalletRemoteDataSource {
  WalletRemoteDataSource(this._dio);
  final Dio _dio;

  Future<WalletModel> getBalance() async {
    final res = await _dio.get(ApiEndpoints.walletBalance);
    return WalletModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  /// `amount` is in RUPEES (backend converts to paise internally).
  Future<AddMoneyOrder> createAddMoneyOrder(num amountRupees) async {
    final res = await _dio.post(ApiEndpoints.walletAddMoneyCreateOrder, data: {'amount': amountRupees});
    return AddMoneyOrder.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<int> verifyAddMoneyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    final res = await _dio.post(ApiEndpoints.walletAddMoneyVerify, data: {
      'razorpayOrderId': razorpayOrderId,
      'razorpayPaymentId': razorpayPaymentId,
      'razorpaySignature': razorpaySignature,
    });
    return (res.data['balance'] as num).toInt();
  }

  Future<int> withdraw({required num amountRupees, required String bankAccountId, required String pin}) async {
    final res = await _dio.post(ApiEndpoints.walletWithdraw, data: {
      'amount': amountRupees,
      'bankAccountId': bankAccountId,
      'pin': pin,
    });
    return (res.data['data']['newBalance'] as num).toInt();
  }

  Future<PaginatedTransactions> getTransactions({int page = 1, int limit = 20, String? type}) async {
    final res = await _dio.get(ApiEndpoints.walletTransactions, queryParameters: {
      'page': page,
      'limit': limit,
      if (type != null) 'type': type,
    });
    final data = res.data['data'] as Map<String, dynamic>;
    final list = data['transactions'] as List;
    return PaginatedTransactions(
      transactions: list.map((e) => WalletTransactionModel.fromJson(e as Map<String, dynamic>)).toList(),
      page: data['page'] as int? ?? page,
      totalPages: data['totalPages'] as int? ?? page,
    );
  }

  Future<void> addBankAccount({
    required String bankName,
    required String accountNumber,
    required String ifscCode,
    bool isPrimary = false,
  }) async {
    await _dio.post(ApiEndpoints.walletBankAccount, data: {
      'bankName': bankName,
      'accountNumber': accountNumber,
      'ifscCode': ifscCode,
      'isPrimary': isPrimary,
    });
  }
}
