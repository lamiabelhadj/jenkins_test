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
# Stage 2: Production image with kubectl
# -----------------------------
FROM node:20-bookworm-slim

# Install kubectl (modern keyring method)
USER root
RUN apt-get update && apt-get install -y curl gpg apt-transport-https \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
       | gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] \
       https://apt.kubernetes.io/ kubernetes-xenial main" \
       > /etc/apt/sources.list.d/kubernetes.list \
    && apt-get update && apt-get install -y kubectl \
    && rm -rf /var/lib/apt/lists/*

# Copy app from builder
WORKDIR /usr/src/app
COPY --from=builder /usr/src/app ./

# Expose port
EXPOSE 3000

# Healthcheck (same as yours)
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD ["node", "-e", "require('http').get('http://localhost:3000/health', (r) => process.exit(r.statusCode === 200 ? 0 : 1))"]

# Start the app
CMD ["node", "app.js"]
