const express = require('express');
const router = express.Router();
const AdminUser = require('../models/AdminUser');

// POST /api/admin/bootstrap-superadmin
// One-time bootstrap route — public, guarded by a shared secret header instead
// of session auth (there's no admin session to authenticate with yet, that's
// the whole point). Remove this route manually after first successful use.
router.post('/', async (req, res, next) => {
  try {
    const secret = req.headers['x-bootstrap-secret'];
    if (!secret || secret !== process.env.BOOTSTRAP_SECRET) {
      return res.status(401).json({ success: false, message: 'Invalid or missing bootstrap secret' });
    }

    const existing = await AdminUser.findOne({ isSuperAdmin: true });
    if (existing) {
      return res.status(403).json({ success: false, message: 'Super admin already exists' });
    }

    const { SUPER_ADMIN_NAME, SUPER_ADMIN_EMAIL, SUPER_ADMIN_PASSWORD, SUPER_ADMIN_MOBILE } = process.env;
    if (!SUPER_ADMIN_EMAIL || !SUPER_ADMIN_PASSWORD) {
      return res.status(500).json({ success: false, message: 'SUPER_ADMIN_EMAIL/SUPER_ADMIN_PASSWORD not set in environment' });
    }

    const superAdmin = await AdminUser.create({
      name: SUPER_ADMIN_NAME || 'Super Admin',
      email: SUPER_ADMIN_EMAIL,
      password: SUPER_ADMIN_PASSWORD,
      mobileNumber: SUPER_ADMIN_MOBILE || null,
      role: 'SUPER_ADMIN',
      isSuperAdmin: true,
      isActive: true,
      isSuspended: false,
      permissions: [],
      createdBy: null,
    });

    res.status(201).json({
      success: true,
      message: 'Super admin created successfully',
      data: { id: superAdmin._id, name: superAdmin.name, email: superAdmin.email, role: superAdmin.role },
    });
  } catch (error) { next(error); }
});

module.exports = router;
