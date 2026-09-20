# Stage 1: Build the React Application
FROM node:22-alpine AS builder

WORKDIR /app

# Copy package files and install dependencies cleanly
COPY package*.json ./
RUN npm ci

# Copy source files and build
COPY . .
RUN npm run build

# Stage 2: Production Web Server
FROM nginx:alpine

# Upgrade packages to patch OS-level Alpine vulnerabilities
RUN apk update && apk upgrade --no-cache

# Copy built static files from builder stage
COPY --from=builder /app/build /usr/share/nginx/html

# Expose default HTTP port
EXPOSE 80

# Run Nginx in foreground
CMD ["nginx", "-g", "daemon off;"]