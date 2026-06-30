const AuditLog = require('../models/AuditLog');
const { parseUserAgent } = require('./uaParser');

const createAuditLog = async (req, { userId, action, entity, entityId, metadata = {} }) => {
  try {
    const ip = req.ip || req.headers['x-forwarded-for'] || '127.0.0.1';
    const uaString = req.headers['user-agent'] || '';
    const ua = parseUserAgent(uaString);
    const country = req.headers['x-country'] || 'Unknown';
    const traceId = req.traceId || '';

    // Create append-only log record
    await AuditLog.create({
      userId: userId || req.user?.id || null,
      action,
      entity,
      entityId: entityId ? String(entityId) : null,
      ip,
      browser: ua.browser,
      device: ua.deviceName,
      country,
      traceId,
      metadata,
    });
  } catch (err) {
    console.error('❌ Failed to write AuditLog entry:', err.message);
  }
};

module.exports = { createAuditLog };
