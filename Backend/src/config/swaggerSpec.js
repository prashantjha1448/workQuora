/**
 * OpenAPI 3.1 Specification Registry for WorkQuora (Phase 5 compliance)
 */
const swaggerSpecification = {
  openapi: '3.1.0',
  info: {
    title: 'WorkQuora API Documentation',
    version: '1.4.0',
    description: 'Enterprise Marketplace Engine & Performance Intelligence Backend',
  },
  servers: [
    { url: '/api/v1', description: 'Production API endpoint version 1' }
  ],
  paths: {
    '/health/liveness': {
      get: {
        summary: 'Check API liveness',
        responses: {
          200: { description: 'Master node running successfully' }
        }
      }
    },
    '/health/readiness': {
      get: {
        summary: 'Check databases connectivity and latencies',
        responses: {
          200: { description: 'Readiness check resolved' }
        }
      }
    }
  }
};

module.exports = swaggerSpecification;
