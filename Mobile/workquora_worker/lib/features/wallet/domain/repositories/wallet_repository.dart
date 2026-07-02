import 'package:fpdart/fpdart.dart';
import '../../../../core/error/app_exception.dart';
import '../../data/datasources/wallet_remote_datasource.dart';
import '../../data/models/wallet_model.dart';

abstract class WalletRepository {
  Future<Either<AppFailure, WalletModel>> getBalance();
  Future<Either<AppFailure, AddMoneyOrder>> createAddMoneyOrder(num amountRupees);
  Future<Either<AppFailure, int>> verifyAddMoneyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  });
  Future<Either<AppFailure, int>> withdraw({required num amountRupees, required String bankAccountId, required String pin});
  Future<Either<AppFailure, PaginatedTransactions>> getTransactions({int page, int limit, String? type});
  Future<Either<AppFailure, void>> addBankAccount({
    required String bankName,
    required String accountNumber,
    required String ifscCode,
    bool isPrimary,
  });
}
