## 0.0.1-dev.2

- Add password reset functionality
  - Implement `createPasswordResetToken` - stores hashed password reset tokens
  - Implement `getPasswordResetToken` - retrieves and validates password reset tokens
  - Implement `revokePasswordResetTokens` - revokes all tokens for a user
  - Implement `updateUserPassword` - updates user password and salt

## 0.0.1-dev.1

- Initial release!
