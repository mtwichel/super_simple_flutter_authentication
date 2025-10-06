# Super Simple Authentication

A Dart Frog-based authentication server that provides comprehensive authentication services including email/password, OTP verification, third-party sign-in, and anonymous authentication. Supports flexible data storage options (in-memory, Hive, or PostgreSQL) and includes integrations for email and SMS services.

The goal of Super Simple Authentication is to provide a simple, yet comprehensive authentication solution for Dart and Flutter applications. It is designed to be easy to self-host and import into Flutter apps with very few dependencies. We don't want to "lock you in" to more than just simple authentication.

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

## Development

### Project Structure

- [super_simple_authentication_server](/server/README.md) - The pre-built authentication server. [Also available as a Docker image.](https://github.com/mtwichel/super_simple_flutter_authentication/pkgs/container/super_simple_flutter_authentication%2Fsuper-simple-auth-server)
- [super_simple_authentication_flutter](/packages/super_simple_authentication_flutter/README.md) - The flutter client package.
- [super_simple_authentication_toolkit](/server/packages/super_simple_authentication_toolkit/README.md) - The toolkit for the authentication server, used in the server. It allows you to either a) build your own authentication server or b) add authentication to your existing server, and c) validate JWT tokens in a Dart Frog server.
