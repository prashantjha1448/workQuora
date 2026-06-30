const featureFlags = require('../config/featureFlags');

class VersionManager {
  constructor() {
    this.deprecatedVersions = new Map();
    // Mark ancient beta versions as deprecated (Vol 11)
    this.deprecatedVersions.set('v0.9.0', {
      deprecationDate: '2026-01-01',
      sunsetDate: '2026-12-31',
    });
  }

  /**
   * Express middleware injecting deprecation headers for sunset compliance APIs (Vol 11)
   */
  versionHeadersMiddleware() {
    return (req, res, next) => {
      if (!featureFlags.ENABLE_API_VERSIONING) {
        return next();
      }

      // Check current api path segment prefix version
      const version = req.originalUrl.split('/')[2]; // e.g. /api/v1/health -> v1
      
      if (this.deprecatedVersions.has(version)) {
        const details = this.deprecatedVersions.get(version);
        res.setHeader('Deprecation', `date="${details.deprecationDate}"`);
        res.setHeader('Sunset', details.sunsetDate);
      }

      next();
    };
  }
}

module.exports = new VersionManager();
