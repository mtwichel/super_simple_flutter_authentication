/// {@template sign_in_response}
/// A response for signing in.
/// {@endtemplate}
class SignInResponse {
  /// {@macro sign_in_response}
  SignInResponse({
    this.token,
    this.refreshToken,
    this.error,
  });

  /// The access token.
  final String? token;

  /// The refresh token.
  final String? refreshToken;

  /// The error.
  final String? error;

  /// Converts the response to a JSON map.
  Map<String, dynamic> toJson() => {
    'token': token,
    'refreshToken': refreshToken,
    'error': error,
  };
}
