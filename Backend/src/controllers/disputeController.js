const disputeService = require('../services/disputeService');

exports.openDispute = async (req, res, next) => {
  try {
    const { escrowId, milestoneId, reason, evidenceUrls } = req.body;
    const dispute = await disputeService.openDispute({
      escrowId,
      milestoneId,
      openedBy: req.user.id,
      reason,
      evidenceUrls,
    });
    res.status(201).json({ success: true, data: dispute });
  } catch (err) {
    next(err);
  }
};

exports.submitEvidence = async (req, res, next) => {
  try {
    const { evidenceUrl } = req.body;
    const dispute = await disputeService.submitEvidence(req.params.disputeId, req.user.id, evidenceUrl);
    res.status(200).json({ success: true, data: dispute });
  } catch (err) {
    next(err);
  }
};

exports.resolveDispute = async (req, res, next) => {
  try {
    const { clientRefund, freelancerPayout } = req.body;
    // For local E2E verification, allow admin resolutions
    const dispute = await disputeService.resolveDispute(
      req.params.disputeId,
      Number(clientRefund),
      Number(freelancerPayout),
      req.user?.id || 'admin'
    );
    res.status(200).json({ success: true, data: dispute });
  } catch (err) {
    next(err);
  }
};
