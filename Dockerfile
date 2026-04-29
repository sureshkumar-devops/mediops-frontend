#-----------------------------------------------------------------------
# STAGE 1: BUILD
# This stage installs dependencies and builds the React production files.
#-----------------------------------------------------------------------
FROM node:20-alpine AS builder

# Set the working directory
WORKDIR /app

# Copy package files first to leverage Docker cache
COPY package*.json ./

# Install all dependencies (npm ci is faster and better for CI/CD)
RUN npm ci

# Copy the source, public folders, and production env
COPY public ./public
COPY src ./src
COPY .env.production ./

# Build the static React application
RUN npm run build

#-----------------------------------------------------------------------
# STAGE 2: PRODUCTION (Nginx)
# This stage serves the built files using a lightweight Nginx server.
#-----------------------------------------------------------------------
FROM nginx:1.25-alpine AS runner

# Set working directory to Nginx's serving path
WORKDIR /usr/share/nginx/html

# Create a system group and user to run Nginx securely
RUN addgroup -S pharma && adduser -S pharma -G pharma

# Copy the build output from Stage 1 to the Nginx html folder
COPY --from=builder /app/build .

# Copy your custom Nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Change ownership of the Nginx files and cache to the non-root user
RUN chown -R pharma:pharma /usr/share/nginx/html && \
    chown -R pharma:pharma /var/cache/nginx && \
    chown -R pharma:pharma /var/log/nginx && \
    chown -R pharma:pharma /etc/nginx/conf.d && \
    touch /var/run/nginx.pid && \
    chown pharma:pharma /var/run/nginx.pid

# Switch to the non-root user
USER pharma

# Document that the container listens on port 80
EXPOSE 80

# Run Nginx in the foreground
CMD ["nginx", "-g", "daemon off;"]
