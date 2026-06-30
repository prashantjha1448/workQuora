const fs = require('fs');
const path = require('path');
const featureFlags = require('../config/featureFlags');

class BackupService {
  constructor() {
    this.backupDir = path.join(process.cwd(), 'backups');
    if (!fs.existsSync(this.backupDir)) {
      fs.mkdirSync(this.backupDir, { recursive: true });
    }
  }

  /**
   * Triggers backups of database snapshot metadata and active uploads
   */
  async triggerBackup(type = 'mongo') {
    if (!featureFlags.ENABLE_BACKUPS) {
      console.log('📦 BackupService: Backups are disabled by feature flags.');
      return null;
    }

    const stamp = Date.now();
    const fileName = `${type}_backup_${stamp}.json`;
    const filePath = path.join(this.backupDir, fileName);

    const mockMetadata = {
      backupType: type,
      timestamp: new Date().toISOString(),
      status: 'success',
      recordCount: 1500,
      sizeBytes: 1024 * 50,
    };

    fs.writeFileSync(filePath, JSON.stringify(mockMetadata, null, 2));
    console.log(`📦 BackupService: Backup saved to: ${filePath}`);
    return { fileName, filePath, sizeBytes: mockMetadata.sizeBytes };
  }

  /**
   * Clean up files exceeding retention limits (Daily/Weekly/Monthly)
   */
  async enforceRetention() {
    const files = fs.readdirSync(this.backupDir);
    const retentionLimit = 30 * 24 * 60 * 60 * 1000; // 30 Days (Vol 5)
    
    let deletedCount = 0;
    for (const file of files) {
      const filePath = path.join(this.backupDir, file);
      const stat = fs.statSync(filePath);
      if (Date.now() - stat.mtimeMs > retentionLimit) {
        fs.unlinkSync(filePath);
        deletedCount++;
      }
    }
    return deletedCount;
  }
}

module.exports = new BackupService();
