const mongoose = require('mongoose');

const fraudReportSchema = new mongoose.Schema(
  {
    userId: { type: String, ref: 'User', required: true },
    ruleTriggered: { type: String, required: true }, // e.g. 'MULTIPLE_ACCOUNTS', 'RAPID_WITHDRAWALS'
    riskScore: {
      type: String,
      enum: ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'],
      default: 'MEDIUM',
    },
    details: { type: String },
    metadata: { type: mongoose.Schema.Types.Mixed },
    isResolved: { type: Boolean, default: false },
  },
  { timestamps: true }
);

module.exports = mongoose.model('FraudReport', fraudReportSchema);
