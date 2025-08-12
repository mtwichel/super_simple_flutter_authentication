import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'sign_in_with_email_and_password.g.dart';

/// {@template sign_in_request}
/// The request body for signing in.
/// {@endtemplate}
@JsonSerializable()
class SignInWithEmailAndPasswordRequest extends Equatable {
  /// {@macro sign_in_request}
  const SignInWithEmailAndPasswordRequest({
    required this.email,
    required this.password,
  });

  /// Creates a [SignInWithEmailAndPasswordRequest] from a JSON object.
  factory SignInWithEmailAndPasswordRequest.fromJson(
    Map<String, dynamic> json,
  ) =>
      _$SignInWithEmailAndPasswordRequestFromJson(json);

  /// Converts a [SignInWithEmailAndPasswordRequest] to a JSON object.
  Map<String, dynamic> toJson() =>
      _$SignInWithEmailAndPasswordRequestToJson(this);

  /// The email of the account.
  final String email;

  /// The password of the account.
  final String password;

  @override
  List<Object> get props => [email, password];
}

/// {@template sign_in_response}
/// The response body for signing in.
/// {@endtemplate}
@JsonSerializable()
class SignInWithEmailAndPasswordResponse extends Equatable {
  /// {@macro sign_in_response}
  const SignInWithEmailAndPasswordResponse({
    this.token,
    this.error,
    this.refreshToken,
  });

  /// Creates a [SignInWithEmailAndPasswordResponse] from a JSON object.
  factory SignInWithEmailAndPasswordResponse.fromJson(
    Map<String, dynamic> json,
  ) =>
      _$SignInWithEmailAndPasswordResponseFromJson(json);

  /// Converts a [SignInWithEmailAndPasswordResponse] to a JSON object.
  Map<String, dynamic> toJson() =>
      _$SignInWithEmailAndPasswordResponseToJson(this);

  /// The token of the account.
  final String? token;

  /// The error that occurred.
  final SignInError? error;

  /// The refresh token of the account.
  final String? refreshToken;

  @override
  List<Object?> get props => [token, error, refreshToken];
}

/// The error that occurs when signing in.
enum SignInError {
  /// The credentials are invalid.
  invalidCredentials,

  /// The user was not found.
  userNotFound,

  /// The server error.
  serverError,

  /// The OTP is invalid.
  otpInvalid,

  /// The 3rd party credential is invalid.
  invalid3rdPartyCredential,

  /// The sign in was aborted.
  aborted,

  /// The error is unknown.
  unknown,
}
