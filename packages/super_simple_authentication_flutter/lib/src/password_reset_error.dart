/// An error that occurred when resetting a password.
enum PasswordResetError {
  /// The password reset token is invalid.
  invalidToken,

  /// The password reset token has expired.
  expiredToken,

  /// An unknown error occurred.
  unknown,
}
