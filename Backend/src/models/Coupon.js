const mongoose = require('mongoose');

const couponSchema = new mongoose.Schema(
  {
    code: { type: String, unique: true, required: true },
    type: { type: String, enum: ['flat', 'percentage'], required: true },
    value: { type: Number, required: true }, // Flat amount or %
    minJobBudget: { type: Number, default: 0 },
    maxDiscount: { type: Number }, // Caps percentage discounts
    expiryDate: { type: Date, required: true },
    isActive: { type: Boolean, default: true },
    usageCount: { type: Number, default: 0 },
    usageLimit: { type: Number, default: 100 }, // Max total uses
  },
  { timestamps: true }
);

module.exports = mongoose.model('Coupon', couponSchema);
