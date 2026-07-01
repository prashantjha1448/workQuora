const redisClient = require('../config/redis');

// In-memory fallback database for local environments when Redis is offline
const memoryStore = new Map();

// Helper to clean expired memory keys periodically
setInterval(() => {
  const now = Date.now();
  for (const [key, value] of memoryStore.entries()) {
    if (value.expiresAt <= now) {
      memoryStore.delete(key);
    }
  }
}, 60000); // Clean every minute

const createLimiter = ({ windowMs, max, message }) => {
  return async (req, res, next) => {
    // Whitelist dev/testing environment to prevent E2E test blocker conflicts (Vol 11)
    if (process.env.NODE_ENV === 'test' || process.env.NODE_ENV === 'development' || process.env.ENABLE_DEV_BYPASS === 'true') {
      return next();
    }
    const ip = req.ip || req.headers['x-forwarded-for'] || '127.0.0.1';
    const key = `ratelimit:${req.path}:${ip}`;
    const now = Date.now();

    if (redisClient && redisClient.isOpen) {
      try {
        const count = await redisClient.incr(key);
        if (count === 1) {
          await redisClient.expire(key, Math.ceil(windowMs / 1000));
        }
        if (count > max) {
          return res.status(429).json({ success: false, message: message || 'Too many requests' });
        }
        return next();
      } catch (err) {
        console.warn('⚠️ Redis rate limiter error, falling back to local memory storage:', err.message);
      }
    }

    // ── LOCAL IN-MEMORY STORE FALLBACK ──
    let record = memoryStore.get(key);
    if (!record || record.expiresAt <= now) {
      record = {
        count: 1,
        expiresAt: now + windowMs
      };
      memoryStore.set(key, record);
    } else {
      record.count += 1;
    }

    if (record.count > max) {
      return res.status(429).json({ success: false, message: message || 'Too many requests' });
    }

    next();
  };
};

// Define specific rate limiters based on Phase 2 requirements (Vol 11)
module.exports = {
  loginLimiter: createLimiter({
    windowMs: 15 * 60 * 1000, // 15 mins
    max: 5,
    message: 'Too many login attempts. Please try again after 15 minutes.'
  }),
  registerLimiter: createLimiter({
    windowMs: 60 * 60 * 1000, // 1 hour
    max: 5,
    message: 'Too many accounts registered. Please try again after 1 hour.'
  }),
  emailOtpLimiter: createLimiter({
    windowMs: 10 * 60 * 1000, // 10 mins
    max: 3,
    message: 'Too many email verification requests. Please try again after 10 minutes.'
  }),
  mobileOtpLimiter: createLimiter({
    windowMs: 10 * 60 * 1000, // 10 mins
    max: 3,
    message: 'Too many mobile OTP requests. Please try again after 10 minutes.'
  }),
  forgotPasswordLimiter: createLimiter({
    windowMs: 60 * 60 * 1000, // 1 hour
    max: 3,
    message: 'Too many forgot password requests. Please try again after 1 hour.'
  }),
  passwordResetLimiter: createLimiter({
    windowMs: 60 * 60 * 1000, // 1 hour
    max: 3,
    message: 'Too many password reset attempts. Please try again after 1 hour.'
  }),
  walletLimiter: createLimiter({
    windowMs: 60 * 1000, // 1 min
    max: 30,
    message: 'Wallet transaction limit exceeded. Please wait a minute.'
  }),
  paymentLimiter: createLimiter({
    windowMs: 60 * 1000, // 1 min
    max: 30,
    message: 'Payment requests limit exceeded. Please wait a minute.'
  }),
  proposalLimiter: createLimiter({
    windowMs: 60 * 1000, // 1 min
    max: 20,
    message: 'Proposal submissions limit exceeded. Please try again later.'
  }),
  kycLimiter: createLimiter({
    windowMs: 60 * 60 * 1000, // 1 hour
    max: 5,
    message: 'KYC submission limit exceeded. Please try again after 1 hour.'
  }),
  adminLimiter: createLimiter({
    windowMs: 15 * 60 * 1000, // 15 mins
    max: 60,
    message: 'Admin API limit exceeded.'
  })
};
