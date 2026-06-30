const redisClient = require('../config/redis');
const featureFlags = require('../config/featureFlags');

class CacheService {
  constructor() {
    this.localFallbackMap = new Map(); // Fast local map fallback if Redis is offline
  }

  /**
   * Get cached item
   */
  async get(key) {
    if (!featureFlags.ENABLE_CACHE) return null;
    try {
      if (redisClient.isOpen) {
        const val = await redisClient.get(key);
        return val ? JSON.parse(val) : null;
      }
    } catch (err) {
      console.error('[Cache Get Error (fallback to local Map)]', err.message);
    }
    return this.localFallbackMap.get(key) || null;
  }

  /**
   * Set cached item with TTL in seconds
   */
  async set(key, value, ttlSeconds = 300) {
    if (!featureFlags.ENABLE_CACHE) return;
    try {
      const stringified = JSON.stringify(value);
      if (redisClient.isOpen) {
        await redisClient.setEx(key, ttlSeconds, stringified);
        return;
      }
    } catch (err) {
      console.error('[Cache Set Error]', err.message);
    }
    this.localFallbackMap.set(key, value);
    setTimeout(() => this.localFallbackMap.delete(key), ttlSeconds * 1000);
  }

  /**
   * Delete specific key
   */
  async delete(key) {
    try {
      if (redisClient.isOpen) {
        await redisClient.del(key);
      }
    } catch (err) {
      console.error('[Cache Del Error]', err.message);
    }
    this.localFallbackMap.delete(key);
  }

  /**
   * Invalidate multiple keys matching namespace pattern
   */
  async invalidate(pattern) {
    try {
      if (redisClient.isOpen) {
        const keys = await redisClient.keys(pattern);
        if (keys && keys.length > 0) {
          await redisClient.del(keys);
        }
      }
    } catch (err) {
      console.error('[Cache Invalidate Pattern Error]', err.message);
    }
    
    // Clear matches from fallback Map
    const regex = new RegExp(pattern.replace(/\*/g, '.*'));
    for (const key of this.localFallbackMap.keys()) {
      if (regex.test(key)) {
        this.localFallbackMap.delete(key);
      }
    }
  }

  /**
   * Pre-warm caches
   */
  async warm(key, loaderFn, ttlSeconds = 300) {
    const data = await loaderFn();
    await this.set(key, data, ttlSeconds);
    return data;
  }

  /**
   * Cache Invalidation Strategy mappings
   */
  async handleEvent(event, metadata = {}) {
    console.log(`📡 CacheService: Processing invalidation event "${event}"`);
    const { userId, jobId } = metadata;

    switch (event) {
      case 'JobCreated':
        // invalidate active jobs, client dashboard, and general recommendations
        await this.delete('jobs:active');
        await this.invalidate('jobs:list:*');
        if (userId) await this.delete(`dashboard:client:${userId}`);
        await this.invalidate('recommendations:*');
        break;

      case 'ProposalAccepted':
        // invalidate wallet, notifications, and dashboard
        if (userId) {
          await this.delete(`wallet:balance:${userId}`);
          await this.delete(`dashboard:client:${userId}`);
        }
        await this.invalidate('notifications:*');
        break;

      case 'WalletUpdated':
        // invalidate wallet balances and earnings
        if (userId) {
          await this.delete(`wallet:balance:${userId}`);
          await this.delete(`earnings:${userId}`);
        }
        break;

      case 'ProfileUpdated':
        // invalidate profile details, recommendations, and search cache
        if (userId) {
          await this.delete(`profile:me:${userId}`);
        }
        await this.invalidate('recommendations:*');
        await this.invalidate('search:*');
        break;

      case 'NotificationCreated':
        // invalidate notification count
        if (userId) {
          await this.delete(`notifications:unread:count:${userId}`);
        }
        break;
    }
  }
}

module.exports = new CacheService();
