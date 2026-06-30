const express = require('express');
const router = express.Router();
const invoiceController = require('../controllers/invoiceController');
const { protect } = require('../middlewares/authMiddleware');

router.use(protect);

router.get('/', invoiceController.getInvoices);

module.exports = router;
