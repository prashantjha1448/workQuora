# ── STAGE 1: BUILD DEPENDENCIES ──
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# ── STAGE 2: PRODUCTION RUNTIME ──
FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY . .

# Set environment runtime profiles (Vol 10)
ENV NODE_ENV=production
ENV PORT=3000

# Run container as non-privileged service user for security hardening (Vol 11)
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
RUN chown -R appuser:appgroup /app
USER appuser

EXPOSE 3000

# Health check to allow container orchestrators (AWS ECS, Docker) to monitor status (Vol 20)
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD node -e "fetch('http://localhost:3000/api/v1/health/liveness').then(r => process.exit(r.ok ? 0 : 1)).catch(() => process.exit(1))"

CMD ["node", "src/server.js"]
