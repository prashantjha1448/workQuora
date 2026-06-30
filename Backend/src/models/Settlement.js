const mongoose = require('mongoose');

const settlementSchema = new mongoose.Schema(
  {
    settlementNumber: { type: String, unique: true, required: true },
    freelancerId: { type: String, ref: 'User', required: true },
    jobId: { type: mongoose.Schema.Types.ObjectId, ref: 'Job', required: true },
    grossAmount: { type: Number, required: true },
    commissionDeducted: { type: Number, default: 0 },
    taxDeducted: { type: Number, default: 0 },
    netAmountSettled: { type: Number, required: true },
    currency: { type: String, default: 'INR' },
    status: {
      type: String,
      enum: ['pending', 'completed', 'failed'],
      default: 'completed',
    },
    reference: { type: String }, // Transaction ID
  },
  { timestamps: true }
);

module.exports = mongoose.model('Settlement', settlementSchema);
