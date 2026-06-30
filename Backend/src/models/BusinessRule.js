const mongoose = require('mongoose');

const businessRuleSchema = new mongoose.Schema(
  {
    name: { type: String, unique: true, required: true }, // e.g. 'premium_user_commission'
    conditions: { type: mongoose.Schema.Types.Mixed }, // conditions logic
    actions: { type: mongoose.Schema.Types.Mixed }, // output settings e.g. { commission: 5 }
    description: { type: String },
  },
  { timestamps: true }
);

module.exports = mongoose.model('BusinessRule', businessRuleSchema);
