const BusinessRule = require('../models/BusinessRule');
const featureFlags = require('../config/featureFlags');

class RuleEngine {
  constructor() {
    this.localRulesMap = new Map();
    // Pre-populate premium commission rules
    this.localRulesMap.set('premium_commission', {
      name: 'premium_commission',
      conditions: { isPremium: true },
      actions: { commissionPercent: 5 }, // 5% premium commission
    });
    this.localRulesMap.set('standard_commission', {
      name: 'standard_commission',
      conditions: { isPremium: false },
      actions: { commissionPercent: 10 }, // 10% standard commission
    });
  }

  /**
   * Evaluates rules for a given user context dynamically
   */
  async evaluateUserRules(userContext) {
    if (!featureFlags.ENABLE_RULES) {
      return { commissionPercent: 10 }; // standard fallback
    }

    try {
      // Look up DB rules if present, otherwise fallback to local configurations (Vol 14)
      const rules = await BusinessRule.find({}).lean();
      const activeRules = rules.length > 0 ? rules : Array.from(this.localRulesMap.values());

      let finalActions = { commissionPercent: 10 }; // default

      for (const rule of activeRules) {
        let isMatch = true;
        if (rule.conditions) {
          for (const key of Object.keys(rule.conditions)) {
            if (userContext[key] !== rule.conditions[key]) {
              isMatch = false;
              break;
            }
          }
        }
        if (isMatch && rule.actions) {
          finalActions = { ...finalActions, ...rule.actions };
        }
      }

      return finalActions;
    } catch (err) {
      console.error('⚠️ RuleEngine Evaluation error, using standard fallback:', err.message);
      return { commissionPercent: 10 };
    }
  }
}

module.exports = new RuleEngine();
