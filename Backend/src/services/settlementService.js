const Settlement = require('../models/Settlement');
const commissionService = require('./commissionService');
const invoiceService = require('./invoiceService');
const eventProvider = require('../events/eventProvider');
const featureFlags = require('../config/featureFlags');
const crypto = require('crypto');

class SettlementService {
  /**
   * Automatically process settlement details on milestone release events
   */
  async processMilestoneSettlement({ escrowId, milestoneId, amount, freelancerId, clientId, jobId, currency = 'INR', session = null }) {
    if (!featureFlags.ENABLE_SETTLEMENTS) {
      console.log('📡 SettlementService: Settlements disabled by feature flags.');
      return null;
    }

    // 1. Calculate platform commissions dynamically
    const { commissionAmount, ratePercent } = await commissionService.calculatePlatformCommission(freelancerId, amount);

    // Mock 18% service tax on platform commission
    const taxAmount = Math.round(commissionAmount * 0.18 * 100) / 100;
    const netAmountSettled = amount - commissionAmount - taxAmount;

    const stamp = Date.now();
    const settlementNumber = `SET-${stamp}-${crypto.randomBytes(4).toString('hex').toUpperCase()}`;

    // 2. Create Settlement entry
    const settlementArr = await Settlement.create(
      [
        {
          settlementNumber,
          freelancerId,
          jobId,
          grossAmount: amount,
          commissionDeducted: commissionAmount,
          taxDeducted: taxAmount,
          netAmountSettled,
          currency,
          status: 'completed',
          reference: escrowId,
        },
      ],
      { session }
    );

    // 3. Post double-entry commission debit ledger logs (Vol 10)
    const walletLedgerService = require('./walletLedgerService');
    if (commissionAmount > 0) {
      await walletLedgerService.postEntry({
        userId: freelancerId,
        transactionId: settlementArr[0]._id.toString(),
        debit: commissionAmount,
        reference: 'commission',
        description: `Platform commission fee of ${ratePercent}% deducted for Job ID: ${jobId}`,
        currency,
        session,
      });
    }

    // 4. Generate client tax invoice
    await invoiceService.generateInvoice({
      clientId,
      freelancerId,
      jobId,
      amount,
      commissionAmount,
      taxAmount,
      currency,
      session,
    });

    eventProvider.publish('SettlementCompleted', settlementArr[0]._id.toString());
    return settlementArr[0];
  }
}

// Hook consumer job listener directly into the local eventBus
const eventBus = require('../events/eventBus');
const settlementService = new SettlementService();

eventBus.on('MilestoneReleased', async (payload) => {
  console.log('📡 SettlementService: MilestoneReleased event listener triggered. Payload:', JSON.stringify(payload));
  try {
    const { runInTransaction } = require('../utils/transactionHelper');
    await runInTransaction(async (session) => {
      await settlementService.processMilestoneSettlement({
        escrowId: payload.escrowId,
        milestoneId: payload.milestoneId,
        amount: payload.amount,
        freelancerId: payload.freelancerId,
        clientId: payload.clientId,
        jobId: payload.jobId,
        currency: 'INR',
        session,
      });
    });
    console.log('📡 SettlementService: Event MilestoneReleased processed successfully.');
  } catch (err) {
    console.error('❌ SettlementService milestone released subscriber failure:', err.message);
  }
});

module.exports = settlementService;
