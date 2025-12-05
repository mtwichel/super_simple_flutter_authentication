# Super Simple Authentication Server

A Dart Frog-based authentication server that provides comprehensive authentication services including email/password, OTP verification, third-party sign-in, and anonymous authentication. Supports flexible data storage options (in-memory, Hive, or PostgreSQL) and includes integrations for email and SMS services.

## Features

- **Email/Password Authentication**: Traditional sign-in and account creation
- **OTP Verification**: Email and SMS one-time password authentication
- **Third-party Sign-in**: Support for Google, Apple, and other OAuth providers
- **Anonymous Authentication**: Allow users to sign in without credentials
- **JWT Token Management**: Secure access and refresh token handling (symmetric HS256 or asymmetric RS256)
- **Session Management**: Database-backed user sessions
- **Secure Password Hashing**: PBKDF2-based password security with optional pepper
- **Flexible Data Storage**: In-memory, Hive (file-based), or PostgreSQL backends
- **Email Integration**: SendGrid support for email delivery
- **SMS Integration**: Twilio and TextBelt support for SMS delivery
- **Auto Schema Management**: Optional automatic database schema initialization

## Architecture

The server is built using:

- **Dart Frog**: High-performance HTTP server framework
- **Flexible Storage**: In-memory (development), Hive (file-based), or PostgreSQL
- **JWT**: Stateless authentication tokens with symmetric (HS256) or asymmetric (RS256) signing
- **Secure Storage**: PBKDF2 password hashing with optional pepper and encrypted token storage

## Installation

### Prerequisites

**For Docker (Recommended):**

- Docker and Docker Compose
- (Optional) PostgreSQL database - required for production, can use in-memory or Hive for development

**For Running from Source:**

- Dart SDK 3.7.0 or higher
- (Optional) PostgreSQL database - required for production, can use in-memory or Hive for development

**Optional (for both):**

- SendGrid API key for email OTP services
- SMS provider credentials (Twilio/TextBelt) for SMS OTP services
- Google/Apple OAuth credentials for third-party authentication

### Setup

You can run the authentication server either using Docker (recommended for production) or manually from source.

#### Option 1: Docker (Recommended)

We publish Docker images to GitHub Container Registry, making deployment simple and consistent.

1. **Pull the Docker image:**

```bash
docker pull ghcr.io/mtwichel/super_simple_flutter_authentication/super-simple-auth-server:latest
```

2. **Create an environment file:**

