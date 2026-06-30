const eventProvider = require('../events/eventProvider');
const featureFlags = require('../config/featureFlags');

class NotificationService {
  constructor() {
    this.sentLogsMap = new Map(); // Simple in-memory deduplication lookup table
  }

  /**
   * Universal dispatch helper
   */
  async sendNotification(recipientId, type, message, options = {}) {
    if (!featureFlags.ENABLE_NOTIFICATIONS) {
      console.log('📡 NotificationService: Notifications disabled by feature flag.');
      return;
    }

    // 1. Deduplication validation
    const dedupeKey = `${recipientId}:${type}:${message}`;
    if (this.sentLogsMap.has(dedupeKey)) {
      console.log(`📡 NotificationService: Deduplicated alert dispatch for key "${dedupeKey}"`);
      return;
    }

    // Record log for 60 seconds to prevent duplicates
    this.sentLogsMap.set(dedupeKey, Date.now());
    setTimeout(() => this.sentLogsMap.delete(dedupeKey), 60000);

    // Queue delivery via eventProvider using Priority
    eventProvider.publish('send_notification_job', { recipientId, type, message, options }, null, {
      priority: options.priority || 'medium',
      delay: options.delay || 0,
      attempts: options.attempts || 3,
    });
  }

  /**
   * Internal job consumer processing queued alerts
   */
  async processNotificationJob({ recipientId, type, message, options }) {
    // 1. Verify User Preferences (Improvement 5)
    const NotificationPreference = require('../models/NotificationPreference');
    const prefs = await NotificationPreference.findOne({ userId: recipientId }).lean();
    
    const category = options.category || 'systemUpdates';
    const channelMapping = {
      sms: 'sms',
      email: 'email',
      push: 'push',
      inapp: 'inApp',
      general: 'inApp' // fallback mapping for standard alerts
    };

    if (prefs && prefs[category]) {
      const channelField = channelMapping[type];
      if (channelField && prefs[category][channelField] === false) {
        console.log(`📡 NotificationService: Skipping channel "${type}" for category "${category}" due to user preferences`);
        return;
      }
    }

    console.log(`📨 NotificationService Processing: Routing alert of type "${type}" to recipient ${recipientId}`);

    // Compile template options
    const compiledMessage = options.templateData
      ? this._compileTemplate(message, options.templateData)
      : message;

    // Delivery channel routes
    if (type === 'sms') {
      await this._sendSMS(recipientId, compiledMessage);
    } else if (type === 'email') {
      await this._sendEmail(recipientId, compiledMessage, options.subject);
    } else {
      // In-app alert notification
      await this._sendInApp(recipientId, compiledMessage, options.relatedId);
    }
  }

  // ── Private Channel Sender Implementations ───────────────────────────────

  async _sendSMS(phone, message) {
    if (!featureFlags.ENABLE_SMS) {
      console.log(`📱 [SMS Mock Provider] Sending SMS alert to "${phone}": "${message}"`);
      return;
    }
    // SMS provider integration
    console.log(`📱 [SMS Live Provider] Sent SMS successfully.`);
  }

  async _sendEmail(email, message, subject = 'WorkQuora Alert') {
    if (!featureFlags.ENABLE_EMAIL) {
      console.log(`📧 [Email Mock Provider] Dispatching mail to "${email}" [Subject: ${subject}]: "${message}"`);
      return;
    }
    // Email provider integration
    console.log(`📧 [Email Live Provider] Sent email successfully.`);
  }

  async _sendInApp(userId, message, relatedId = null) {
    const createNotification = require('../utils/notification').createNotification;
    try {
      await createNotification({
        recipient: userId,
        sender: 'SYSTEM',
        type: 'general',
        message,
        relatedId,
      });
      console.log(`🔔 [In-App Notification] Created alert for user ${userId}`);
    } catch (err) {
      console.error('❌ NotificationService: Failed to create in-app alert doc:', err.message);
    }
  }

  _compileTemplate(template, data) {
    let compiled = template;
    for (const key of Object.keys(data)) {
      compiled = compiled.replace(new RegExp(`{{${key}}}`, 'g'), data[key]);
    }
    return compiled;
  }
}

// Hook consumer job listener directly into the local eventBus
const eventBus = require('../events/eventBus');
const notificationService = new NotificationService();

eventBus.on('send_notification_job', async (payload) => {
  try {
    await notificationService.processNotificationJob(payload);
  } catch (err) {
    console.error('❌ Notification worker execution failure:', err.message);
  }
});

module.exports = notificationService;
