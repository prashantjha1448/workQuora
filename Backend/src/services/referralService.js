const Referral = require('../models/Referral');
const walletLedgerService = require('./walletLedgerService');
const eventProvider = require('../events/eventProvider');
const featureFlags = require('../config/featureFlags');

class ReferralService {
  /**
   * Register a new referral link invite mapping
   */
  async registerReferral(referrerId, referredUserId) {
    if (!featureFlags.ENABLE_REFERRALS) {
      return null;
    }

    const ref = await Referral.create({
      referrerId,
      referredUserId,
      status: 'pending',
    });

    console.log(`🔗 Referral Registered: User ${referredUserId} referred by ${referrerId}`);
    return ref;
  }

  /**
   * Reward the referrer once the referred user completes a task
   */
  async rewardReferrer(referredUserId, session = null) {
    if (!featureFlags.ENABLE_REFERRALS) return;

    const referral = await Referral.findOne({ referredUserId, status: 'pending' }).session(session);
    if (!referral) return; // No pending referral found

    referral.status = 'rewarded';
    referral.referredUserMilestoneCompleted = true;
    await referral.save({ session });

    // Credit referrer wallet with ₹100 invite bonus (post double-entry credit ledger)
    await walletLedgerService.postEntry({
      userId: referral.referrerId,
      transactionId: referral._id.toString(),
      credit: referral.rewardAmount,
      reference: 'referral',
      description: `Referral invite reward credited for referring user ${referredUserId}`,
      currency: 'INR',
      session,
    });

    eventProvider.publish('ReferralRewarded', referral._id.toString());
    console.log(`🎁 Referral Rewarded: Credited ₹${referral.rewardAmount} to referrer ${referral.referrerId}`);
  }
}

// Hook milestone release listener to award referral payouts
const eventBus = require('../events/eventBus');
const referralService = new ReferralService();

eventBus.on('MilestoneReleased', async (payload) => {
  try {
    const { runInTransaction } = require('../utils/transactionHelper');
    await runInTransaction(async (session) => {
      // Check if freelancer or client was referred, and reward their referrer on milestone completion
      await referralService.rewardReferrer(payload.freelancerId, session);
    });
  } catch (err) {
    console.error('❌ Referral reward event execution failure:', err.message);
  }
});

module.exports = referralService;
