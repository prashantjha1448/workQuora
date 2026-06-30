const EventEmitter = require('events');

class EventBus extends EventEmitter {
  constructor() {
    super();
    // Increase listener limits to prevent warnings in heavy test runs
    this.setMaxListeners(50);
  }

  emit(eventName, ...args) {
    const result = super.emit(eventName, ...args);

    // Dynamic import to avoid circular dependency loops
    const cacheService = require('../services/cacheService');
    
    const payload = args[0];
    const metadata = {};
    if (payload) {
      if (typeof payload === 'object') {
        metadata.userId = payload.userId || payload.clientId || payload.freelancerId || payload.sender || payload.receiver;
        metadata.jobId = payload.jobId || payload._id;
      } else {
        metadata.jobId = payload;
        metadata.userId = payload;
      }
    }

    cacheService.handleEvent(eventName, metadata).catch(err => {
      console.error(`⚠️ Cache invalidation error for event "${eventName}":`, err.message);
    });

    return result;
  }
}

// Single instance to share across modular backend
const eventBus = new EventBus();

module.exports = eventBus;
