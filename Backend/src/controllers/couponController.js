const couponService = require('../services/couponService');

exports.applyCoupon = async (req, res, next) => {
  try {
    const { code, budget } = req.body;
    const result = await couponService.validateAndApplyCoupon(code, Number(budget));
    res.status(200).json({ success: true, data: result });
  } catch (err) {
    res.status(400).json({ success: false, message: err.message });
  }
};

exports.createCoupon = async (req, res, next) => {
  try {
    const { code, type, value, minJobBudget, maxDiscount } = req.body;
    const coupon = await couponService.createCoupon({
      code,
      type,
      value: Number(value),
      minJobBudget: Number(minJobBudget || 0),
      maxDiscount: maxDiscount ? Number(maxDiscount) : null,
    });
    res.status(201).json({ success: true, data: coupon });
  } catch (err) {
    next(err);
  }
};
