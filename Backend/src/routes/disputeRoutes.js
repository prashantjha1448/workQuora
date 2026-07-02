const express = require('express');
const router = express.Router();
const disputeController = require('../controllers/disputeController');
const { protect, authorize } = require('../middlewares/authMiddleware');

router.use(protect);

router.post('/', disputeController.openDispute);
router.post('/:disputeId/evidence', disputeController.submitEvidence);
router.post('/:disputeId/resolve', authorize('ADMIN'), disputeController.resolveDispute);

module.exports = router;
