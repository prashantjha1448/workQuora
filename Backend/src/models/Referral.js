const mongoose = require('mongoose');

const referralSchema = new mongoose.Schema(
  {
    referrerId: { type: String, ref: 'User', required: true },
    referredUserId: { type: String, ref: 'User', required: true },
    status: {
      type: String,
      enum: ['pending', 'rewarded'],
      default: 'pending',
    },
    rewardAmount: { type: Number, default: 100 }, // Reward in INR
    referredUserMilestoneCompleted: { type: Boolean, default: false },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Referral', referralSchema);
