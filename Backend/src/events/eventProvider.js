const eventBus = require('./eventBus');
const config = require('../config/configService');

class AbstractEventProvider {
  publish(eventName, payload, io, options = {}) {
    throw new Error('publish method must be implemented by subclass');
  }
  async getQueueMetrics() {
    return { provider: 'abstract', status: 'unimplemented' };
  }
}

// ── LOCAL EVENT PROVIDER (FALLBACK) ──
class LocalEventProvider extends AbstractEventProvider {
  constructor() {
    super();
    this.metrics = {
      completed: 0,
      failed: 0,
      active: 0,
      delayed: 0,
      total: 0,
    };
  }

  publish(eventName, payload, io, options = {}) {
    this.metrics.total++;
    this.metrics.active++;
    console.log(`🔌 [LocalEventProvider] Publishing event: "${eventName}" (priority: ${options.priority || 'medium'}, delay: ${options.delay || 0}ms)`);
    
    const execute = () => {
      try {
        eventBus.emit(eventName, payload, io);
        this.metrics.completed++;
      } catch (err) {
        this.metrics.failed++;
        console.error(`❌ [LocalEventProvider] Event execution failed: ${err.message}`);
      } finally {
        this.metrics.active = Math.max(0, this.metrics.active - 1);
      }
    };

    if (options.delay) {
      this.metrics.delayed++;
      setTimeout(() => {
        this.metrics.delayed = Math.max(0, this.metrics.delayed - 1);
        execute();
      }, options.delay);
    } else {
      execute();
    }
  }

  async getQueueMetrics() {
    return {
      provider: 'local',
      status: 'active',
      metrics: { ...this.metrics },
    };
  }
}

// ── REDIS BULLMQ EVENT PROVIDER (DISTRIBUTED QUEUE) ──
class BullMQEventProvider extends AbstractEventProvider {
  constructor() {
    super();
    this.queue = null;
    try {
      const { Queue } = require('bullmq');
      // Set up Redis-backed job queue with exponential backoff strategy (Vol 19)
      this.queue = new Queue('workquora-events', {
        connection: {
          url: config.redisUrl || 'redis://127.0.0.1:6379'
        },
        defaultJobOptions: {
          attempts: 5, // Retry up to 5 times on failures
          backoff: {
            type: 'exponential',
            delay: 1000 // Exponential backoff starting at 1s
          },
          removeOnComplete: true, // Auto clean successful jobs
          removeOnFail: false // Keep failed jobs in DLQ for analysis
        }
      });
      console.log('✅ BullMQ Distributed Queue Provider Initialized successfully.');
    } catch (err) {
      console.warn('⚠️ BullMQ package not installed or Redis not configured. EventProvider falling back to local memory bus.');
    }
  }

  async publish(eventName, payload, io, options = {}) {
    if (this.queue) {
      console.log(`🔌 [BullMQEventProvider] Enqueueing job event: "${eventName}" to Redis`);
      try {
        // Map friendly priority string to BullMQ priority number (1 is highest, 10 is low)
        let priorityVal = 5;
        if (options.priority === 'high') priorityVal = 1;
        if (options.priority === 'low') priorityVal = 10;

        const jobOpts = {
          priority: priorityVal,
          delay: options.delay || 0,
        };

        if (options.attempts) {
          jobOpts.attempts = options.attempts;
        }

        await this.queue.add(eventName, { payload }, jobOpts);
      } catch (err) {
        console.error('❌ BullMQ Enqueue failed, falling back to local bus:', err.message);
        eventBus.emit(eventName, payload, io);
      }
    } else {
      // Local fallback
      eventBus.emit(eventName, payload, io);
    }
  }

  async getQueueMetrics() {
    if (!this.queue) {
      return { provider: 'bullmq', status: 'disconnected', error: 'Queue client uninitialized' };
    }
    try {
      const [active, completed, failed, delayed, waiting] = await Promise.all([
        this.queue.getActiveCount(),
        this.queue.getCompletedCount(),
        this.queue.getFailedCount(),
        this.queue.getDelayedCount(),
        this.queue.getWaitingCount(),
      ]);

      return {
        provider: 'bullmq',
        status: 'connected',
        metrics: {
          active,
          completed,
          failed, // This serves as the DLQ monitoring count
          delayed,
          waiting,
          total: active + completed + failed + delayed + waiting,
        }
      };
    } catch (err) {
      return { provider: 'bullmq', status: 'error', error: err.message };
    }
  }
}

// Initialize provider based on config file settings (Vol 19)
let activeProvider;

if (config.queueProvider === 'redis' && config.redisUrl) {
  activeProvider = new BullMQEventProvider();
} else {
  activeProvider = new LocalEventProvider();
}

module.exports = activeProvider;
