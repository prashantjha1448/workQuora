const Invoice = require('../models/Invoice');

exports.getInvoices = async (req, res, next) => {
  try {
    const invoices = await Invoice.find({
      $or: [{ clientId: req.user.id }, { freelancerId: req.user.id }],
    })
      .sort({ createdAt: -1 })
      .lean();
    res.status(200).json({ success: true, data: invoices });
  } catch (err) {
    next(err);
  }
};
