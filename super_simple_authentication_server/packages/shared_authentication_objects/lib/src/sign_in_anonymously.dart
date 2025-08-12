import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:shared_authentication_objects/shared_authentication_objects.dart';

part 'sign_in_anonymously.g.dart';

/// {@template sign_in_anonymously_response}
/// Response for signing in anonymously.
/// {@endtemplate}
@JsonSerializable()
class SignInAnonymouslyResponse extends Equatable {
  /// {@macro sign_in_anonymously_response}
  const SignInAnonymouslyResponse({
    this.token,
    this.refreshToken,
    this.error,
  });

  /// Converts a JSON map to a [SignInAnonymouslyResponse].
  factory SignInAnonymouslyResponse.fromJson(Map<String, dynamic> json) =>
      _$SignInAnonymouslyResponseFromJson(json);

  /// Converts the [SignInAnonymouslyResponse] to a JSON map.
  Map<String, dynamic> toJson() => _$SignInAnonymouslyResponseToJson(this);

  /// The JWT token for the user.
  final String? token;

  /// The refresh token for the user.
  final String? refreshToken;

  /// The error if the request failed.
  final SignInError? error;

  @override
  List<Object?> get props => [token, refreshToken];
}
