import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../core/error/app_exception.dart';
import '../data/wallet_providers.dart';
import 'wallet_controller.dart';

class AddMoneyState {
  const AddMoneyState({
    this.isCreatingOrder = false,
    this.isVerifying = false,
    this.success = false,
    this.error,
  });

  final bool isCreatingOrder;
  final bool isVerifying;
  final bool success;
  final AppFailure? error;

  bool get isBusy => isCreatingOrder || isVerifying;

  AddMoneyState copyWith({
    bool? isCreatingOrder,
    bool? isVerifying,
    bool? success,
    AppFailure? error,
    bool clearError = false,
  }) {
    return AddMoneyState(
      isCreatingOrder: isCreatingOrder ?? this.isCreatingOrder,
      isVerifying: isVerifying ?? this.isVerifying,
      success: success ?? this.success,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AddMoneyController extends Notifier<AddMoneyState> {
  late final Razorpay _razorpay;

  @override
  AddMoneyState build() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
    ref.onDispose(_razorpay.clear);
    return const AddMoneyState();
  }

  Future<void> startAddMoney(num amountRupees) async {
    state = state.copyWith(isCreatingOrder: true, clearError: true);
    final repo = ref.read(walletRepositoryProvider);
    final result = await repo.createAddMoneyOrder(amountRupees);

    result.match(
      (failure) => state = state.copyWith(isCreatingOrder: false, error: failure),
      (order) {
        state = state.copyWith(isCreatingOrder: false);
        try {
          _razorpay.open({
            'key': order.keyId,
            'amount': order.amountPaise,
            'currency': order.currency,
            'name': 'WorkQuora',
            'description': 'Add money to wallet',
            'order_id': order.orderId,
            'theme': {'color': '#1E00A9'},
          });
        } catch (_) {
          state = state.copyWith(error: AppFailure.fromMessage('Could not open the payment screen.'));
        }
      },
    );
  }

  // Razorpay's event handlers are synchronously-typed — kick off the async
  // verification as fire-and-forget rather than making this method itself async.
  void _onPaymentSuccess(PaymentSuccessResponse response) {
    state = state.copyWith(isVerifying: true, clearError: true);
    _verify(response);
  }

  Future<void> _verify(PaymentSuccessResponse response) async {
    final repo = ref.read(walletRepositoryProvider);
    final result = await repo.verifyAddMoneyPayment(
      razorpayOrderId: response.orderId ?? '',
      razorpayPaymentId: response.paymentId ?? '',
      razorpaySignature: response.signature ?? '',
    );
    result.match(
      (failure) => state = state.copyWith(isVerifying: false, error: failure),
      (_) {
        state = state.copyWith(isVerifying: false, success: true);
        ref.read(walletControllerProvider.notifier).refresh();
      },
    );
  }

  void _onPaymentError(PaymentFailureResponse response) {
    state = state.copyWith(
      error: AppFailure.fromMessage(response.message ?? 'Payment was cancelled or failed.'),
    );
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    state = state.copyWith(
      error: AppFailure.fromMessage('${response.walletName ?? 'External wallet'} is not supported.'),
    );
  }

  void reset() => state = const AddMoneyState();
}

final addMoneyControllerProvider = NotifierProvider<AddMoneyController, AddMoneyState>(
  AddMoneyController.new,
);
