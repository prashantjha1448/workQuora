const mongoose = require('mongoose');

const auditLogSchema = new mongoose.Schema(
  {
    userId: { type: String, ref: 'User', index: true },
    action: { type: String, required: true, index: true },
    entity: { type: String, required: true },
    entityId: { type: String },
    ip: { type: String },
    browser: { type: String },
    device: { type: String },
    country: { type: String },
    traceId: { type: String, index: true },
    metadata: { type: mongoose.Schema.Types.Mixed, default: {} },
    timestamp: { type: Date, default: Date.now },
  },
  {
    timestamps: false,
    versionKey: false,
  }
);

// Enforce strict append-only constraints (Vol 11)
auditLogSchema.pre('save', function () {
  if (!this.isNew) {
    throw new Error('Audit logs are append-only. Updates are strictly forbidden.');
  }
});

// Intercept queries that attempt updates/deletions
const preventMutations = function (next) {
  next(new Error('Audit logs are append-only. Modifications or deletions are strictly forbidden.'));
};

auditLogSchema.pre('updateOne', preventMutations);
auditLogSchema.pre('updateMany', preventMutations);
auditLogSchema.pre('findOneAndUpdate', preventMutations);
auditLogSchema.pre('deleteOne', preventMutations);
auditLogSchema.pre('deleteMany', preventMutations);
auditLogSchema.pre('findOneAndDelete', preventMutations);
auditLogSchema.pre('remove', preventMutations);

const AuditLog = mongoose.model('AuditLog', auditLogSchema);
module.exports = AuditLog;
