import 'package:meta/meta.dart';

/// {@template oauth_provider_config}
/// Configuration class that holds provider-specific OAuth settings.
///
/// This class stores all necessary configuration for an OAuth provider,
/// including issuer information, client credentials, JWKS endpoints,
/// and validation parameters. It supports both manual configuration
/// and auto-discovery via OpenID Connect.
/// {@endtemplate}
@immutable
class OAuthProviderConfig {
  /// Creates an instance of [OAuthProviderConfig].
  const OAuthProviderConfig({
    required this.id,
    required this.issuer,
    required this.clientId,
    this.jwksUri,
    this.keysCacheDuration = const Duration(hours: 1),
    this.requiredClaims = const [],
    this.claimMappings = const {},
    this.autoDiscovery = false,
  });

  /// Unique identifier for this OAuth provider configuration.
  /// Used to distinguish between multiple providers.
  final String id;

  /// The issuer URL for the OAuth provider.
  /// This should match the 'iss' claim in JWT tokens from this provider.
  final String issuer;

  /// The client ID for this application with the OAuth provider.
  /// This should match the 'aud' claim in JWT tokens.
  final String clientId;

  /// The JWKS (JSON Web Key Set) endpoint URL for fetching public keys.
  /// If null and autoDiscovery is true, will be discovered automatically.
  final String? jwksUri;

  /// How long to cache the provider's public keys before refreshing.
  /// Defaults to 1 hour to balance performance and security.
  final Duration keysCacheDuration;

  /// List of claims that must be present in tokens from this provider.
  /// Verification will fail if any of these claims are missing.
  final List<String> requiredClaims;

  /// Mapping of standard claim names to provider-specific claim names.
  /// Used when a provider uses non-standard claim names.
  /// Example: {'email': 'user_email', 'name': 'full_name'}
  final Map<String, String> claimMappings;

  /// Whether to use OpenID Connect auto-discovery to find endpoints.
  /// When true, will attempt to discover JWKS URI from the well-known endpoint.
  final bool autoDiscovery;

  /// Gets the well-known OpenID Connect configuration URL for this provider.
  String get wellKnownConfigUrl {
    final uri = Uri.parse(issuer);
    return '${uri.scheme}://${uri.host}${uri.path}'
        '/.well-known/openid_configuration';
  }

  /// Creates a copy of this [OAuthProviderConfig] with the given fields
  /// replaced.
  OAuthProviderConfig copyWith({
    String? id,
    String? issuer,
    String? clientId,
    String? jwksUri,
    Duration? keysCacheDuration,
    List<String>? requiredClaims,
    Map<String, String>? claimMappings,
    bool? autoDiscovery,
  }) {
    return OAuthProviderConfig(
      id: id ?? this.id,
      issuer: issuer ?? this.issuer,
      clientId: clientId ?? this.clientId,
      jwksUri: jwksUri ?? this.jwksUri,
      keysCacheDuration: keysCacheDuration ?? this.keysCacheDuration,
      requiredClaims: requiredClaims ?? this.requiredClaims,
      claimMappings: claimMappings ?? this.claimMappings,
      autoDiscovery: autoDiscovery ?? this.autoDiscovery,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OAuthProviderConfig &&
        other.id == id &&
        other.issuer == issuer &&
        other.clientId == clientId &&
        other.jwksUri == jwksUri &&
        other.keysCacheDuration == keysCacheDuration &&
        _listEquals(other.requiredClaims, requiredClaims) &&
        _mapEquals(other.claimMappings, claimMappings) &&
        other.autoDiscovery == autoDiscovery;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      issuer,
      clientId,
      jwksUri,
      keysCacheDuration,
      requiredClaims,
      claimMappings,
      autoDiscovery,
    );
  }

  @override
  String toString() {
    return 'OAuthProviderConfig('
        'id: $id, '
        'issuer: $issuer, '
        'clientId: $clientId, '
        'jwksUri: $jwksUri, '
        'keysCacheDuration: $keysCacheDuration, '
        'requiredClaims: $requiredClaims, '
        'claimMappings: $claimMappings, '
        'autoDiscovery: $autoDiscovery'
        ')';
  }

  /// Helper method to compare lists for equality.
  bool _listEquals(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    for (var i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  /// Helper method to compare maps for equality.
  bool _mapEquals(Map<String, String> map1, Map<String, String> map2) {
    if (map1.length != map2.length) return false;
    for (final key in map1.keys) {
      if (!map2.containsKey(key) || map1[key] != map2[key]) {
        return false;
      }
    }
    return true;
  }
}
