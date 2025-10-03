# Docker Deployment Guide

This document describes how to build and deploy the Super Simple Authentication Server using Docker.

## 🐳 Docker Image

The application is containerized using a multi-stage Docker build that creates a minimal, secure runtime image.

### Features

- **Multi-stage build**: Separates build and runtime environments
- **Security**: Runs as non-root user
- **Minimal footprint**: Uses Debian slim base image
- **Health checks**: Built-in health monitoring
- **Multi-platform**: Supports AMD64 and ARM64 architectures

## 🚀 Quick Start

### Using GitHub Container Registry

```bash
# Pull the latest image
docker pull ghcr.io/your-org/super-simple-auth-server:latest

# Run the container
docker run -p 8080:8080 ghcr.io/your-org/super-simple-auth-server:latest
```

### Building Locally

```bash
# Build the image
docker build -t super-simple-auth-server .

# Run the container
docker run -p 8080:8080 super-simple-auth-server
```

## 🔧 Configuration

The server can be configured using environment variables:

```bash
# Data storage configuration
docker run -p 8080:8080 \
  -e DATA_STORAGE_TYPE=in_memory \
  super-simple-auth-server

# For Hive storage
docker run -p 8080:8080 \
  -e DATA_STORAGE_TYPE=hive \
  -e HIVE_DATA_PATH=/app/data \
  -v hive_data:/app/data \
  super-simple-auth-server

# For PostgreSQL storage
docker run -p 8080:8080 \
  -e DATA_STORAGE_TYPE=postgres \
  -e POSTGRES_HOST=postgres-server \
  -e POSTGRES_PORT=5432 \
  -e POSTGRES_DATABASE=auth_db \
  -e POSTGRES_USERNAME=user \
  -e POSTGRES_PASSWORD=password \
  super-simple-auth-server
```

## 🏗️ Docker Compose

For development or testing, use Docker Compose:

```yaml
version: "3.8"

services:
  auth-server:
    image: ghcr.io/your-org/super-simple-auth-server:latest
    ports:
      - "8080:8080"
    environment:
      - DATA_STORAGE_TYPE=postgres
      - POSTGRES_HOST=postgres
      - POSTGRES_DATABASE=auth_db
      - POSTGRES_USERNAME=auth_user
      - POSTGRES_PASSWORD=auth_password
    depends_on:
      - postgres

  postgres:
    image: postgres:15-alpine
    environment:
      - POSTGRES_DB=auth_db
      - POSTGRES_USER=auth_user
      - POSTGRES_PASSWORD=auth_password
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

## 🔒 Security Features

- **Non-root execution**: Container runs as `appuser` (UID 1000)
- **Minimal base image**: Uses Debian slim to reduce attack surface
- **No shell access**: No shell or package manager in runtime image
- **Health checks**: Monitors application health
- **Security scanning**: Automated vulnerability scanning in CI/CD

## 📊 Monitoring

The container includes built-in health checks:

```bash
# Check container health
docker ps

# View health check logs
docker inspect <container_id> | grep -A 10 Health
```

## 🚀 Production Deployment

### Kubernetes

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: auth-server
spec:
  replicas: 3
  selector:
    matchLabels:
      app: auth-server
  template:
    metadata:
      labels:
        app: auth-server
    spec:
      containers:
        - name: auth-server
          image: ghcr.io/your-org/super-simple-auth-server:latest
          ports:
            - containerPort: 8080
          env:
            - name: DATA_STORAGE_TYPE
              value: "postgres"
            - name: POSTGRES_HOST
              value: "postgres-service"
          resources:
            requests:
              memory: "128Mi"
              cpu: "100m"
            limits:
              memory: "256Mi"
              cpu: "200m"
          livenessProbe:
            httpGet:
              path: /
              port: 8080
            initialDelaySeconds: 30
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /
              port: 8080
            initialDelaySeconds: 5
            periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: auth-server-service
spec:
  selector:
    app: auth-server
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
  type: LoadBalancer
```

### Docker Swarm

```yaml
version: "3.8"

services:
  auth-server:
    image: ghcr.io/your-org/super-simple-auth-server:latest
    ports:
      - "8080:8080"
    environment:
      - DATA_STORAGE_TYPE=postgres
      - POSTGRES_HOST=postgres
    deploy:
      replicas: 3
      update_config:
        parallelism: 1
        delay: 10s
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
    networks:
      - auth-network

  postgres:
    image: postgres:15-alpine
    environment:
      - POSTGRES_DB=auth_db
      - POSTGRES_USER=auth_user
      - POSTGRES_PASSWORD=auth_password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    deploy:
      placement:
        constraints:
          - node.role == manager
    networks:
      - auth-network

networks:
  auth-network:
    driver: overlay
    attachable: true

volumes:
  postgres_data:
```

## 🔍 Troubleshooting

### Common Issues

1. **Port already in use**

   ```bash
   # Check what's using the port
   lsof -i :8080

   # Use a different port
   docker run -p 8081:8080 super-simple-auth-server
   ```

2. **Permission denied**

   ```bash
   # Ensure the container has proper permissions
   docker run --user 1000:1000 super-simple-auth-server
   ```

3. **Database connection issues**

   ```bash
   # Check environment variables
   docker exec <container_id> env | grep POSTGRES

   # Test database connectivity
   docker run --rm postgres:15-alpine pg_isready -h postgres-host
   ```

### Logs

```bash
# View container logs
docker logs <container_id>

# Follow logs in real-time
docker logs -f <container_id>

# View logs with timestamps
docker logs -t <container_id>
```

## 📈 Performance Tuning

### Resource Limits

```bash
# Run with resource constraints
docker run -p 8080:8080 \
  --memory=256m \
  --cpus=1.0 \
  super-simple-auth-server
```

### Optimization Tips

1. **Use specific tags**: Avoid `latest` in production
2. **Enable caching**: Use build cache for faster builds
3. **Monitor resources**: Set appropriate limits
4. **Health checks**: Implement proper health endpoints
5. **Logging**: Configure structured logging

## 🔄 CI/CD Integration

The Docker image is automatically built and published via GitHub Actions:

- **Triggers**: Push to main/develop, tags, pull requests
- **Multi-platform**: AMD64 and ARM64 support
- **Security**: Automated vulnerability scanning
- **Caching**: Optimized build caching
- **Registry**: Published to GitHub Container Registry

See `.github/workflows/publish_image.yaml` for the complete CI/CD pipeline.
