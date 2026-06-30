const mongoose = require('mongoose');
const featureFlags = require('../config/featureFlags');
const os = require('os');

class ProductionValidator {
  /**
   * Automatically executes SRE checklist audits (Vol 15)
   */
  async runProductionAudit() {
    if (!featureFlags.ENABLE_PRODUCTION_VALIDATOR) {
      return { score: 100, warnings: [], errors: [], recommendations: [] };
    }

    const errors = [];
    const warnings = [];
    const recommendations = [];

    // 1. Check database connections
    const dbState = mongoose.connection.readyState;
    if (dbState !== 1) {
      errors.push('CRITICAL: MongoDB is not connected.');
    }

    // 2. Validate essential text indexes are mounted (Vol 15)
    try {
      const collections = await mongoose.connection.db.listCollections().toArray();
      const hasJobs = collections.some(c => c.name === 'jobs');
      if (hasJobs) {
        const indexes = await mongoose.connection.db.collection('jobs').indexes();
        const hasTextIndex = indexes.some(idx => idx.name.includes('text') || Object.values(idx.key).includes('text'));
        if (!hasTextIndex) {
          warnings.push('WARNING: Jobs collection is missing optimized text search indexing.');
          recommendations.push('INDEXING: Create compound text index on Jobs title and description.');
        }
      }
    } catch (err) {
      warnings.push(`INDEXING: Failed to fetch indexes: ${err.message}`);
    }

    // 3. Verify System Secrets setup (Vol 15)
    const secretProvider = require('../config/secretProvider');
    const jwtSecret = await secretProvider.getSecret('JWT_SECRET');
    if (!jwtSecret || jwtSecret === 'mock-secret-phase5') {
      warnings.push('SECURITY: JWT_SECRET is currently using a mock default string.');
      recommendations.push('SECURITY: Inject dynamic credentials from AWS Secrets Manager or Vault.');
    }

    // 4. Check OS margins
    const freeMem = os.freemem();
    const totalMem = os.totalmem();
    const memUsagePercent = ((totalMem - freeMem) / totalMem) * 100;
    if (memUsagePercent > 95) {
      warnings.push('SYSTEM: Server is running with dangerously high RAM utilization limits.');
    }

    // 5. Calculate Production Readiness Score
    let score = 100;
    score -= errors.length * 20;
    score -= warnings.length * 5;
    const finalScore = Math.max(0, score);

    return {
      score: finalScore,
      errors,
      warnings,
      recommendations,
      checkedAt: new Date().toISOString(),
    };
  }
}

module.exports = new ProductionValidator();
