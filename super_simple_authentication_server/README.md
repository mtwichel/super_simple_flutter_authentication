# Super Simple Authentication Server

A Dart Frog-based authentication server that provides comprehensive authentication services including email/password, OTP verification, third-party sign-in, and anonymous authentication. Built with PostgreSQL for data persistence and includes integrations for email and SMS services.

## Features

- **Email/Password Authentication**: Traditional sign-in and account creation
- **OTP Verification**: Email and SMS one-time password authentication
- **Third-party Sign-in**: Support for Google, Apple, and other OAuth providers
- **Anonymous Authentication**: Allow users to sign in without credentials
- **JWT Token Management**: Secure access and refresh token handling
- **Session Management**: Database-backed user sessions
- **Secure Password Hashing**: PBKDF2-based password security
- **Email Integration**: SendGrid support for email delivery
- **SMS Integration**: Twilio and TextBelt support for SMS delivery
- **PostgreSQL Database**: Robust data persistence with schema management

## Architecture

The server is built using:

- **Dart Frog**: High-performance HTTP server framework
- **PostgreSQL**: Primary database for user data and sessions
- **JWT**: Stateless authentication tokens
- **Secure Storage**: Encrypted password and token storage

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

## Installation

### Prerequisites

- Dart SDK 3.7.0 or higher
- PostgreSQL database
- (Optional) SendGrid API key for email services
- (Optional) SMS provider credentials (Twilio/TextBelt)

### Setup

1. **Clone and install dependencies:**

```bash
cd super_simple_authentication_server
dart pub get
```

2. **Set up environment variables:**

```bash
# Database configuration
export POSTGRES_HOST=localhost
export POSTGRES_PORT=5432
export POSTGRES_DATABASE=your_database
export POSTGRES_USERNAME=your_username
export POSTGRES_PASSWORD=your_password

# Email service (optional)
export SENDGRID_API_KEY=your_sendgrid_api_key

# SMS service (optional)
export TWILIO_ACCOUNT_SID=your_twilio_sid
export TWILIO_AUTH_TOKEN=your_twilio_token
export TWILIO_PHONE_NUMBER=your_twilio_phone

# Testing (optional)
export TESTING_EMAIL=test@example.com
export TESTING_PHONE_NUMBER=+1234567890
export TESTING_OTP=123456
```

3. **Set up database schema:**

```sql
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

## Usage Examples

### Email/Password Sign In

```bash
curl -X POST http://localhost:8080/auth/email-password/sign-in \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "password123"
  }'
```

**Response:**

```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "refresh_token_here",
  "error": null
}
```

### Create Account

```bash
curl -X POST http://localhost:8080/auth/email-password/create-account \
  -H "Content-Type: application/json" \
  -d '{
    "email": "newuser@example.com",
    "password": "password123"
  }'
```

### Send Email OTP

```bash
curl -X POST http://localhost:8080/auth/request-otp \
  -H "Content-Type: application/json" \
  -d '{
    "identifier": "user@example.com",
    "type": "email"
  }'
```

### Verify OTP

```bash
curl -X POST http://localhost:8080/auth/verify-otp \
  -H "Content-Type: application/json" \
  -d '{
    "identifier": "user@example.com",
    "otp": "123456",
    "type": "email"
  }'
```

### Anonymous Sign In

```bash
curl -X POST http://localhost:8080/auth/sign-in-anonymously \
  -H "Content-Type: application/json"
```

### Third-party Sign In

```bash
curl -X POST http://localhost:8080/auth/sign-in-with-credential \
  -H "Content-Type: application/json" \
  -d '{
    "credential": {
      "type": "google",
      "token": "google_id_token_here"
    }
  }'
```

## Configuration

### Email Service Integration

The server supports SendGrid for email delivery. Configure with:

```dart
// In your server setup
final sendgrid = Sendgrid(
  apiKey: Platform.environment['SENDGRID_API_KEY']!,
  baseUrl: 'https://api.sendgrid.com',
);
```

### SMS Service Integration

Multiple SMS providers are supported:

#### Twilio

```dart
final twilio = Twilio(
  accountSid: Platform.environment['TWILIO_ACCOUNT_SID']!,
  authToken: Platform.environment['TWILIO_AUTH_TOKEN']!,
  phoneNumber: Platform.environment['TWILIO_PHONE_NUMBER']!,
);
```

#### TextBelt

```dart
final textbelt = TextBelt(
  apiKey: Platform.environment['TEXTBELT_API_KEY']!,
);
```

### Third-party Authentication

#### Google Sign-In

Configure Google OAuth credentials and use the `signInWithGoogle` integration.

#### Apple Sign-In

Configure Apple Sign-In credentials and use the `signInWithApple` integration.

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

## Development

### Project Structure

```
super_simple_authentication_server/
├── lib/
│   └── src/
│       ├── handlers/           # Request handlers for each endpoint
│       ├── integrations/       # Third-party service integrations
│       ├── authentication_middleware.dart
│       ├── create_jwt.dart
│       ├── password_hashing.dart
│       └── ...
├── packages/
│   └── shared_authentication_objects/  # Shared data models
├── main.dart                   # Server entry point
└── pubspec.yaml
```

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

Create a `Dockerfile`:

```dockerfile
FROM dart:stable AS build

WORKDIR /app
COPY pubspec.* ./
RUN dart pub get

COPY . .
RUN dart compile exe main.dart -o server

FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/server /app/server

EXPOSE 8080
ENTRYPOINT ["/app/server"]
```

### Environment Variables for Production

```bash
# Database
POSTGRES_HOST=your-db-host
POSTGRES_PORT=5432
POSTGRES_DATABASE=production_db
POSTGRES_USERNAME=db_user
POSTGRES_PASSWORD=secure_password

# Services
SENDGRID_API_KEY=your_production_sendgrid_key
TWILIO_ACCOUNT_SID=your_twilio_sid
TWILIO_AUTH_TOKEN=your_twilio_token
TWILIO_PHONE_NUMBER=your_twilio_number

# Security
JWT_SECRET=your_jwt_secret_key
```

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
