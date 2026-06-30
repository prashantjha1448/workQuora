const express = require('express');
const router = express.Router();
const referralController = require('../controllers/referralController');
const { protect } = require('../middlewares/authMiddleware');

router.use(protect);

router.post('/register', referralController.registerReferral);
router.get('/', referralController.getReferrals);

module.exports = router;
