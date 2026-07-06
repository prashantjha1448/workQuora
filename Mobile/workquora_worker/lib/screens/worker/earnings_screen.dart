import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/wallet_provider.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/error_helper.dart';
import '../../core/utils/time_utils.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});
  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().fetchWallet();
      context.read<DashboardProvider>().fetchDashboard();
    });
  }

  Future<void> _refresh() async {
    await context.read<WalletProvider>().fetchWallet();
    await context.read<DashboardProvider>().fetchDashboard();
  }

  @override
  Widget build(BuildContext context) {
    final w = context.watch<WalletProvider>();
    final dash = context.watch<DashboardProvider>();
    final completedJobs = dash.completedTasks;
    final avgPerJob = completedJobs > 0 ? dash.allTimeIncome / completedJobs : 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Earnings'), backgroundColor: AppColors.background, elevation: 0, actions: [
        IconButton(icon: Icon(Icons.refresh, color: AppColors.textSecondary), onPressed: _refresh),
      ]),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [const Color(0xFF065F46), AppColors.primary.withOpacity(0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 24, offset: const Offset(0, 8))],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Wallet Balance', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Text(formatCurrency(w.wallet?['balance'] ?? 0), style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: -1)),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _openWithdrawSheet(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: const Center(
                          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.arrow_upward, color: Color(0xFF065F46), size: 16),
                            SizedBox(width: 6),
                            Text('Withdraw', style: TextStyle(color: Color(0xFF065F46), fontWeight: FontWeight.bold, fontSize: 13)),
                          ]),
                        ),
                      ),
                    ),
                  ),
                ]),
              ]),
            ),
            const SizedBox(height: 28),
            Row(children: [
              Expanded(child: _summaryCard('Today', formatCurrency(dash.todayIncome), AppColors.primary)),
              const SizedBox(width: 12),
              Expanded(child: _summaryCard('All Time', formatCurrency(dash.allTimeIncome), AppColors.primary)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _summaryCard('Completed Jobs', '$completedJobs', AppColors.info)),
              const SizedBox(width: 12),
              Expanded(child: _summaryCard('Avg / Job', formatCurrency(avgPerJob), AppColors.info)),
            ]),
            const SizedBox(height: 28),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Payment History', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
              if (w.isLoading) SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textSecondary)),
            ]),
            const SizedBox(height: 14),
            if (w.isLoading)
              Column(
                children: List.generate(
                  5,
                  (_) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Shimmer.fromColors(
                      baseColor: AppColors.surface,
                      highlightColor: AppColors.surface2,
                      child: Container(height: 64, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                ),
              )
            else if (w.transactions.isEmpty)
              Container(
                padding: const EdgeInsets.all(40),
                child: Column(children: [
                  Icon(Icons.currency_rupee, color: AppColors.textSecondary, size: 56),
                  const SizedBox(height: 12),
                  Text('No earnings yet', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Text('Complete jobs to earn money', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ]),
              )
            else
              ...w.transactions.map((tx) {
                final isCredit = (tx['type'] ?? '').toString().toLowerCase() == 'credit';
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                  child: Row(children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(color: (isCredit ? AppColors.primary : AppColors.error).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Icon(isCredit ? Icons.arrow_downward : Icons.arrow_upward, color: isCredit ? AppColors.primary : AppColors.error, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(tx['description'] ?? (isCredit ? 'Job Payment' : 'Withdrawal'), style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(formatDate(tx['createdAt']?.toString()), style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      ]),
                    ),
                    Text('${isCredit ? '+' : '-'}${formatCurrency(tx['amount'] ?? 0)}', style: TextStyle(color: isCredit ? AppColors.primary : AppColors.error, fontWeight: FontWeight.bold, fontSize: 15)),
                  ]),
                );
              }),
          ]),
        ),
      ),
    );
  }

  Widget _summaryCard(String label, String val, Color color) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Text(val, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900), overflow: TextOverflow.ellipsis),
        ]),
      );

  void _openWithdrawSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _WithdrawSheet(),
    );
  }
}

// walletController.js's `withdraw` expects { amount (INR, not paise), bankAccountId, pin }.
class _WithdrawSheet extends StatefulWidget {
  const _WithdrawSheet();
  @override
  State<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<_WithdrawSheet> {
  final _amountCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  String? _selectedBankId;
  bool _submitting = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(List<dynamic> bankAccounts) async {
    final amount = num.tryParse(_amountCtrl.text.trim());
    final pin = _pinCtrl.text.trim();

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Enter a valid amount'), backgroundColor: AppColors.error));
      return;
    }
    if (pin.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Enter your 4-digit withdrawal PIN'), backgroundColor: AppColors.error));
      return;
    }
    if (_selectedBankId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Select a bank account'), backgroundColor: AppColors.error));
      return;
    }

    setState(() => _submitting = true);
    try {
      await DioClient.instance.dio.post(ApiConstants.withdraw, data: {
        'amount': amount,
        'bankAccountId': _selectedBankId,
        'pin': pin,
      });
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Withdrawal request submitted'), backgroundColor: AppColors.success));
      await context.read<WalletProvider>().fetchWallet();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHelper.extract(e)), backgroundColor: AppColors.error));
    }
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>().wallet;
    final bankAccounts = (wallet?['bankAccounts'] as List?) ?? [];

    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Withdraw Funds', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        AppTextField(controller: _amountCtrl, hint: 'Amount (₹)', icon: Icons.currency_rupee, keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        if (bankAccounts.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Text('No bank account linked yet. Add one during KYC to withdraw.', style: TextStyle(color: AppColors.warning, fontSize: 12)),
          )
        else
          Container(
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
            child: DropdownButtonFormField<String>(
              value: _selectedBankId,
              dropdownColor: AppColors.surface,
              decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4)),
              hint: Text('Select bank account', style: TextStyle(color: AppColors.textSecondary)),
              items: bankAccounts.map<DropdownMenuItem<String>>((b) {
                final id = (b['_id'] ?? '').toString();
                return DropdownMenuItem(value: id, child: Text('${b['bankName'] ?? 'Bank'} • ${b['accountEnding'] ?? ''}', style: TextStyle(color: AppColors.textPrimary)));
              }).toList(),
              onChanged: (v) => setState(() => _selectedBankId = v),
            ),
          ),
        const SizedBox(height: 12),
        AppTextField(controller: _pinCtrl, hint: '4-digit Withdrawal PIN', icon: Icons.lock_outline, obscure: true, keyboardType: TextInputType.number),
        const SizedBox(height: 20),
        AppButton(label: 'Confirm Withdrawal', loading: _submitting, onPressed: () => _submit(bankAccounts)),
      ]),
    );
  }
}
