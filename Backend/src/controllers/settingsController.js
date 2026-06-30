const SystemSettings = require('../models/SystemSettings');

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
