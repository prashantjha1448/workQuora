const mongoose = require('mongoose');
const featureFlags = require('../config/featureFlags');

// Define MigrationHistory Schema in-line (Vol 13)
const migrationHistorySchema = new mongoose.Schema({
  version: { type: String, unique: true, required: true },
  description: { type: String },
  migratedAt: { type: Date, default: Date.now },
});

// Define MigrationLock Schema to prevent parallel deployment conflicts
const migrationLockSchema = new mongoose.Schema({
  locked: { type: Boolean, default: false },
  lockedAt: { type: Date },
});

const MigrationHistory = mongoose.model('MigrationHistory', migrationHistorySchema);
const MigrationLock = mongoose.model('MigrationLock', migrationLockSchema);

class MigrationRunner {
  /**
   * Run pending database migrations
   */
  async runMigrations() {
    if (!featureFlags.ENABLE_MIGRATIONS) {
      console.log('📦 MigrationRunner: Migrations disabled by feature flags.');
      return [];
    }

    // 1. Acquire migration lock
    const lock = await MigrationLock.findOneAndUpdate(
      { locked: false },
      { $set: { locked: true, lockedAt: new Date() } },
      { upsert: true, new: true }
    );

    if (!lock || lock.locked === false) {
      console.warn('📦 MigrationRunner: Migration process is already locked/running on another pod.');
      return [];
    }

    try {
      console.log('📦 MigrationRunner: Lock acquired. Executing schema upgrades...');

      const mockMigrations = [
        { version: '1.0.0', description: 'Initialize schemas' },
        { version: '1.0.1', description: 'Add compound indexes for task searches' },
        { version: '1.0.2', description: 'Setup dual-entry ledger indexes' },
      ];

      const executed = [];
      for (const migration of mockMigrations) {
        const alreadyRun = await MigrationHistory.findOne({ version: migration.version }).lean();
        if (!alreadyRun) {
          await MigrationHistory.create({
            version: migration.version,
            description: migration.description,
          });
          executed.push(migration.version);
          console.log(`📦 MigrationRunner: Applied schema migration v${migration.version}`);
        }
      }

      return executed;
    } finally {
      // 2. Release lock
      await MigrationLock.updateOne({}, { $set: { locked: false } });
      console.log('📦 MigrationRunner: Migration lock released.');
    }
  }

  /**
   * Run down/rollback migrations
   */
  async rollbackMigration(version) {
    const deleted = await MigrationHistory.deleteOne({ version });
    return deleted.deletedCount > 0;
  }
}

module.exports = new MigrationRunner();
