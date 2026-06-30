const mongoose = require('mongoose');

const milestoneSchema = new mongoose.Schema({
  title: { type: String, required: true },
  description: { type: String },
  amount: { type: Number, required: true }, // amount in currency base unit
  status: {
    type: String,
    enum: ['pending', 'locked', 'in_progress', 'completed', 'released', 'refunded', 'disputed', 'cancelled'],
    default: 'pending',
  },
  releasedAt: { type: Date },
  refundedAt: { type: Date },
});

const escrowSchema = new mongoose.Schema(
  {
    jobId: { type: mongoose.Schema.Types.ObjectId, ref: 'Job', required: true },
    clientId: { type: String, ref: 'User', required: true },
    freelancerId: { type: String, ref: 'User', required: true },
    currency: { type: String, default: 'INR' },
    totalAmount: { type: Number, required: true },
    status: {
      type: String,
      enum: ['pending', 'locked', 'released', 'refunded', 'disputed', 'cancelled'],
      default: 'locked',
    },
    milestones: [milestoneSchema],
    timeline: [
      {
        event: { type: String, required: true },
        description: { type: String },
        timestamp: { type: Date, default: Date.now },
      },
    ],
  },
  { timestamps: true }
);

module.exports = mongoose.model('Escrow', escrowSchema);
