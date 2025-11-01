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

# Create minimal passwd/group files for non-root user support in scratch image
# Using numeric UID/GID 65534 (nobody/nogroup) for minimal scratch image
RUN mkdir -p /app/etc && \
    echo "nobody:x:65534:65534:Nobody:/:/sbin/nologin" > /app/etc/passwd && \
    echo "nogroup:x:65534:" > /app/etc/group

# Stage 2: Create minimal runtime image from scratch
FROM scratch

# Copy minimal runtime dependencies from Dart SDK
# This includes the necessary C libraries that the compiled binary needs
COPY --from=build /runtime/ /

# Copy CA certificates for HTTPS requests (critical for auth server)
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Copy minimal passwd/group files for non-root user support
COPY --from=build /app/etc/passwd /etc/passwd
COPY --from=build /app/etc/group /etc/group

# Copy the compiled binary
COPY --from=build /app/build/bin/server /app/bin/server

# Use numeric UID/GID for non-root user (nobody = 65534)
# This works even in scratch without useradd
USER 65534:65534

# Expose port
EXPOSE 8080

# Note: In scratch images, HEALTHCHECK requires an executable.
# For production, use external health checks from your orchestrator:
# - Docker Compose: Use httpGet with a health endpoint
# - Kubernetes: Use livenessProbe with httpGet or tcpSocket
# - Docker Swarm: Use --health-cmd at service level

# Add labels for better container management
LABEL org.opencontainers.image.title="Super Simple Authentication Server"
LABEL org.opencontainers.image.description="Authentication server built with Dart Frog"
LABEL org.opencontainers.image.vendor="Marcus Twichel"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.security="Minimal attack surface with scratch base image and non-root user"

# Start the server
CMD ["/app/bin/server"]