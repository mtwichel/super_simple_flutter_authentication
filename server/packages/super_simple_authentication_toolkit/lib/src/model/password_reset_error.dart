/// {@template password_reset_error}
/// An error that can occur during password reset.
/// {@endtemplate}
enum PasswordResetError {
  /// The password reset token is invalid.
  invalidToken,

  /// The password reset token has expired.
  expiredToken,

  /// An unknown error occurred.
  unknown,
}
