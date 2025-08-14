import 'package:meta/meta.dart';

/// {@template oauth_user_info}
/// Standardized user information extracted from OAuth tokens.
///
/// This class provides a consistent structure for user data regardless
/// of the OAuth provider, containing standard OpenID Connect claims
/// and allowing for provider-specific additional claims.
/// {@endtemplate}
@immutable
class OAuthUserInfo {
  /// Creates an instance of [OAuthUserInfo].
  const OAuthUserInfo({
    required this.sub,
    this.email,
    this.emailVerified,
    this.name,
    this.picture,
    this.additionalClaims = const {},
  });

  /// The unique identifier for the user (subject claim).
  /// This is required and should be present in all OAuth tokens.
  final String sub;

  /// The user's email address, if available.
  final String? email;

  /// Whether the user's email address has been verified by the provider.
  final bool? emailVerified;

  /// The user's full name, if available.
  final String? name;

  /// URL to the user's profile picture, if available.
  final String? picture;

  /// Additional claims from the OAuth token that are not part of
  /// the standard set. This allows access to provider-specific
  /// user information.
  final Map<String, dynamic> additionalClaims;

  /// Creates a copy of this [OAuthUserInfo] with the given fields replaced.
  OAuthUserInfo copyWith({
    String? sub,
    String? email,
    bool? emailVerified,
    String? name,
    String? picture,
    Map<String, dynamic>? additionalClaims,
  }) {
    return OAuthUserInfo(
      sub: sub ?? this.sub,
      email: email ?? this.email,
      emailVerified: emailVerified ?? this.emailVerified,
      name: name ?? this.name,
      picture: picture ?? this.picture,
      additionalClaims: additionalClaims ?? this.additionalClaims,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OAuthUserInfo &&
        other.sub == sub &&
        other.email == email &&
        other.emailVerified == emailVerified &&
        other.name == name &&
        other.picture == picture &&
        _mapEquals(other.additionalClaims, additionalClaims);
  }

  @override
  int get hashCode {
    return Object.hash(
      sub,
      email,
      emailVerified,
      name,
      picture,
      additionalClaims,
    );
  }

  @override
  String toString() {
    return 'OAuthUserInfo('
        'sub: $sub, '
        'email: $email, '
        'emailVerified: $emailVerified, '
        'name: $name, '
        'picture: $picture, '
        'additionalClaims: $additionalClaims'
        ')';
  }

  /// Helper method to compare maps for equality.
  bool _mapEquals(Map<String, dynamic> map1, Map<String, dynamic> map2) {
    if (map1.length != map2.length) return false;
    for (final key in map1.keys) {
      if (!map2.containsKey(key) || map1[key] != map2[key]) {
        return false;
      }
    }
    return true;
  }
}
