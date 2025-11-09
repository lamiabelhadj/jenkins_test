# Use Chainguard Node.js image (minimal, secure by default)
FROM cgr.dev/chainguard/node:latest-dev AS builder

WORKDIR /usr/src/app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production --omit=dev

# Copy source
COPY . .

# Production stage
FROM cgr.dev/chainguard/node:latest

WORKDIR /usr/src/app

# Copy node_modules and application
COPY --from=builder /usr/src/app/ ./

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD ["node", "-e", "require('http').get('http://localhost:3000/health', (r) => process.exit(r.statusCode === 200 ? 0 : 1))"]

# Start the application
CMD ["app.js"]