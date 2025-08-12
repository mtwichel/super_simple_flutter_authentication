import 'package:shared_authentication_objects/shared_authentication_objects.dart';

/// {@template sign_in_exception}
/// An exception thrown when signing in fails.
/// {@endtemplate}
class SignInException implements Exception {
  /// {@macro sign_in_exception}
  const SignInException(this.error);

  /// The error that occurred.
  final SignInError error;
}
