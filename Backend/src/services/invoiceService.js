const Invoice = require('../models/Invoice');
const featureFlags = require('../config/featureFlags');
const crypto = require('crypto');

class InvoiceService {
  /**
   * Automatically generate tax invoice records for client payments
   */
  async generateInvoice({ clientId, freelancerId, jobId, amount, commissionAmount, taxAmount = 0, currency = 'INR', session = null }) {
    if (!featureFlags.ENABLE_INVOICES) {
      console.log('📡 InvoiceService: Invoices disabled by feature flags.');
      return null;
    }

    const stamp = Date.now();
    const invoiceNumber = `INV-${stamp}-${crypto.randomBytes(4).toString('hex').toUpperCase()}`;
    const netPayout = amount - commissionAmount - taxAmount;

    const invoiceArr = await Invoice.create(
      [
        {
          invoiceNumber,
          clientId,
          freelancerId,
          jobId,
          amount,
          taxAmount,
          commissionAmount,
          netPayout,
          currency,
          status: 'paid',
        },
      ],
      { session }
    );

    console.log(`🧾 Invoice Generated: ${invoiceNumber} for Job ID: ${jobId}`);
    return invoiceArr[0];
  }
}

module.exports = new InvoiceService();
