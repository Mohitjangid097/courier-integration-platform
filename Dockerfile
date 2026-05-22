# ── Stage 1: Build ────────────────────────────────────────────────────────────
FROM node:22-alpine AS builder

WORKDIR /app

# Build tools required to compile better-sqlite3 native bindings
RUN apk add --no-cache python3 make g++

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

# ── Stage 2: Production ───────────────────────────────────────────────────────
FROM node:22-alpine AS production

WORKDIR /app

# Same build tools needed to recompile native bindings for production env
RUN apk add --no-cache python3 make g++

# Install only production dependencies (recompiles better-sqlite3)
COPY package*.json ./
RUN npm ci --omit=dev

# Copy compiled app from builder stage
COPY --from=builder /app/dist ./dist

# Directory for persistent SQLite database file
RUN mkdir -p /app/data

EXPOSE 8080

ENV NODE_ENV=production
ENV DB_PATH=/app/data/courier_integration.db

CMD ["node", "dist/main.js"]
