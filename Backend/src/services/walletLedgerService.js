const Ledger = require('../models/Ledger');
const Earnings = require('../models/Earnings');
const crypto = require('crypto');

class WalletLedgerService {
  /**
   * Post double entry transaction ledger log
   * Enforces strict ledger-first balances (Vol 10)
   */
  async postEntry({ userId, transactionId, debit = 0, credit = 0, reference, description, currency = 'INR', session = null }) {
    const txId = transactionId || crypto.randomUUID();

    // 1. Get current balance using lean option (Vol 14)
    const currentEarnings = await Earnings.findOne({ userId }).session(session).lean();
    const previousBalance = currentEarnings?.walletBalance || 0;

    // Calculate new running balance
    const runningBalance = previousBalance + credit - debit;

    // 2. Create Ledger entry
    const ledgerEntryArr = await Ledger.create(
      [
        {
          transactionId: txId,
          walletId: userId,
          debit: Number(debit),
          credit: Number(credit),
          runningBalance: Number(runningBalance),
          currency,
          reference,
          description,
        },
      ],
      { session }
    );

    // 3. Re-calculate verified balance from database ledger logs to avoid out-of-sync states
    const aggregateResult = await Ledger.aggregate([
      { $match: { walletId: userId } },
      {
        $group: {
          _id: null,
          totalCredits: { $sum: '$credit' },
          totalDebits: { $sum: '$debit' },
        },
      },
    ]).session(session);

    let verifiedBalance = runningBalance;
    if (aggregateResult && aggregateResult.length > 0) {
      verifiedBalance = aggregateResult[0].totalCredits - aggregateResult[0].totalDebits;
    }

    // 4. Update the wallet balance to match verified ledger sum
    const updatedEarnings = await Earnings.findOneAndUpdate(
      { userId },
      { 
        $set: { walletBalance: Number(verifiedBalance) }
      },
      { upsert: true, new: true, session }
    );

    return { ledgerEntry: ledgerEntryArr[0], earnings: updatedEarnings };
  }

  /**
   * Verify integrity of a user's wallet ledger
   */
  async verifyIntegrity(userId) {
    const aggregateResult = await Ledger.aggregate([
      { $match: { walletId: userId } },
      {
        $group: {
          _id: null,
          totalCredits: { $sum: '$credit' },
          totalDebits: { $sum: '$debit' },
        },
      },
    ]);

    const earnings = await Earnings.findOne({ userId }).lean();
    const docBalance = earnings?.walletBalance || 0;

    let verifiedBalance = 0;
    if (aggregateResult && aggregateResult.length > 0) {
      verifiedBalance = aggregateResult[0].totalCredits - aggregateResult[0].totalDebits;
    }

    return {
      userId,
      documentBalance: docBalance,
      verifiedLedgerBalance: verifiedBalance,
      isConsistent: Math.abs(docBalance - verifiedBalance) < 0.001,
    };
  }
}

module.exports = new WalletLedgerService();
