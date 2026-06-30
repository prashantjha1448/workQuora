const redisClient = require('../config/redis');
const Idempotency = require('../models/Idempotency');

const idempotencyMiddleware = async (req, res, next) => {
  const key = req.headers['idempotency-key'];

  if (!key) {
    return next(); // Bypass if header is not present
  }

  const cacheKey = `idempotency:${key}`;
  const now = Date.now();

  try {
    // 1. Try fetching from Redis
    if (redisClient && redisClient.isOpen) {
      const cached = await redisClient.get(cacheKey).catch(() => null);
      if (cached) {
        const { status, body } = JSON.parse(cached);
        console.log(`⚡ Idempotency Cache HIT (Redis) for key: ${key}`);
        return res.status(status).json(body);
      }
    } else {
      // 2. Try fetching from MongoDB fallback
      const record = await Idempotency.findOne({ key });
      if (record && record.expiresAt > new Date()) {
        console.log(`⚡ Idempotency Cache HIT (MongoDB Fallback) for key: ${key}`);
        return res.status(record.responseStatus).json(record.responseBody);
      }
    }
  } catch (err) {
    console.error('⚠️ Idempotency check failed, continuing sequentially:', err.message);
  }

  // Intercept response methods to cache response payload
  const originalJson = res.json;
  res.json = function (body) {
    res.json = originalJson; // Restore

    const status = res.statusCode;
    const cacheData = { status, body };
    const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24 hours expiration

    // Asynchronously save cache
    (async () => {
      try {
        if (redisClient && redisClient.isOpen) {
          await redisClient.setEx(cacheKey, 24 * 3600, JSON.stringify(cacheData));
        } else {
          await Idempotency.create({
            key,
            responseStatus: status,
            responseBody: body,
            expiresAt,
          });
        }
      } catch (err) {
        console.error('❌ Failed to cache idempotency record:', err.message);
      }
    })();

    return originalJson.call(this, body);
  };

  next();
};

module.exports = idempotencyMiddleware;
