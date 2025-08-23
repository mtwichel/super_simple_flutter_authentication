import 'package:super_simple_authentication_flutter/super_simple_authentication_flutter.dart';

/// {@template sign_in_exception}
/// An exception thrown when signing in fails.
/// {@endtemplate}
class SignInException implements Exception {
  /// {@macro sign_in_exception}
  const SignInException(this.error);

  /// The error that occurred.
  final SignInError error;
}