Create a file named `.env` with your configuration (see [Environment Variables](#environment-variables) below for all options):

```bash
# Minimal example
DATA_STORAGE_TYPE=postgres
POSTGRES_HOST=your-db-host
POSTGRES_PORT=5432
POSTGRES_DATABASE=auth_db
POSTGRES_USERNAME=auth_user
POSTGRES_PASSWORD=your_password
SHOULD_INITIALIZE_DATABASE_SCHEMA=true
JWT_SECRET_KEY=your_base64_secret_here
```

3. **Run the container:**

```bash
docker run -d \
  --name super-simple-auth-server \
  -p 8080:8080 \
  --env-file .env \
  ghcr.io/mtwichel/super_simple_flutter_authentication/super-simple-auth-server:latest
```

Or with docker-compose (recommended):

```yaml
version: "3.8"

services:
  auth-server:
    image: ghcr.io/mtwichel/super_simple_flutter_authentication/super-simple-auth-server:latest
    ports:
      - "8080:8080"
    environment:
      DATA_STORAGE_TYPE: postgres
      POSTGRES_HOST: postgres
      POSTGRES_PORT: 5432
      POSTGRES_DATABASE: auth_db
      POSTGRES_USERNAME: auth_user
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      SHOULD_INITIALIZE_DATABASE_SCHEMA: "true"
      JWT_SECRET_KEY: ${JWT_SECRET_KEY}
    depends_on:
      - postgres
    restart: unless-stopped

  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: auth_db
      POSTGRES_USER: auth_user
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped

volumes:
  postgres_data:
```

Then run:

```bash
docker-compose up -d
```

The server will be available at `http://localhost:8080`.

#### Option 2: Run from Source

1. **Clone and install dependencies:**

```bash
cd super_simple_authentication_server
dart pub get
```

2. **Set up environment variables:** {#environment-variables}

The server supports extensive configuration through environment variables. Choose the options that match your requirements.

##### Data Storage Configuration (Required)

Choose one of the following storage backends:

**Option 1: In-Memory Storage (Development Only)**

```bash
export DATA_STORAGE_TYPE=in_memory
```

⚠️ Data will be lost when the server restarts. Not suitable for production.

**Option 2: Hive Storage (File-Based)**

```bash
export DATA_STORAGE_TYPE=hive
export HIVE_DATA_PATH=/path/to/data/directory  # Optional, defaults to current directory
```

Suitable for single-server deployments with persistent file storage.

**Option 3: PostgreSQL Storage (Recommended for Production)**

```bash
export DATA_STORAGE_TYPE=postgres
export POSTGRES_HOST=localhost
export POSTGRES_PORT=5432
export POSTGRES_DATABASE=your_database
export POSTGRES_USERNAME=your_username
export POSTGRES_PASSWORD=your_password
export SHOULD_INITIALIZE_DATABASE_SCHEMA=true  # Set to true to auto-create tables on startup
```

##### JWT Token Configuration (Required)

Choose between symmetric or asymmetric token signing:

**Option 1: Symmetric Signing (HS256) - Simpler Setup**

```bash
# No JWT_HASHING_STRATEGY needed (symmetric is default)
export JWT_SECRET_KEY=your_base64_encoded_secret_key
```

Generate a secret key:

```bash
# Generate a random 256-bit key and encode it in base64url
openssl rand -base64 32
```

**Option 2: Asymmetric Signing (RS256) - More Secure for Distributed Systems**

```bash
export JWT_HASHING_STRATEGY=asymmetric
export JWT_RSA_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC7...
-----END PRIVATE KEY-----"
export JWT_RSA_PUBLIC_KEY="-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAu7...
-----END PUBLIC KEY-----"
export JWT_RSA_PUBLIC_KEY_URL=https://your-domain.com/.well-known/jwks.json  # Optional: JWKS endpoint URL
```

Generate RSA key pair:

```bash
# Generate private key
openssl genrsa -out private_key.pem 2048

# Extract public key
openssl rsa -in private_key.pem -pubout -out public_key.pem

# Format for environment variable (remove newlines or keep with quotes)
cat private_key.pem
cat public_key.pem
```

##### Password Security (Optional)

```bash
export PASSWORD_PEPPER=your_base64_encoded_pepper  # Additional secret for password hashing
```

The pepper adds an extra layer of security to password hashing. Generate it like the JWT secret:

```bash
openssl rand -base64 32
```

##### Third-Party Authentication (Optional)

**Google Sign-In**

```bash
export GOOGLE_CLIENT_ID=your_google_client_id.apps.googleusercontent.com
```

**Apple Sign-In**

```bash
export APPLE_BUNDLE_ID=com.yourcompany.yourapp  # Required: iOS/macOS bundle ID
export APPLE_SERVICE_ID=com.yourcompany.yourapp.service  # Optional: For web/Android
```

##### Email Service Integration (Optional)

Required for email OTP verification:

```bash
# Currently supports SendGrid
export SENDGRID_API_KEY=your_sendgrid_api_key
export SENDGRID_BASE_URL=https://api.sendgrid.com  # Optional, defaults to SendGrid API
```

##### Password Reset Email Configuration (Optional)

Required for password reset functionality:

```bash
# Required: Base URL for password reset links
export PASSWORD_RESET_BASE_URL=https://yourapp.com

# Optional: Email configuration
export PASSWORD_RESET_FROM_EMAIL=noreply@yourapp.com  # Defaults to 'noreply@online-service.com'
export PASSWORD_RESET_FROM_NAME=Your App Name  # Defaults to 'Online Service'
export PASSWORD_RESET_EMAIL_SUBJECT=Reset your password  # Optional custom subject

# Optional: Sendgrid template support
export PASSWORD_RESET_TEMPLATE_ID=d-1234567890abcdef  # Sendgrid dynamic template ID
```

When `PASSWORD_RESET_TEMPLATE_ID` is set, the handler will use Sendgrid dynamic templates instead of plain text emails. The template should include these variables: `resetLink`, `fromName`, `expiresInHours`.

##### SMS Service Integration (Optional)

Required for SMS OTP verification. Choose one provider:

**Twilio**

```bash
export TWILIO_ACCOUNT_SID=your_twilio_account_sid
export TWILIO_AUTH_TOKEN=your_twilio_auth_token
export TWILIO_MESSAGING_SERVICE_SID=your_messaging_service_sid
```

**TextBelt**

```bash
export TEXTBELT_API_KEY=your_textbelt_api_key
```

##### Testing/Development (Optional)

```bash
export TESTING_EMAIL=test@example.com
export TESTING_PHONE_NUMBER=+1234567890
export TESTING_OTP=123456
```

When these are set, the server will use the fixed `TESTING_OTP` for the specified email/phone instead of generating random OTPs. This is useful for automated testing and development.

##### Complete Example Configuration

**Minimal Production Setup (PostgreSQL + Symmetric JWT)**

```bash
# Storage
export DATA_STORAGE_TYPE=postgres
export POSTGRES_HOST=db.example.com
export POSTGRES_PORT=5432
export POSTGRES_DATABASE=auth_db
export POSTGRES_USERNAME=auth_user
export POSTGRES_PASSWORD=secure_password
export SHOULD_INITIALIZE_DATABASE_SCHEMA=true

# JWT
export JWT_SECRET_KEY=your_base64_secret_here
```

**Full Production Setup (PostgreSQL + Asymmetric JWT + All Providers)**

```bash
# Storage
export DATA_STORAGE_TYPE=postgres
export POSTGRES_HOST=db.example.com
export POSTGRES_PORT=5432
export POSTGRES_DATABASE=auth_db
export POSTGRES_USERNAME=auth_user
export POSTGRES_PASSWORD=secure_password
export SHOULD_INITIALIZE_DATABASE_SCHEMA=true

# JWT (Asymmetric)
export JWT_HASHING_STRATEGY=asymmetric
export JWT_RSA_PRIVATE_KEY="$(cat private_key.pem)"
export JWT_RSA_PUBLIC_KEY="$(cat public_key.pem)"
export JWT_RSA_PUBLIC_KEY_URL=https://auth.example.com/.well-known/jwks.json

# Security
export PASSWORD_PEPPER=your_base64_pepper_here

# Third-party Auth
export GOOGLE_CLIENT_ID=your_google_client_id.apps.googleusercontent.com
export APPLE_BUNDLE_ID=com.yourcompany.yourapp
export APPLE_SERVICE_ID=com.yourcompany.yourapp.service

# Email/SMS
export SENDGRID_API_KEY=your_sendgrid_api_key
export TWILIO_ACCOUNT_SID=your_twilio_sid
export TWILIO_AUTH_TOKEN=your_twilio_token
export TWILIO_MESSAGING_SERVICE_SID=your_messaging_service_sid
```

3. **Set up database schema (PostgreSQL only):**

If using PostgreSQL with `SHOULD_INITIALIZE_DATABASE_SCHEMA=false`, or want to manually create the schema, run:

```sql
-- This SQL is automatically executed if SHOULD_INITIALIZE_DATABASE_SCHEMA=true
-- Create auth schema
CREATE SCHEMA IF NOT EXISTS auth;

-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE,
    phone_number VARCHAR(20) UNIQUE,
    password TEXT,
    salt TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Sessions table
CREATE TABLE auth.sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP DEFAULT NOW() + INTERVAL '30 days'
);

-- Refresh tokens table
CREATE TABLE auth.refresh_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    session_id UUID REFERENCES auth.sessions(id) ON DELETE CASCADE,
    token TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP DEFAULT NOW() + INTERVAL '30 days'
);

-- OTPs table
CREATE TABLE auth.otps (
    id SERIAL PRIMARY KEY,
    identifier VARCHAR(255) NOT NULL,
    otp TEXT NOT NULL,
    channel VARCHAR(10) NOT NULL, -- 'email' or 'phone'
    expires_at TIMESTAMP NOT NULL,
    revoked BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW()
);
```

4. **Run the server:**

```bash
dart run main.dart
```

The server will start on `http://localhost:8080` by default.

## API Endpoints

### Authentication Endpoints

#### Email/Password Authentication

- `POST /auth/email-password/sign-in` - Sign in with email and password
- `POST /auth/email-password/create-account` - Create new account with email and password

#### OTP Authentication

- `POST /auth/request-otp` - Send OTP via email or SMS
- `POST /auth/verify-otp` - Verify OTP and authenticate user

#### Third-party Authentication

- `POST /auth/sign-in-with-credential` - Sign in with third-party credentials

#### Anonymous Authentication

- `POST /auth/sign-in-anonymously` - Create anonymous user session

#### Token Management

- `POST /auth/refresh-token` - Refresh access token using refresh token

## Security Features

### Password Security

- PBKDF2 hashing with random salts
- Configurable iteration counts
- Secure password storage

### Token Security

- JWT tokens with configurable expiration
- Refresh token rotation
- Session-based token management

### OTP Security

- Time-based expiration (10 minutes default)
- Secure hashing of OTP codes
- Single-use token validation

### Request Security

- CORS support
- Request validation
- Error handling without information leakage

### Adding New Authentication Methods

1. Create a new handler in `lib/src/handlers/`
2. Add the handler to the exports in `handlers.dart`
3. Implement the authentication logic
4. Add corresponding request/response models to shared objects

### Testing

The server includes support for testing with predefined credentials:

```bash
export TESTING_EMAIL=test@example.com
export TESTING_PHONE_NUMBER=+1234567890
export TESTING_OTP=123456
```

When these environment variables are set, the server will use the testing OTP instead of sending real emails/SMS.

### Running Tests

```bash
dart test
```

## Deployment

### Docker Deployment

We publish production-ready Docker images to [GitHub Container Registry](https://github.com/mtwichel/super_simple_flutter_authentication/pkgs/container/super_simple_flutter_authentication%2Fsuper-simple-auth-server).

**Quick Start:**

```bash
# Pull the latest image
docker pull ghcr.io/mtwichel/super_simple_flutter_authentication/super-simple-auth-server:latest

# Run with environment variables
docker run -d \
  --name auth-server \
  -p 8080:8080 \
  -e DATA_STORAGE_TYPE=postgres \
  -e POSTGRES_HOST=your-db \
  -e POSTGRES_DATABASE=auth_db \
  -e POSTGRES_USERNAME=auth_user \
  -e POSTGRES_PASSWORD=your_password \
  -e JWT_SECRET_KEY=your_secret \
  ghcr.io/mtwichel/super_simple_flutter_authentication/super-simple-auth-server:latest
```

**Production Deployment with Docker Compose:**

See the complete docker-compose example in the [Setup](#setup) section above, which includes PostgreSQL and all necessary configuration.

### Environment Variables for Production

See the complete environment variable reference in the [Environment Variables](#environment-variables) section. At minimum, you need:

**Required:**

- Data storage configuration (`DATA_STORAGE_TYPE` and related variables)
- JWT configuration (`JWT_SECRET_KEY` for symmetric or `JWT_RSA_PRIVATE_KEY`/`JWT_RSA_PUBLIC_KEY` for asymmetric)

**Optional but Recommended:**

- `PASSWORD_PEPPER` - Additional password security
- `SHOULD_INITIALIZE_DATABASE_SCHEMA=true` - For PostgreSQL auto-setup

**Optional for Features:**

- `SENDGRID_API_KEY` - Email OTP support
- `TWILIO_*` or `TEXTBELT_API_KEY` - SMS OTP support
- `GOOGLE_CLIENT_ID` - Google sign-in support
- `APPLE_BUNDLE_ID` - Apple sign-in support
- `API_KEY` - API key for authentication
- `ALLOWED_ORIGIN` - Allowed origin for CORS

## Monitoring and Logging

The server includes built-in logging for:

- Database queries (in debug mode)
- Authentication attempts
- OTP generation (in debug mode)
- Error conditions

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions:

1. Check the documentation
2. Review existing issues
3. Create a new issue with detailed information

## Related Packages

- `super_simple_authentication_flutter` - Flutter client package
- `shared_authentication_objects` - Shared data models
- `api_client` - HTTP client utilities
