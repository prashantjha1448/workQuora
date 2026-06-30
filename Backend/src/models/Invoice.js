const mongoose = require('mongoose');

const invoiceSchema = new mongoose.Schema(
  {
    invoiceNumber: { type: String, unique: true, required: true },
    clientId: { type: String, ref: 'User', required: true },
    freelancerId: { type: String, ref: 'User', required: true },
    jobId: { type: mongoose.Schema.Types.ObjectId, ref: 'Job', required: true },
    amount: { type: Number, required: true }, // Gross amount
    taxAmount: { type: Number, default: 0 }, // GST / Service tax
    commissionAmount: { type: Number, default: 0 },
    netPayout: { type: Number, required: true },
    currency: { type: String, default: 'INR' },
    status: {
      type: String,
      enum: ['unpaid', 'paid', 'refunded'],
      default: 'paid',
    },
    paymentReference: { type: String }, // Transaction ID
  },
  { timestamps: true }
);

module.exports = mongoose.model('Invoice', invoiceSchema);
