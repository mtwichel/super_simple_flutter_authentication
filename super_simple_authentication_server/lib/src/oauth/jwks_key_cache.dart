import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:pointycastle/export.dart';

/// {@template jwks_key_cache}
/// A caching mechanism for OAuth provider public keys from JWKS endpoints.
///
/// This class fetches and caches JSON Web Key Sets (JWKS) from OAuth providers
/// to improve performance and reduce network requests. It supports both RSA
/// and ECDSA key formats and handles cache expiration automatically.
/// {@endtemplate}
class JwksKeyCache {
  /// Creates an instance of [JwksKeyCache].
  JwksKeyCache({
    http.Client? httpClient,
    Duration defaultCacheDuration = const Duration(hours: 1),
  }) : _httpClient = httpClient ?? http.Client(),
       _defaultCacheDuration = defaultCacheDuration;

  final http.Client _httpClient;
  final Duration _defaultCacheDuration;
  final Map<String, _CacheEntry> _cache = {};

  /// Fetches and caches JSON Web Keys from the specified JWKS URI.
  ///
  /// Returns a list of [JsonWebKey] objects parsed from the JWKS endpoint.
  /// Uses cached keys if they are still valid, otherwise fetches fresh keys.
  ///
  /// Throws [JwksException] if the keys cannot be fetched or parsed.
  Future<List<JsonWebKey>> getKeys(
    String jwksUri, {
    Duration? cacheDuration,
  }) async {
    final effectiveCacheDuration = cacheDuration ?? _defaultCacheDuration;
    final cacheEntry = _cache[jwksUri];

    // Return cached keys if they are still valid
    if (cacheEntry != null && !cacheEntry.isExpired) {
      return cacheEntry.keys;
    }

    try {
      // Fetch fresh keys from the JWKS endpoint
      final response = await _httpClient.get(Uri.parse(jwksUri));

      if (response.statusCode != 200) {
        // If we have cached keys and the request fails, return cached keys
        if (cacheEntry != null) {
          return cacheEntry.keys;
        }
        throw JwksException(
          'Failed to fetch JWKS: HTTP ${response.statusCode}',
          jwksUri: jwksUri,
        );
      }

      final jwksData = json.decode(response.body) as Map<String, dynamic>;
      final keys = _parseJwks(jwksData, jwksUri);

      // Cache the keys
      _cache[jwksUri] = _CacheEntry(
        keys: keys,
        expiresAt: DateTime.now().add(effectiveCacheDuration),
      );

      return keys;
    } catch (e) {
      // If we have cached keys and the request fails, return cached keys
      if (cacheEntry != null) {
        return cacheEntry.keys;
      }

      if (e is JwksException) {
        rethrow;
      }

      throw JwksException(
        'Failed to fetch or parse JWKS: $e',
        jwksUri: jwksUri,
      );
    }
  }

  /// Invalidates the cache for the specified JWKS URI.
  ///
  /// The next call to [getKeys] for this URI will fetch fresh keys.
  void invalidateCache(String jwksUri) {
    _cache.remove(jwksUri);
  }

  /// Clears all cached keys.
  void clearCache() {
    _cache.clear();
  }

  /// Disposes of the HTTP client and clears the cache.
  void dispose() {
    _httpClient.close();
    clearCache();
  }

  /// Parses a JWKS response into a list of [JsonWebKey] objects.
  List<JsonWebKey> _parseJwks(Map<String, dynamic> jwksData, String jwksUri) {
    final keys = jwksData['keys'] as List<dynamic>?;
    if (keys == null) {
      throw JwksException(
        'Invalid JWKS format: missing "keys" field',
        jwksUri: jwksUri,
      );
    }

    final parsedKeys = <JsonWebKey>[];
    for (final keyData in keys) {
      if (keyData is! Map<String, dynamic>) {
        continue; // Skip invalid key entries
      }

      try {
        final key = _parseJsonWebKey(keyData);
        if (key != null) {
          parsedKeys.add(key);
        }
      } catch (e) {
        // Log the error but continue parsing other keys
        // In a production environment, you might want to use a proper logger
        print('Warning: Failed to parse JWK: $e');
      }
    }

    if (parsedKeys.isEmpty) {
      throw JwksException('No valid keys found in JWKS', jwksUri: jwksUri);
    }

    return parsedKeys;
  }

  /// Parses a single JSON Web Key from the JWKS data.
  JsonWebKey? _parseJsonWebKey(Map<String, dynamic> keyData) {
    final kty = keyData['kty'] as String?;
    final kid = keyData['kid'] as String?;
    final use = keyData['use'] as String?;
    final alg = keyData['alg'] as String?;

    // Skip keys that are not for signature verification
    if (use != null && use != 'sig') {
      return null;
    }

    switch (kty) {
      case 'RSA':
        return _parseRsaKey(keyData, kid, alg);
      case 'EC':
        return _parseEcKey(keyData, kid, alg);
      default:
        return null; // Unsupported key type
    }
  }

