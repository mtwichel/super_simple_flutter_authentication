import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:shared_authentication_objects/shared_authentication_objects.dart';

part 'sign_in_with_credential.g.dart';

/// {@template sign_in_with_credential_request}
/// The request body for signing in with a credential.
/// {@endtemplate}
@JsonSerializable()
class SignInWithCredentialRequest extends Equatable {
  /// {@macro sign_in_with_credential_request}
  const SignInWithCredentialRequest({required this.credential});

  /// Converts a JSON object to a [SignInWithCredentialRequest] object.
  factory SignInWithCredentialRequest.fromJson(Map<String, dynamic> json) =>
      _$SignInWithCredentialRequestFromJson(json);

  /// Converts a [SignInWithCredentialRequest] object to a JSON object.
  Map<String, dynamic> toJson() => _$SignInWithCredentialRequestToJson(this);

  /// The credential to sign in with.
  final Credential credential;

  @override
  List<Object> get props => [credential];
}

/// {@template sign_in_with_credential_response}
/// The response body for signing in with a credential.
/// {@endtemplate}
@JsonSerializable()
class SignInWithCredentialResponse extends Equatable {
  /// {@macro sign_in_with_credential_response}
  const SignInWithCredentialResponse({
    this.token,
    this.refreshToken,
    this.error,
  });

  /// Converts a JSON object to a [SignInWithCredentialResponse] object.
  factory SignInWithCredentialResponse.fromJson(Map<String, dynamic> json) =>
      _$SignInWithCredentialResponseFromJson(json);

  /// Converts a [SignInWithCredentialResponse] object to a JSON object.
  Map<String, dynamic> toJson() => _$SignInWithCredentialResponseToJson(this);

  /// The access token.
  final String? token;

  /// The refresh token.
  final String? refreshToken;

  /// The error.
  final SignInError? error;

  @override
  List<Object?> get props => [token, refreshToken, error];
}
