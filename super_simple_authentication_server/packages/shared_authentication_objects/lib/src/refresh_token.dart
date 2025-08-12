import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'refresh_token.g.dart';

/// {@template refresh_token_request}
/// The request body for refreshing a token.
/// {@endtemplate}
@JsonSerializable()
class RefreshTokenRequest extends Equatable {
  /// {@macro refresh_token_request}
  const RefreshTokenRequest({required this.refreshToken});

  /// Creates a [RefreshTokenRequest] from a JSON object.
  factory RefreshTokenRequest.fromJson(Map<String, dynamic> json) =>
      _$RefreshTokenRequestFromJson(json);

  /// The refresh token to refresh.
  final String refreshToken;

  /// Converts a [RefreshTokenRequest] to a JSON object.
  Map<String, dynamic> toJson() => _$RefreshTokenRequestToJson(this);

  @override
  List<Object> get props => [refreshToken];
}

/// {@template refresh_token_response}
/// The response body for refreshing a token.
/// {@endtemplate}
@JsonSerializable()
class RefreshTokenResponse extends Equatable {
  /// {@macro refresh_token_response}
  const RefreshTokenResponse({this.token, this.refreshToken, this.error});

  /// Creates a [RefreshTokenResponse] from a JSON object.
  factory RefreshTokenResponse.fromJson(Map<String, dynamic> json) =>
      _$RefreshTokenResponseFromJson(json);

  /// Converts a [RefreshTokenResponse] to a JSON object.
  Map<String, dynamic> toJson() => _$RefreshTokenResponseToJson(this);

  /// The token to refresh.
  final String? token;

  /// The refresh token to refresh.
  final String? refreshToken;

  /// The error that occurred.
  final RefreshTokenError? error;

  @override
  List<Object?> get props => [token, refreshToken, error];
}

/// The error that occurs when refreshing a token.
enum RefreshTokenError {
  /// The token has been revoked.
  revoked,

  /// The token is invalid.
  invalid,

  /// The error is unknown.
  unknown,
}
