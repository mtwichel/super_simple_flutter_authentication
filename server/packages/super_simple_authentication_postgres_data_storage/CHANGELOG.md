## 0.0.1-dev.3

- Add password reset functionality
  - Implement `createPasswordResetToken` - stores hashed password reset tokens
  - Implement `getPasswordResetToken` - retrieves and validates password reset tokens
  - Implement `revokePasswordResetTokens` - revokes all tokens for a user
  - Implement `updateUserPassword` - updates user password and salt
  - Add `auth.password_reset_tokens` table with indexes

## 0.0.1-dev.2

- Make Postgres write statements directly (instead of using postgres_builder)
- Add a setup function to write the schema directly to the database on startup

## 0.0.1-dev.1

- Initial release!
