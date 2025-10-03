# Super Simple Authentication PostgreSQL Data Storage

A PostgreSQL-based implementation of the `DataStorage` interface for [Super Simple Authentication](https://github.com/mtwichel/super_simple_flutter_authentication). This package provides robust, production-ready storage for authentication data using [PostgreSQL](https://www.postgresql.org/) via the [postgres_builder](https://pub.dev/packages/postgres_builder) package.

## Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  super_simple_authentication_postgres_data_storage: ^0.0.1-dev.1
```

## Database Schema

Before using this package, you need to set up the required database schema. Create the following tables in your PostgreSQL database:

```sql
-- Create auth schema
CREATE SCHEMA IF NOT EXISTS auth;

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE,
    phone_number VARCHAR(50) UNIQUE,
    password TEXT,
    salt TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Sessions table
CREATE TABLE IF NOT EXISTS auth.sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    refreshed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Refresh tokens table
CREATE TABLE IF NOT EXISTS auth.refresh_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    session_id UUID NOT NULL REFERENCES auth.sessions(id) ON DELETE CASCADE,
    token TEXT NOT NULL UNIQUE,
    parent_token TEXT,
    revoked BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- OTPs table
CREATE TABLE IF NOT EXISTS auth.otps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    identifier VARCHAR(255) NOT NULL,
    channel VARCHAR(50) NOT NULL,
    otp TEXT NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    revoked BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone_number);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_token ON auth.refresh_tokens(token);
CREATE INDEX IF NOT EXISTS idx_otps_identifier_channel ON auth.otps(identifier, channel);
```

## Usage

### Basic Usage

Create an instance of `PostgresDataStorage` and initialize it with your database connection details:

```dart
import 'package:super_simple_authentication_postgres_data_storage/super_simple_authentication_postgres_data_storage.dart';

void main() async {
  final dataStorage = PostgresDataStorage();

  // Initialize with database connection
  await dataStorage.initialize(
    endpoint: Endpoint(
      host: 'localhost',
      database: 'my_auth_db',
      username: 'postgres',
      password: 'your_password',
    ),
  );

  // Use with your authentication server
  // ...
}
```

### Connection Settings

For production environments, you can customize the connection settings:

```dart
await dataStorage.initialize(
  endpoint: Endpoint(
    host: 'your-db-host.com',
    port: 5432,
    database: 'production_db',
    username: 'auth_user',
    password: 'secure_password',
  ),
  settings: ConnectionSettings(
    sslMode: SslMode.require, // Enforce SSL
    connectTimeout: Duration(seconds: 30),
    queryTimeout: Duration(seconds: 15),
  ),
);
```

### Using with an Existing PostgresBuilder

If you already have a `PostgresBuilder` instance in your application, you can use it directly:

```dart
import 'package:postgres_builder/postgres_builder.dart';

// Your existing database instance
final postgresBuilder = DirectPostgresBuilder();
await postgresBuilder.initialize(
  endpoint: Endpoint(
    host: 'localhost',
    database: 'my_db',
    username: 'postgres',
    password: 'password',
  ),
);

// Create storage with existing builder
final dataStorage = PostgresDataStorage.fromPostgresBuilder(postgresBuilder);
```

### Environment Variables

For better security, use environment variables for connection details:

```dart
import 'dart:io';

await dataStorage.initialize(
  endpoint: Endpoint(
    host: Platform.environment['DB_HOST'] ?? 'localhost',
    port: int.parse(Platform.environment['DB_PORT'] ?? '5432'),
    database: Platform.environment['DB_NAME'] ?? 'auth_db',
    username: Platform.environment['DB_USER'] ?? 'postgres',
    password: Platform.environment['DB_PASSWORD'] ?? '',
  ),
  settings: ConnectionSettings(
    sslMode: SslMode.require,
  ),
);
```

## Features

This storage implementation handles:

- User account creation and retrieval by email or phone number
- Session management with refresh tracking
- Refresh token storage, revocation, and token chaining
- OTP generation, validation, and expiration
- Automatic cleanup of expired/revoked tokens

## Example with Server

```dart
import 'package:dart_frog/dart_frog.dart';
import 'package:super_simple_authentication_postgres_data_storage/super_simple_authentication_postgres_data_storage.dart';
import 'package:super_simple_authentication_toolkit/super_simple_authentication_toolkit.dart';

Future<void> init() async {
  // Initialize PostgreSQL data storage
  final dataStorage = PostgresDataStorage();
  await dataStorage.initialize(
    endpoint: Endpoint(
      host: Platform.environment['DB_HOST'] ?? 'localhost',
      database: Platform.environment['DB_NAME'] ?? 'auth_db',
      username: Platform.environment['DB_USER'] ?? 'postgres',
      password: Platform.environment['DB_PASSWORD'] ?? '',
    ),
    settings: ConnectionSettings(
      sslMode: SslMode.require,
    ),
  );

  // Use with authentication middleware
  final authMiddleware = authenticationMiddleware(
    dataStorage: dataStorage,
    // ... other configuration
  );
}
```

## Production Considerations

For production deployments:

1. **Use SSL/TLS**: Always set `sslMode: SslMode.require` for secure connections
2. **Connection Pooling**: PostgresBuilder handles connection pooling automatically
3. **Timeouts**: Configure appropriate `connectTimeout` and `queryTimeout` values
4. **Monitoring**: Set up monitoring for database performance and connection health
5. **Backups**: Implement regular database backups
6. **Indexing**: The provided schema includes indexes for common queries
7. **Cleanup**: Consider implementing a scheduled job to clean up expired OTPs and revoked tokens

## Learn More

- [Super Simple Authentication](https://github.com/mtwichel/super_simple_flutter_authentication)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [postgres_builder Package](https://pub.dev/packages/postgres_builder)
