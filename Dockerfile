# -----------------------------
# Stage 1: Build the application
# -----------------------------
FROM node:20-bookworm AS builder

WORKDIR /usr/src/app

# Copy package files and install dependencies
COPY package*.json ./
RUN if [ -f package-lock.json ]; then npm ci --only=production --omit=dev; \
    else npm install --omit=dev; fi

# Copy source code
COPY . .

# -----------------------------
# Stage 2: Production image WITH kubectl
# -----------------------------
FROM node:20-bookworm-slim

# Install curl and fetch kubectl binary directly
USER root
RUN apt-get update \
    && apt-get install -y curl ca-certificates \
    && curl -L "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
       -o /usr/local/bin/kubectl \
    && chmod +x /usr/local/bin/kubectl \
    && rm -rf /var/lib/apt/lists/*

# Runtime directory
WORKDIR /usr/src/app

# Copy built app from builder stage
COPY --from=builder /usr/src/app ./

# Expose the application port
EXPOSE 3000

# Healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD ["node", "-e", "require('http').get('http://localhost:3000/health', (r) => process.exit(r.statusCode === 200 ? 0 : 1))"]

# Start the app
CMD ["node", "app.js"]
