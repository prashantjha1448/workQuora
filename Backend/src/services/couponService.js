const Coupon = require('../models/Coupon');
const featureFlags = require('../config/featureFlags');

class CouponService {
  /**
   * Validate and apply coupon code to a job budget
   */
  async validateAndApplyCoupon(code, jobBudget) {
    if (!featureFlags.ENABLE_COUPONS) {
      throw new Error('Coupons module is disabled via feature flags.');
    }

    const coupon = await Coupon.findOne({ code, isActive: true });
    if (!coupon) throw new Error('Invalid or expired coupon code');

    if (new Date() > coupon.expiryDate) {
      coupon.isActive = false;
      await coupon.save();
      throw new Error('Coupon has expired');
    }

    if (coupon.usageCount >= coupon.usageLimit) {
      throw new Error('Coupon usage limit reached');
    }

    if (jobBudget < coupon.minJobBudget) {
      throw new Error(`Minimum budget of ₹${coupon.minJobBudget} required to apply this coupon.`);
    }

    let discountAmount = 0;
    if (coupon.type === 'flat') {
      discountAmount = coupon.value;
    } else {
      // Percentage discount
      discountAmount = (jobBudget * coupon.value) / 100;
      if (coupon.maxDiscount) {
        discountAmount = Math.min(discountAmount, coupon.maxDiscount);
      }
    }

    // Increment usage counters
    coupon.usageCount += 1;
    await coupon.save();

    return {
      couponCode: code,
      discountAmount,
      finalBudget: Math.max(0, jobBudget - discountAmount),
    };
  }

  /**
   * Generate static referral / promotional coupons
   */
  async createCoupon({ code, type, value, minJobBudget = 0, maxDiscount = null, expiryDays = 30, usageLimit = 100 }) {
    const expiryDate = new Date();
    expiryDate.setDate(expiryDate.getDate() + expiryDays);

    const couponArr = await Coupon.create([
      {
        code: code.toUpperCase(),
        type,
        value,
        minJobBudget,
        maxDiscount,
        expiryDate,
        usageLimit,
      },
    ]);

    return couponArr[0];
  }
}

module.exports = new CouponService();
