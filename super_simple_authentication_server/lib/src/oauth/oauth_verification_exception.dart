/// {@template oauth_verification_error}
/// Enumeration of possible OAuth verification error types.
///
/// This provides structured error categorization to enable
/// appropriate error handling and user feedback.
/// {@endtemplate}
enum OAuthVerificationError {
  /// The JWT token format is invalid or malformed.
  invalidTokenFormat,

  /// The JWT signature verification failed.
  invalidSignature,

  /// The JWT token has expired.
  tokenExpired,

  /// The audience claim doesn't match the expected client ID.
  invalidAudience,

  /// The issuer claim doesn't match the expected provider.
  invalidIssuer,

  /// Required claims are missing from the token.
  missingRequiredClaims,

  /// The specified OAuth provider is not configured.
  providerNotConfigured,

  /// The JWKS endpoint is unavailable or returned an error.
  jwksUnavailable,

  /// A network error occurred during verification.
  networkError,

  /// An unknown or unexpected error occurred.
  unknownError,
}

/// {@template oauth_verification_exception}
/// Exception thrown during OAuth token verification failures.
///
/// This provides structured error information including the error type,
/// descriptive message, provider context, and additional details for
/// debugging and appropriate error handling.
/// {@endtemplate}
class OAuthVerificationException implements Exception {
  /// Creates an instance of [OAuthVerificationException].
  const OAuthVerificationException({
    required this.type,
    required this.message,
    this.providerId,
    this.details,
  });

  /// Creates an [OAuthVerificationException] for invalid token format.
  factory OAuthVerificationException.invalidTokenFormat({
    String? providerId,
    Map<String, dynamic>? details,
  }) {
    return OAuthVerificationException(
      type: OAuthVerificationError.invalidTokenFormat,
      message: 'The provided JWT token has an invalid format',
      providerId: providerId,
      details: details,
    );
  }

  /// Creates an [OAuthVerificationException] for invalid signature.
  factory OAuthVerificationException.invalidSignature({
    String? providerId,
    Map<String, dynamic>? details,
  }) {
    return OAuthVerificationException(
      type: OAuthVerificationError.invalidSignature,
      message: 'JWT signature verification failed',
      providerId: providerId,
      details: details,
    );
  }

  /// Creates an [OAuthVerificationException] for expired token.
  factory OAuthVerificationException.tokenExpired({
    String? providerId,
    DateTime? expiredAt,
    Map<String, dynamic>? details,
  }) {
    final message =
        expiredAt != null
            ? 'JWT token expired at $expiredAt'
            : 'JWT token has expired';
    return OAuthVerificationException(
      type: OAuthVerificationError.tokenExpired,
      message: message,
      providerId: providerId,
      details: details,
    );
  }

  /// Creates an [OAuthVerificationException] for invalid audience.
  factory OAuthVerificationException.invalidAudience({
    String? providerId,
    String? expectedAudience,
    String? actualAudience,
    Map<String, dynamic>? details,
  }) {
    final message =
        expectedAudience != null && actualAudience != null
            ? 'Invalid audience: expected $expectedAudience, '
                'got $actualAudience'
            : 'JWT audience claim does not match expected client ID';
    return OAuthVerificationException(
      type: OAuthVerificationError.invalidAudience,
      message: message,
      providerId: providerId,
      details: details,
    );
  }

  /// Creates an [OAuthVerificationException] for invalid issuer.
  factory OAuthVerificationException.invalidIssuer({
    String? providerId,
    String? expectedIssuer,
    String? actualIssuer,
    Map<String, dynamic>? details,
  }) {
    final message =
        expectedIssuer != null && actualIssuer != null
            ? 'Invalid issuer: expected $expectedIssuer, got $actualIssuer'
            : 'JWT issuer claim does not match expected provider';
    return OAuthVerificationException(
      type: OAuthVerificationError.invalidIssuer,
      message: message,
      providerId: providerId,
      details: details,
    );
  }

  /// Creates an [OAuthVerificationException] for missing required claims.
  factory OAuthVerificationException.missingRequiredClaims({
    String? providerId,
    List<String>? missingClaims,
    Map<String, dynamic>? details,
  }) {
    final message =
        missingClaims != null && missingClaims.isNotEmpty
            ? 'Missing required claims: ${missingClaims.join(', ')}'
            : 'Required claims are missing from the JWT token';
    return OAuthVerificationException(
      type: OAuthVerificationError.missingRequiredClaims,
      message: message,
      providerId: providerId,
      details: details,
    );
  }

  /// Creates an [OAuthVerificationException] for provider not configured.
  factory OAuthVerificationException.providerNotConfigured({
    String? providerId,
    Map<String, dynamic>? details,
  }) {
    final message =
        providerId != null
            ? 'OAuth provider "$providerId" is not configured'
            : 'The specified OAuth provider is not configured';
    return OAuthVerificationException(
      type: OAuthVerificationError.providerNotConfigured,
      message: message,
      providerId: providerId,
      details: details,
    );
  }

  /// Creates an [OAuthVerificationException] for JWKS unavailable.
  factory OAuthVerificationException.jwksUnavailable({
    String? providerId,
    String? jwksUri,
    Map<String, dynamic>? details,
  }) {
    final message =
        jwksUri != null
            ? 'JWKS endpoint unavailable: $jwksUri'
            : 'Unable to fetch provider public keys';
    return OAuthVerificationException(
      type: OAuthVerificationError.jwksUnavailable,
      message: message,
      providerId: providerId,
      details: details,
    );
  }

  /// Creates an [OAuthVerificationException] for network errors.
  factory OAuthVerificationException.networkError({
    String? providerId,
    String? originalError,
    Map<String, dynamic>? details,
  }) {
    final message =
        originalError != null
            ? 'Network error during verification: $originalError'
            : 'A network error occurred during token verification';
    return OAuthVerificationException(
      type: OAuthVerificationError.networkError,
      message: message,
      providerId: providerId,
      details: details,
    );
  }

  /// Creates an [OAuthVerificationException] for unknown errors.
  factory OAuthVerificationException.unknownError({
    String? providerId,
    String? originalError,
    Map<String, dynamic>? details,
  }) {
    final message =
        originalError != null
            ? 'Unknown error during verification: $originalError'
            : 'An unexpected error occurred during token verification';
    return OAuthVerificationException(
      type: OAuthVerificationError.unknownError,
      message: message,
      providerId: providerId,
      details: details,
    );
  }

  /// The specific type of verification error that occurred.
  final OAuthVerificationError type;

  /// A human-readable description of the error.
  final String message;

  /// The ID of the OAuth provider where the error occurred, if applicable.
  final String? providerId;

  /// Additional details about the error for debugging purposes.
  /// This may contain technical information that should not be
  /// exposed to end users.
  final Map<String, dynamic>? details;

  @override
  String toString() {
    final buffer = StringBuffer('OAuthVerificationException: $message');
    if (providerId != null) {
      buffer.write(' (Provider: $providerId)');
    }
    if (details != null && details!.isNotEmpty) {
      buffer.write(' Details: $details');
    }
    return buffer.toString();
  }
}
