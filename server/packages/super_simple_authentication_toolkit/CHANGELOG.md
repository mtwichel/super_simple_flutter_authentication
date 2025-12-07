## 0.0.1-dev.7

- Use `EmailProvider` interface instead of `Sendgrid`
- **Breaking change**: Remove `debugOtps` parameter from `sendOtpHandler` in favor of `FakeEmailService` for testing

## 0.0.1-dev.6

- Add `EmailProvider` interfaces
- Add `FakeEmailService` for testing
- Add `FakeSms` for testing

## 0.0.1-dev.5

- Add password reset functionality
  - Add `sendPasswordResetEmailHandler` for sending password reset emails via Sendgrid
  - Add `resetPasswordHandler` for resetting passwords with secure tokens
  - Add password reset token utilities (`createPasswordResetToken`, `hashPasswordResetToken`)
  - Add password reset models (`PasswordResetResponse`, `PasswordResetError`)
  - Extend `DataStorage` interface with password reset token methods:
    - `createPasswordResetToken` - creates a hashed password reset token
    - `getPasswordResetToken` - retrieves and validates a password reset token
    - `revokePasswordResetTokens` - revokes all tokens for a user
    - `updateUserPassword` - updates a user's password and salt
  - Support for Sendgrid dynamic templates in password reset emails
  - Security best practices: token hashing, expiration, one-time use, email enumeration prevention

## 0.0.1-dev.4

- Fix CORS middleware to return 200 for OPTIONS requests

## 0.0.1-dev.3

- Add CORS middleware
- Fixed sign in error enum

## 0.0.1-dev.2

- Standardize sign in response format

## 0.0.1-dev.1

- Initial release!
