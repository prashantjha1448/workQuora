const express = require('express');
const router = express.Router();
const { getAllDisputes, getDisputeById, adminResolveDispute } = require('../controllers/adminDisputeController');
const { protectAdmin } = require('../middleware/adminAuthMiddleware');

router.use(protectAdmin);

router.get('/', getAllDisputes);
router.get('/:disputeId', getDisputeById);
router.post('/:disputeId/resolve', adminResolveDispute);

module.exports = router;
