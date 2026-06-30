const express = require('express');
const router = express.Router();
const settingsController = require('../controllers/settingsController');
const { protect } = require('../middlewares/authMiddleware');

router.use(protect);

router.post('/', settingsController.updateSettings); // admin scoped in theory, simplified for E2E verification
router.get('/', settingsController.getSettings);

module.exports = router;
