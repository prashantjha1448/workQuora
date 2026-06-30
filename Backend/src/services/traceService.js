const crypto = require('crypto');
const featureFlags = require('../config/featureFlags');

class TraceService {
  /**
   * Extract or generate trace correlation context IDs (Vol 10)
   */
  getTraceContext(req) {
    if (!featureFlags.ENABLE_TRACING) {
      return { traceId: crypto.randomUUID(), spanId: crypto.randomUUID() };
    }

    const traceHeader = req.headers['x-trace-id'] || req.headers['traceparent'];
    let traceId;
    if (traceHeader) {
      traceId = traceHeader.split('-')[1] || traceHeader;
    } else {
      traceId = crypto.randomBytes(16).toString('hex');
    }

    const spanId = crypto.randomBytes(8).toString('hex');

    return {
      traceId,
      spanId,
    };
  }

  /**
   * Express middleware router to inject correlation headers to responses
   */
  traceMiddleware() {
    return (req, reqRes, next) => {
      const { traceId, spanId } = this.getTraceContext(req);
      req.traceId = traceId;
      req.spanId = spanId;
      reqRes.setHeader('x-trace-id', traceId);
      next();
    };
  }
}

module.exports = new TraceService();
