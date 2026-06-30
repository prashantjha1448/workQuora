const mongoose = require('mongoose');
const crypto = require('crypto');

const sessionSchema = new mongoose.Schema(
  {
    _id: {
      type: String,
      default: () => crypto.randomUUID(),
    },
    userId: {
      type: String,
      required: true,
      ref: 'User',
      index: true,
    },
    sessionId: {
      type: String,
      default: () => crypto.randomUUID(),
      unique: true,
    },
    refreshTokenHash: {
      type: String,
      required: true,
      index: true,
    },
    deviceName: { type: String, default: 'Unknown' },
    browser: { type: String, default: 'Unknown' },
    operatingSystem: { type: String, default: 'Unknown' },
    ipAddress: { type: String, default: '127.0.0.1' },
    country: { type: String, default: 'Unknown' },
    city: { type: String, default: 'Unknown' },
    userAgent: { type: String, default: '' },
    lastUsedAt: { type: Date, default: Date.now },
    expiresAt: { type: Date, required: true },
    isRevoked: { type: Boolean, default: false },
  },
  {
    timestamps: true,
  }
);

// Hash helper for storing rotated tokens
sessionSchema.statics.hashToken = function (token) {
  return crypto.createHash('sha256').update(token).digest('hex');
};

const Session = mongoose.model('Session', sessionSchema);
module.exports = Session;
