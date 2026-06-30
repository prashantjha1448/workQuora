const mongoose = require('mongoose');

const idempotencySchema = new mongoose.Schema(
  {
    key: {
      type: String,
      required: true,
      unique: true,
      index: true,
    },
    responseBody: {
      type: mongoose.Schema.Types.Mixed,
      required: true,
    },
    responseStatus: {
      type: Number,
      required: true,
    },
    expiresAt: {
      type: Date,
      required: true,
      index: { expires: 0 }, // MongoDB TTL index to auto-delete expired records
    },
  },
  {
    timestamps: true,
  }
);

const Idempotency = mongoose.model('Idempotency', idempotencySchema);
module.exports = Idempotency;
