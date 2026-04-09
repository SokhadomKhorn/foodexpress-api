# ── Stage 1: Build ──────────────────────────────────────────────
FROM node:24-alpine AS builder

WORKDIR /usr/src/app

# Copy dependency files first (layer caching)
COPY package*.json ./

# Install only production dependencies
RUN npm install --omit=dev

# ── Stage 2: Runtime ─────────────────────────────────────────────
FROM node:24-alpine

# Security: run as non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /usr/src/app

# Copy built node_modules and app source from builder
COPY --from=builder /usr/src/app/node_modules ./node_modules
COPY . .

# Set ownership
RUN chown -R appuser:appgroup /usr/src/app
USER appuser

# App runs on port 5000
EXPOSE 5000

# Health check — Docker restarts container if this fails
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
  CMD wget -qO- http://localhost:5000/ || exit 1

CMD ["node", "index.js"]
