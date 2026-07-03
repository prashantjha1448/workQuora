const SystemSettings = require('../models/SystemSettings');
const User = require('../models/User');

exports.updateSettings = async (req, res, next) => {
  try {
    const { key, value, description } = req.body;
    const setting = await SystemSettings.findOneAndUpdate(
      { key },
      { value, description },
      { new: true, upsert: true }
    );
    res.status(200).json({ success: true, data: setting });
  } catch (err) {
    next(err);
  }
};

exports.getSettings = async (req, res, next) => {
  try {
    const settings = await SystemSettings.find({}).lean();
    res.status(200).json({ success: true, data: settings });
  } catch (err) {
    next(err);
  }
};

exports.getPrivacySettings = async (req, res, next) => {
  try {
    const user = await User.findById(req.user.id).select('privacySettings');
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });
    res.status(200).json({ success: true, data: user.privacySettings });
  } catch (err) {
    next(err);
  }
};

exports.updatePrivacySettings = async (req, res, next) => {
  try {
    const { showEmail, showPhone, showEarnings, profileVisibility } = req.body;
    const update = {};
    if (showEmail !== undefined) update['privacySettings.showEmail'] = showEmail;
    if (showPhone !== undefined) update['privacySettings.showPhone'] = showPhone;
    if (showEarnings !== undefined) update['privacySettings.showEarnings'] = showEarnings;
    if (profileVisibility !== undefined) update['privacySettings.profileVisibility'] = profileVisibility;

    const user = await User.findByIdAndUpdate(req.user.id, { $set: update }, { new: true, runValidators: true }).select('privacySettings');
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });
    res.status(200).json({ success: true, data: user.privacySettings });
  } catch (err) {
    next(err);
  }
};
