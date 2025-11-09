# -----------------------------
# Stage 1: Build the application
# -----------------------------
FROM cgr.dev/chainguard/node:latest-dev AS builder

# Switch to root temporarily to set up permissions
USER root
RUN mkdir -p /usr/src/app && chown -R node:node /usr/src/app

# Switch back to non-root user (Chainguard runs as 'node' by default)
USER node
WORKDIR /usr/src/app

# Copy package files
COPY package*.json ./

# Install dependencies (use npm ci if lockfile exists, else fallback)
RUN if [ -f package-lock.json ]; then npm ci --only=production --omit=dev; \
    else npm install --omit=dev; fi

# Copy source code
COPY . .

# -----------------------------
# Stage 2: Production image
# -----------------------------
FROM cgr.dev/chainguard/node:latest

# Same directory for runtime
WORKDIR /usr/src/app

# Copy built app and dependencies from builder
COPY --from=builder /usr/src/app ./

# Expose the application port
EXPOSE 3000

# Optional health check for container orchestration systems
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD ["node", "-e", "require('http').get('http://localhost:3000/health', (r) => process.exit(r.statusCode === 200 ? 0 : 1))"]

# Use node directly to start the app
CMD ["node", "app.js"]
