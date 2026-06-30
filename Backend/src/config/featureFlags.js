/**
 * Centralized Feature Flag Registry for WorkQuora (Phase 3, 4 & 5 Compliance)
 * Exposes configuration flags from environment variables to allow enabling/disabling modules dynamically.
 */

const getFlag = (envVar, defaultValue) => {
  const val = process.env[envVar];
  if (val === undefined) return defaultValue;
  return val === 'true' || val === '1';
};

const featureFlags = {
  ENABLE_AI: getFlag('ENABLE_AI', false),
  ENABLE_CACHE: getFlag('ENABLE_CACHE', true),
  ENABLE_STORAGE: getFlag('ENABLE_STORAGE', true),
  ENABLE_ELASTIC: getFlag('ENABLE_ELASTIC', false),
  ENABLE_SMS: getFlag('ENABLE_SMS', false),
  ENABLE_EMAIL: getFlag('ENABLE_EMAIL', false),
  ENABLE_NOTIFICATIONS: getFlag('ENABLE_NOTIFICATIONS', true),
  ENABLE_RECOMMENDATIONS: getFlag('ENABLE_RECOMMENDATIONS', true),
  ENABLE_SEARCH_SUGGESTIONS: getFlag('ENABLE_SEARCH_SUGGESTIONS', true),

  // Phase 4 Business Engine Feature Flags
  ENABLE_ESCROW: getFlag('ENABLE_ESCROW', true),
  ENABLE_DISPUTES: getFlag('ENABLE_DISPUTES', true),
  ENABLE_COMMISSIONS: getFlag('ENABLE_COMMISSIONS', true),
  ENABLE_INVOICES: getFlag('ENABLE_INVOICES', true),
  ENABLE_SETTLEMENTS: getFlag('ENABLE_SETTLEMENTS', true),
  ENABLE_COUPONS: getFlag('ENABLE_COUPONS', true),
  ENABLE_FRAUD_DETECTION: getFlag('ENABLE_FRAUD_DETECTION', true),
  ENABLE_REPUTATION: getFlag('ENABLE_REPUTATION', true),
  ENABLE_CRON: getFlag('ENABLE_CRON', true),
  ENABLE_REFERRALS: getFlag('ENABLE_REFERRALS', true),
  ENABLE_MODERATION: getFlag('ENABLE_MODERATION', true),
  ENABLE_RULES: getFlag('ENABLE_RULES', true),
  ENABLE_MULTICURRENCY: getFlag('ENABLE_MULTICURRENCY', true),

  // Phase 5 Infrastructure & SRE Feature Flags
  ENABLE_MONITORING: getFlag('ENABLE_MONITORING', true),
  ENABLE_BACKUPS: getFlag('ENABLE_BACKUPS', true),
  ENABLE_SWAGGER: getFlag('ENABLE_SWAGGER', true),
  ENABLE_METRICS: getFlag('ENABLE_METRICS', true),
  ENABLE_INFRASTRUCTURE: getFlag('ENABLE_INFRASTRUCTURE', true),
  ENABLE_KUBERNETES: getFlag('ENABLE_KUBERNETES', true),
  ENABLE_MIGRATIONS: getFlag('ENABLE_MIGRATIONS', true),
  ENABLE_RELEASE_MANAGER: getFlag('ENABLE_RELEASE_MANAGER', true),
  ENABLE_SECRETS_PROVIDER: getFlag('ENABLE_SECRETS_PROVIDER', true),
  ENABLE_DR: getFlag('ENABLE_DR', true),
  ENABLE_CANARY_DEPLOYMENT: getFlag('ENABLE_CANARY_DEPLOYMENT', true),
  ENABLE_TRACING: getFlag('ENABLE_TRACING', true),
  ENABLE_API_VERSIONING: getFlag('ENABLE_API_VERSIONING', true),
  ENABLE_PRODUCTION_VALIDATOR: getFlag('ENABLE_PRODUCTION_VALIDATOR', true),
};

module.exports = featureFlags;
