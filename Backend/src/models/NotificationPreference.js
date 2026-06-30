const mongoose = require('mongoose');

const preferenceItemSchema = new mongoose.Schema({
  email: { type: Boolean, default: true },
  sms: { type: Boolean, default: false },
  push: { type: Boolean, default: true },
  inApp: { type: Boolean, default: true },
}, { _id: false });

const notificationPreferenceSchema = new mongoose.Schema(
  {
    userId: { type: String, unique: true, required: true },
    security: { type: preferenceItemSchema, default: () => ({ email: true, sms: true, push: true, inApp: true }) },
    wallet: { type: preferenceItemSchema, default: () => ({ email: true, sms: false, push: true, inApp: true }) },
    payments: { type: preferenceItemSchema, default: () => ({ email: true, sms: false, push: true, inApp: true }) },
    escrow: { type: preferenceItemSchema, default: () => ({ email: true, sms: false, push: true, inApp: true }) },
    messages: { type: preferenceItemSchema, default: () => ({ email: false, sms: false, push: true, inApp: true }) },
    chat: { type: preferenceItemSchema, default: () => ({ email: false, sms: false, push: true, inApp: true }) },
    jobs: { type: preferenceItemSchema, default: () => ({ email: true, sms: false, push: false, inApp: true }) },
    proposals: { type: preferenceItemSchema, default: () => ({ email: true, sms: false, push: true, inApp: true }) },
    marketing: { type: preferenceItemSchema, default: () => ({ email: false, sms: false, push: false, inApp: false }) },
    promotions: { type: preferenceItemSchema, default: () => ({ email: false, sms: false, push: false, inApp: false }) },
    aiSuggestions: { type: preferenceItemSchema, default: () => ({ email: true, sms: false, push: false, inApp: true }) },
    systemUpdates: { type: preferenceItemSchema, default: () => ({ email: true, sms: false, push: false, inApp: true }) },
  },
  { timestamps: true }
);

module.exports = mongoose.model('NotificationPreference', notificationPreferenceSchema);
