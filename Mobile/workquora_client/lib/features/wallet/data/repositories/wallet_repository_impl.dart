import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/app_exception.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/wallet_remote_datasource.dart';
import '../models/wallet_model.dart';

class WalletRepositoryImpl implements WalletRepository {
  WalletRepositoryImpl(this._remote);
  final WalletRemoteDataSource _remote;

  Future<Either<AppFailure, T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
        return Left(AppFailure.network());
      }
      final message = (e.response?.data is Map) ? e.response?.data['message'] as String? : null;
      return Left(AppFailure.fromMessage(message ?? 'Something went wrong.', statusCode: e.response?.statusCode));
    } catch (_) {
      return Left(AppFailure.fromMessage('Unexpected error.'));
    }
  }

  @override
  Future<Either<AppFailure, WalletModel>> getBalance() => _guard(() => _remote.getBalance());

  @override
  Future<Either<AppFailure, AddMoneyOrder>> createAddMoneyOrder(num amountRupees) =>
      _guard(() => _remote.createAddMoneyOrder(amountRupees));

  @override
  Future<Either<AppFailure, int>> verifyAddMoneyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) =>
      _guard(() => _remote.verifyAddMoneyPayment(
            razorpayOrderId: razorpayOrderId,
            razorpayPaymentId: razorpayPaymentId,
            razorpaySignature: razorpaySignature,
          ));

  @override
  Future<Either<AppFailure, int>> withdraw({required num amountRupees, required String bankAccountId, required String pin}) =>
      _guard(() => _remote.withdraw(amountRupees: amountRupees, bankAccountId: bankAccountId, pin: pin));

  @override
  Future<Either<AppFailure, PaginatedTransactions>> getTransactions({int page = 1, int limit = 20, String? type}) =>
      _guard(() => _remote.getTransactions(page: page, limit: limit, type: type));

  @override
  Future<Either<AppFailure, void>> addBankAccount({
    required String bankName,
    required String accountNumber,
    required String ifscCode,
    bool isPrimary = false,
  }) =>
      _guard(() => _remote.addBankAccount(
            bankName: bankName,
            accountNumber: accountNumber,
            ifscCode: ifscCode,
            isPrimary: isPrimary,
          ));
}
