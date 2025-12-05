import 'package:super_simple_authentication_flutter/super_simple_authentication_flutter.dart';

/// {@template password_reset_exception}
/// An exception thrown when password reset fails.
/// {@endtemplate}
class PasswordResetException implements Exception {
  /// {@macro password_reset_exception}
  const PasswordResetException(this.error);

  /// The error that occurred.
  final PasswordResetError error;
}
