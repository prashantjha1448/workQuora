const mongoose = require('mongoose');

const ledgerSchema = new mongoose.Schema(
  {
    transactionId: { type: String, required: true },
    walletId: { type: String, required: true }, // userId of the wallet owner
    debit: { type: Number, default: 0 }, // positive value indicating money going out
    credit: { type: Number, default: 0 }, // positive value indicating money coming in
    runningBalance: { type: Number, required: true },
    currency: { type: String, default: 'INR' },
    reference: {
      type: String,
      enum: ['deposit', 'withdrawal', 'escrow_hold', 'escrow_release', 'commission', 'referral', 'coupon', 'adjustment'],
      required: true,
    },
    description: { type: String },
    metadata: { type: mongoose.Schema.Types.Mixed },
  },
  { timestamps: true }
);

// Indexes for fast double-entry queries and audits (Vol 10)
ledgerSchema.index({ walletId: 1, createdAt: -1 });
ledgerSchema.index({ transactionId: 1 });

module.exports = mongoose.model('Ledger', ledgerSchema);
