const referralService = require('../services/referralService');
const Referral = require('../models/Referral');

exports.registerReferral = async (req, res, next) => {
  try {
    const { referrerId } = req.body;
    const ref = await referralService.registerReferral(referrerId, req.user.id);
    res.status(201).json({ success: true, data: ref });
  } catch (err) {
    next(err);
  }
};

exports.getReferrals = async (req, res, next) => {
  try {
    const refs = await Referral.find({ referrerId: req.user.id })
      .populate('referredUserId', 'name email')
      .sort({ createdAt: -1 })
      .lean();
    res.status(200).json({ success: true, data: refs });
  } catch (err) {
    next(err);
  }
};
