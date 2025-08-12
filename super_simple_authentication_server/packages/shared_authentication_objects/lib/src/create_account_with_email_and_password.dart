import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:shared_authentication_objects/shared_authentication_objects.dart';

part 'create_account_with_email_and_password.g.dart';

/// {@template create_account_request}
/// The request body for creating a new account.
/// {@endtemplate}
@JsonSerializable()
class CreateAccountWithEmailAndPasswordRequest extends Equatable {
  /// {@macro create_account_request}
  const CreateAccountWithEmailAndPasswordRequest({
    required this.email,
    required this.password,
  });

  /// Creates a [CreateAccountWithEmailAndPasswordRequest] from a JSON object.
  factory CreateAccountWithEmailAndPasswordRequest.fromJson(
    Map<String, dynamic> json,
  ) =>
      _$CreateAccountWithEmailAndPasswordRequestFromJson(json);

  /// Converts a [CreateAccountWithEmailAndPasswordRequest] to a JSON object.
  Map<String, dynamic> toJson() =>
      _$CreateAccountWithEmailAndPasswordRequestToJson(this);

  /// The email of the account.
  final String email;

  /// The password of the account.
  final String password;

  @override
  List<Object> get props => [email, password];
}

/// {@template create_account_response}
/// The response body for creating a new account.
/// {@endtemplate}
@JsonSerializable()
class CreateAccountWithEmailAndPasswordResponse extends Equatable {
  /// {@macro create_account_response}
  const CreateAccountWithEmailAndPasswordResponse({
    this.token,
    this.refreshToken,
    this.error,
  });

  /// Creates a [CreateAccountWithEmailAndPasswordResponse] from a JSON object.
  factory CreateAccountWithEmailAndPasswordResponse.fromJson(
    Map<String, dynamic> json,
  ) =>
      _$CreateAccountWithEmailAndPasswordResponseFromJson(json);

  /// Converts a [CreateAccountWithEmailAndPasswordResponse] to a JSON object.
  Map<String, dynamic> toJson() =>
      _$CreateAccountWithEmailAndPasswordResponseToJson(this);

  /// The token of the account.
  final String? token;

  /// The refresh token of the account.
  final String? refreshToken;

  /// The error that occurred.
  final SignInError? error;

  @override
  List<Object?> get props => [token, refreshToken, error];
}
