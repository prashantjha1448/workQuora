/**
 * Centralized Multi-Currency Configurations Foundation for WorkQuora (Phase 4 compliance)
 */
const currencyConfigs = {
  INR: {
    currencyCode: 'INR',
    symbol: '₹',
    exchangeRate: 1.0, // base currency
    decimalPrecision: 2,
    locale: 'en-IN',
    formattingRules: { style: 'currency', currency: 'INR' },
  },
  USD: {
    currencyCode: 'USD',
    symbol: '$',
    exchangeRate: 0.012, // example rate config
    decimalPrecision: 2,
    locale: 'en-US',
    formattingRules: { style: 'currency', currency: 'USD' },
  },
  EUR: {
    currencyCode: 'EUR',
    symbol: '€',
    exchangeRate: 0.011,
    decimalPrecision: 2,
    locale: 'de-DE',
    formattingRules: { style: 'currency', currency: 'EUR' },
  },
  GBP: {
    currencyCode: 'GBP',
    symbol: '£',
    exchangeRate: 0.0094,
    decimalPrecision: 2,
    locale: 'en-GB',
    formattingRules: { style: 'currency', currency: 'GBP' },
  },
  AED: {
    currencyCode: 'AED',
    symbol: 'د.إ',
    exchangeRate: 0.044,
    decimalPrecision: 2,
    locale: 'ar-AE',
    formattingRules: { style: 'currency', currency: 'AED' },
  },
  SGD: {
    currencyCode: 'SGD',
    symbol: 'S$',
    exchangeRate: 0.016,
    decimalPrecision: 2,
    locale: 'en-SG',
    formattingRules: { style: 'currency', currency: 'SGD' },
  },
};

module.exports = currencyConfigs;
