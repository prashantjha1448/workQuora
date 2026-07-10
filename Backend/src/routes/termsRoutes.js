const express = require('express');
const router = express.Router();
const { getCurrentTerms, acceptTerms } = require('../controllers/termsController');
const { protect } = require('../middlewares/authMiddleware');

router.get('/current', getCurrentTerms);
router.post('/accept', protect, acceptTerms);

module.exports = router;
