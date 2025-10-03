# Multi-stage Dockerfile for Super Simple Authentication Server
# Stage 1: Build the application
FROM dart:stable AS build

# Set working directory
WORKDIR /app

# Copy pubspec files first for better layer caching
COPY pubspec.yaml pubspec.lock ./

# Install dependencies
RUN dart pub get

# Copy source code
COPY . .

# Install dart_frog_cli globally
RUN dart pub global activate dart_frog_cli

# Generate production build
RUN dart pub global run dart_frog_cli:dart_frog build

# Compile the application to native executable
RUN dart compile exe build/bin/server.dart -o build/bin/server

# Stage 2: Create minimal runtime image
FROM debian:bookworm-slim AS runtime

# Install only required runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Create non-root user for security
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Set working directory
WORKDIR /app

# Copy the compiled binary
COPY --from=build /app/build/bin/server /app/bin/server

# Change ownership to non-root user
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose port (adjust if your app uses a different port)
EXPOSE 8080

# Add health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/ || exit 1

# Add labels for better container management
LABEL org.opencontainers.image.title="Super Simple Authentication Server"
LABEL org.opencontainers.image.description="Authentication server built with Dart Frog"
LABEL org.opencontainers.image.vendor="Marcus Twichel"
LABEL org.opencontainers.image.licenses="MIT"

# Start the server
CMD ["/app/bin/server"]