# ── STAGE 1: BUILD REACT APP ──
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
# Compile Vite production assets
RUN npm run build

# ── STAGE 2: PRODUCTION SERVER (NGINX) ──
FROM nginx:alpine
# Copy compiled static assets from stage 1
COPY --from=builder /app/dist /usr/share/nginx/html
# Copy custom secure Nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
