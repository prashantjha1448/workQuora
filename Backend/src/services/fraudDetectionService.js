const FraudReport = require('../models/FraudReport');
const User = require('../models/User');
const featureFlags = require('../config/featureFlags');

class FraudDetectionService {
  /**
   * Evaluates real-time risk scores for users (Vol 11)
   */
  async evaluateRisk(userId, actionType, metadata = {}) {
    if (!featureFlags.ENABLE_FRAUD_DETECTION) {
      return { riskScore: 'LOW', flagTriggered: false };
    }

    try {
      const user = await User.findById(userId);
      if (!user) return { riskScore: 'LOW', flagTriggered: false };

      let riskScore = 'LOW';
      let ruleTriggered = null;
      let details = '';

      // 1. Check Multiple Accounts sharing session signatures
      if (metadata.ipAddress && metadata.userAgent) {
        const Session = require('../models/Session');
        // Find other active users sharing this exact IP and Agent profile
        const duplicates = await Session.find({
          ipAddress: metadata.ipAddress,
          userAgent: metadata.userAgent,
          userId: { $ne: userId },
        }).distinct('userId').lean();

        if (duplicates.length >= 2) {
          riskScore = 'HIGH';
          ruleTriggered = 'MULTIPLE_ACCOUNTS';
          details = `User sharing exact hardware session signatures with other active profiles: ${duplicates.join(', ')}`;
        }
      }

      // 2. Check Rapid Withdrawals (wallet abuse)
      if (actionType === 'WITHDRAWAL') {
        const Transaction = require('../models/Transaction');
        const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);
        
        // Count withdrawal transactions in the last hour
        const withdrawalCount = await Transaction.countDocuments({
          sender: userId,
          type: 'withdrawal',
          createdAt: { $gte: oneHourAgo },
        });

        if (withdrawalCount >= 3) {
          riskScore = 'CRITICAL';
          ruleTriggered = 'RAPID_WITHDRAWALS';
          details = `Suspicious behavior: User executed ${withdrawalCount} withdrawals within a single hour.`;
        }
      }

      // 3. Flags Critical lockout state matching failed logins
      if (user.failedLoginAttempts >= 5) {
        riskScore = 'CRITICAL';
        ruleTriggered = 'ACCOUNT_LOCK_MAX';
        details = 'Enforced lock limits reached. Suspension check recommended.';
      }

      // Write FraudReport if matches suspicious levels
      if (riskScore !== 'LOW') {
        await FraudReport.create({
          userId,
          ruleTriggered,
          riskScore,
          details,
          metadata,
        });

        // Suspend user automatically if risk is CRITICAL
        if (riskScore === 'CRITICAL') {
          user.isSuspended = true;
          user.suspensionReason = `Enforced auto-suspension: Fraud alert [${ruleTriggered}]`;
          await user.save();
          console.warn(`🚨 [FraudSuspension] Auto-suspended user ${userId} due to critical risk: ${ruleTriggered}`);
        }

        return { riskScore, flagTriggered: true, ruleTriggered };
      }

      return { riskScore, flagTriggered: false };
    } catch (err) {
      console.error('⚠️ FraudDetectionService: Risk evaluation error:', err.message);
      return { riskScore: 'LOW', flagTriggered: false };
    }
  }
}

module.exports = new FraudDetectionService();
