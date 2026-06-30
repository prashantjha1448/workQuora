const mongoose = require('mongoose');

const transactionSchema = new mongoose.Schema(
  {
    sender: {
      type: String,
      ref: 'User',
      required: true
    },
    receiver: {
      type: String,
      ref: 'User',
      required: true
    },
    job: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Job',
      required: false
    },
    amount: {
      type: Number,
      required: true
    },
    type: {
      type: String,
      enum: ['escrow_deposit', 'escrow_release', 'refund', 'withdrawal', 'deposit'],
      required: true
    },
    status: {
      type: String,
      enum: ['pending', 'completed', 'failed'],
      default: 'pending'
    }
  },
  { timestamps: true }
);

transactionSchema.index({ sender: 1, createdAt: -1 });
transactionSchema.index({ receiver: 1, createdAt: -1 });

module.exports = mongoose.model('Transaction', transactionSchema);