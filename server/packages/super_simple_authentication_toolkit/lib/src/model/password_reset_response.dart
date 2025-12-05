import 'package:super_simple_authentication_toolkit/super_simple_authentication_toolkit.dart';

/// {@template password_reset_response}
/// A response for resetting a password.
/// {@endtemplate}
class PasswordResetResponse {
  /// {@macro password_reset_response}
  PasswordResetResponse({
    this.success,
    this.error,
  });

  /// Whether the password reset was successful.
  final bool? success;

  /// The error, if any.
  final PasswordResetError? error;

  /// Converts the response to a JSON map.
  Map<String, dynamic> toJson() => {
    'success': success,
    'error': error?.name,
  };
}