  /// Parses an RSA key from JWK data.
  JsonWebKey? _parseRsaKey(
    Map<String, dynamic> keyData,
    String? kid,
    String? alg,
  ) {
    final n = keyData['n'] as String?;
    final e = keyData['e'] as String?;

    if (n == null || e == null) {
      return null;
    }

    try {
      final modulus = _base64UrlDecode(n);
      final exponent = _base64UrlDecode(e);

      final publicKey = RSAPublicKey(
        _bytesToBigInt(modulus),
        _bytesToBigInt(exponent),
      );

      return JsonWebKey(
        keyId: kid,
        algorithm: alg,
        keyType: 'RSA',
        publicKey: publicKey,
      );
    } catch (e) {
      return null;
    }
  }

  /// Parses an ECDSA key from JWK data.
  JsonWebKey? _parseEcKey(
    Map<String, dynamic> keyData,
    String? kid,
    String? alg,
  ) {
    final crv = keyData['crv'] as String?;
    final x = keyData['x'] as String?;
    final y = keyData['y'] as String?;

    if (crv == null || x == null || y == null) {
      return null;
    }

    try {
      final xBytes = _base64UrlDecode(x);
      final yBytes = _base64UrlDecode(y);

      // Determine the curve based on the crv parameter
      ECDomainParameters? curve;
      switch (crv) {
        case 'P-256':
          curve = ECCurve_secp256r1();
          break;
        case 'P-384':
          curve = ECCurve_secp384r1();
          break;
        case 'P-521':
          curve = ECCurve_secp521r1();
          break;
        default:
          return null; // Unsupported curve
      }

      final point = curve.curve.createPoint(
        _bytesToBigInt(xBytes),
        _bytesToBigInt(yBytes),
      );

      final publicKey = ECPublicKey(point, curve);

      return JsonWebKey(
        keyId: kid,
        algorithm: alg,
        keyType: 'EC',
        publicKey: publicKey,
      );
    } catch (e) {
      return null;
    }
  }

  /// Decodes a base64url-encoded string to bytes.
  Uint8List _base64UrlDecode(String input) {
    // Add padding if necessary
    var padded = input;
    switch (padded.length % 4) {
      case 2:
        padded += '==';
        break;
      case 3:
        padded += '=';
        break;
    }

    // Replace URL-safe characters
    padded = padded.replaceAll('-', '+').replaceAll('_', '/');

    return base64.decode(padded);
  }

  /// Converts bytes to a BigInt.
  BigInt _bytesToBigInt(Uint8List bytes) {
    var result = BigInt.zero;
    for (var i = 0; i < bytes.length; i++) {
      result = (result << 8) + BigInt.from(bytes[i]);
    }
    return result;
  }
}

/// {@template json_web_key}
/// Represents a JSON Web Key with its cryptographic public key.
/// {@endtemplate}
@immutable
class JsonWebKey {
  /// Creates an instance of [JsonWebKey].
  const JsonWebKey({
    required this.keyId,
    required this.algorithm,
    required this.keyType,
    required this.publicKey,
  });

  /// The key ID (kid) parameter.
  final String? keyId;

  /// The algorithm (alg) parameter.
  final String? algorithm;

  /// The key type (kty) parameter.
  final String keyType;

  /// The actual cryptographic public key.
  final PublicKey publicKey;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is JsonWebKey &&
        other.keyId == keyId &&
        other.algorithm == algorithm &&
        other.keyType == keyType &&
        other.publicKey == publicKey;
  }

  @override
  int get hashCode {
    return Object.hash(keyId, algorithm, keyType, publicKey);
  }

  @override
  String toString() {
    return 'JsonWebKey('
        'keyId: $keyId, '
        'algorithm: $algorithm, '
        'keyType: $keyType, '
        'publicKey: ${publicKey.runtimeType}'
        ')';
  }
}

/// {@template jwks_exception}
/// Exception thrown when JWKS operations fail.
/// {@endtemplate}
class JwksException implements Exception {
  /// Creates an instance of [JwksException].
  const JwksException(this.message, {this.jwksUri});

  /// The error message.
  final String message;

  /// The JWKS URI that caused the error, if applicable.
  final String? jwksUri;

  @override
  String toString() {
    if (jwksUri != null) {
      return 'JwksException: $message (URI: $jwksUri)';
    }
    return 'JwksException: $message';
  }
}

/// Internal cache entry for storing keys with expiration.
class _CacheEntry {
  _CacheEntry({required this.keys, required this.expiresAt});

  final List<JsonWebKey> keys;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
