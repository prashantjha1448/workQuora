const mongoose = require('mongoose');

const disputeSchema = new mongoose.Schema(
  {
    escrowId: { type: mongoose.Schema.Types.ObjectId, ref: 'Escrow', required: true },
    milestoneId: { type: mongoose.Schema.Types.ObjectId }, // optional if disputing whole escrow
    openedBy: { type: String, ref: 'User', required: true },
    againstUser: { type: String, ref: 'User', required: true },
    reason: { type: String, required: true },
    status: {
      type: String,
      enum: ['OPEN', 'UNDER_REVIEW', 'CLIENT_RESPONSE', 'FREELANCER_RESPONSE', 'RESOLVED', 'CLOSED'],
      default: 'OPEN',
    },
    evidenceUrls: [{ type: String }],
    timeline: [
      {
        user: { type: String }, // 'CLIENT', 'FREELANCER', or 'ADMIN'
        action: { type: String, required: true },
        description: { type: String },
        timestamp: { type: Date, default: Date.now },
      },
    ],
    resolutionSplit: {
      clientRefund: { type: Number, default: 0 },
      freelancerPayout: { type: Number, default: 0 },
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Dispute', disputeSchema);
