const ruleEngine = require('./ruleEngine');
const SystemSettings = require('../models/SystemSettings');
const featureFlags = require('../config/featureFlags');

class CommissionService {
  /**
   * Calculates commission amount based on project volume and premium status
   */
  async calculatePlatformCommission(userId, grossAmount) {
    if (!featureFlags.ENABLE_COMMISSIONS) {
      return { commissionAmount: 0, ratePercent: 0 };
    }

    try {
      // 1. Fetch user model details to evaluate premium flags
      const User = require('../models/User');
      const user = await User.findById(userId).lean();
      
      const context = {
        isPremium: user?.isPremium || false,
        kycVerified: user?.kycVerified || false,
        totalEarnings: user?.totalEarnings || 0,
      };

      // 2. Evaluate commissions using RuleEngine
      const rulesActions = await ruleEngine.evaluateUserRules(context);
      let ratePercent = rulesActions.commissionPercent || 10;

      // 3. Fallback check System settings database parameters (Vol 14)
      const commissionSetting = await SystemSettings.findOne({ key: 'COMMISSION_PERCENT' }).lean();
      if (commissionSetting && !user?.isPremium) {
        ratePercent = Number(commissionSetting.value);
      }

      const commissionAmount = (grossAmount * ratePercent) / 100;

      return {
        commissionAmount,
        ratePercent,
      };
    } catch (err) {
      console.error('⚠️ Commission calculations failed, using standard 10% rate:', err.message);
      return {
        commissionAmount: grossAmount * 0.10,
        ratePercent: 10,
      };
    }
  }
}

module.exports = new CommissionService();
