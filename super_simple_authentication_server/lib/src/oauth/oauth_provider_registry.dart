import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import 'package:super_simple_authentication_server/src/oauth/oauth_provider_config.dart';

/// {@template oauth_provider_registry}
/// Registry for managing multiple OAuth provider configurations.
///
/// This class provides functionality to register, lookup, and manage
/// OAuth provider configurations. It supports loading configurations
/// from environment variables, JSON files with environment variable
/// substitution, and OpenID Connect auto-discovery.
/// {@endtemplate}
class OAuthProviderRegistry {
  /// Creates an instance of [OAuthProviderRegistry].
  OAuthProviderRegistry({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;
  final Map<String, OAuthProviderConfig> _providers = {};

  /// Registers a new OAuth provider configuration.
  ///
  /// If a provider with the same [config.id] already exists,
  /// it will be replaced with the new configuration.
  void registerProvider(OAuthProviderConfig config) {
    _providers[config.id] = config;
  }

  /// Gets the configuration for a specific OAuth provider.
  ///
  /// Returns null if no provider with the given [providerId] is registered.
  OAuthProviderConfig? getProvider(String providerId) {
    return _providers[providerId];
  }

  /// Gets a list of all registered provider IDs.
  List<String> getRegisteredProviders() {
    return _providers.keys.toList();
  }

  /// Loads OAuth provider configurations from environment variables.
  ///
  /// This method looks for environment variables following these patterns:
  /// - OAUTH_{PROVIDER}_CLIENT_ID
  /// - OAUTH_{PROVIDER}_ISSUER
  /// - OAUTH_{PROVIDER}_JWKS_URI (optional)
  /// - OAUTH_{PROVIDER}_AUTO_DISCOVERY (optional, defaults to false)
  ///
  /// For backward compatibility, it also supports:
  /// - GOOGLE_CLIENT_ID -> google provider
  /// - APPLE_BUNDLE_ID -> apple provider
  Future<void> loadFromEnvironment() async {
    final env = Platform.environment;

    // Load Google configuration (backward compatibility)
    final googleClientId =
        env['GOOGLE_CLIENT_ID'] ?? env['OAUTH_GOOGLE_CLIENT_ID'];
    if (googleClientId != null) {
      final googleConfig = OAuthProviderConfig(
        id: 'google',
        issuer: env['OAUTH_GOOGLE_ISSUER'] ?? 'https://accounts.google.com',
        clientId: googleClientId,
        jwksUri:
            env['OAUTH_GOOGLE_JWKS_URI'] ??
            'https://www.googleapis.com/oauth2/v3/certs',
        keysCacheDuration:
            _parseDuration(env['OAUTH_GOOGLE_CACHE_DURATION']) ??
            const Duration(hours: 1),
        autoDiscovery: _parseBool(env['OAUTH_GOOGLE_AUTO_DISCOVERY']) ?? false,
      );
      registerProvider(googleConfig);
    }

    // Load Apple configuration (backward compatibility)
    final appleClientId =
        env['APPLE_BUNDLE_ID'] ?? env['OAUTH_APPLE_CLIENT_ID'];
    if (appleClientId != null) {
      final appleConfig = OAuthProviderConfig(
        id: 'apple',
        issuer: env['OAUTH_APPLE_ISSUER'] ?? 'https://appleid.apple.com',
        clientId: appleClientId,
        jwksUri:
            env['OAUTH_APPLE_JWKS_URI'] ??
            'https://appleid.apple.com/auth/keys',
        keysCacheDuration:
            _parseDuration(env['OAUTH_APPLE_CACHE_DURATION']) ??
            const Duration(hours: 24),
        autoDiscovery: _parseBool(env['OAUTH_APPLE_AUTO_DISCOVERY']) ?? false,
      );
      registerProvider(appleConfig);
    }

    // Load generic OAuth providers
    final providerIds = <String>{};
    for (final key in env.keys) {
      if (key.startsWith('OAUTH_') && key.endsWith('_CLIENT_ID')) {
        final providerId =
            key
                .substring(
                  6,
                  key.length - 10,
                ) // Remove 'OAUTH_' and '_CLIENT_ID'
                .toLowerCase();
        if (providerId != 'google' && providerId != 'apple') {
          providerIds.add(providerId);
        }
      }
    }

    for (final providerId in providerIds) {
      final prefix = 'OAUTH_${providerId.toUpperCase()}';
      final clientId = env['${prefix}_CLIENT_ID'];
      final issuer = env['${prefix}_ISSUER'];

      if (clientId != null && issuer != null) {
        var config = OAuthProviderConfig(
          id: providerId,
          issuer: issuer,
          clientId: clientId,
          jwksUri: env['${prefix}_JWKS_URI'],
          keysCacheDuration:
              _parseDuration(env['${prefix}_CACHE_DURATION']) ??
              const Duration(hours: 1),
          autoDiscovery: _parseBool(env['${prefix}_AUTO_DISCOVERY']) ?? false,
        );

        // Perform auto-discovery if enabled and JWKS URI is not provided
        if (config.autoDiscovery && config.jwksUri == null) {
          config = await _performAutoDiscovery(config);
        }

        registerProvider(config);
      }
    }
  }

  /// Loads OAuth provider configurations from a JSON file.
  ///
  /// The JSON file should have the following structure:
  /// ```json
  /// {
  ///   "providers": {
  ///     "google": {
  ///       "issuer": "https://accounts.google.com",
  ///       "clientId": "${GOOGLE_CLIENT_ID}",
  ///       "jwksUri": "https://www.googleapis.com/oauth2/v3/certs",
  ///       "keysCacheDuration": "1h",
  ///       "requiredClaims": ["email", "email_verified"]
  ///     }
  ///   }
  /// }
  /// ```
  ///
  /// Environment variable substitution is supported using ${VAR_NAME} syntax.
  Future<void> loadFromJson(String configPath) async {
    final file = File(configPath);
    if (!await file.exists()) {
      throw ArgumentError('Configuration file not found: $configPath');
    }

    final content = await file.readAsString();
    final substitutedContent = _substituteEnvironmentVariables(content);

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(substitutedContent) as Map<String, dynamic>;
    } catch (e) {
      throw FormatException('Invalid JSON in configuration file: $e');
    }

    final providersJson = json['providers'] as Map<String, dynamic>?;
    if (providersJson == null) {
      throw const FormatException(
        'Configuration file must contain a "providers" object',
      );
    }

    for (final entry in providersJson.entries) {
      final providerId = entry.key;
      final providerJson = entry.value as Map<String, dynamic>;

      final issuer = providerJson['issuer'] as String?;
      final clientId = providerJson['clientId'] as String?;

      if (issuer == null || clientId == null) {
        throw FormatException(
          'Provider "$providerId" must have both "issuer" and "clientId" fields',
        );
      }

      var config = OAuthProviderConfig(
        id: providerId,
        issuer: issuer,
        clientId: clientId,
        jwksUri: providerJson['jwksUri'] as String?,
        keysCacheDuration:
            _parseDuration(providerJson['keysCacheDuration'] as String?) ??
            const Duration(hours: 1),
        requiredClaims: _parseStringList(providerJson['requiredClaims']),
        claimMappings: _parseStringMap(providerJson['claimMappings']),
        autoDiscovery: providerJson['autoDiscovery'] as bool? ?? false,
      );

      // Perform auto-discovery if enabled and JWKS URI is not provided
      if (config.autoDiscovery && config.jwksUri == null) {
        config = await _performAutoDiscovery(config);
      }

      registerProvider(config);
    }
  }

  /// Performs OpenID Connect auto-discovery for a provider configuration.
  ///
  /// This method fetches the well-known OpenID Connect configuration
  /// from the provider's issuer URL and extracts the JWKS URI.
  @visibleForTesting
  Future<OAuthProviderConfig> performAutoDiscovery(
    OAuthProviderConfig config,
  ) async {
    return _performAutoDiscovery(config);
  }

  Future<OAuthProviderConfig> _performAutoDiscovery(
    OAuthProviderConfig config,
  ) async {
    try {
      final response = await _httpClient.get(
        Uri.parse(config.wellKnownConfigUrl),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch OpenID Connect configuration: ${response.statusCode}',
        );
      }

      final Map<String, dynamic> wellKnownConfig;
      try {
        wellKnownConfig = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        throw FormatException(
          'Invalid JSON in OpenID Connect configuration: $e',
        );
      }

      final jwksUri = wellKnownConfig['jwks_uri'] as String?;
      if (jwksUri == null) {
        throw const FormatException(
          'OpenID Connect configuration missing jwks_uri',
        );
      }

      return config.copyWith(jwksUri: jwksUri);
    } catch (e) {
      throw Exception('Auto-discovery failed for provider ${config.id}: $e');
    }
  }

  /// Clears all registered providers.
  void clear() {
    _providers.clear();
  }

  /// Substitutes environment variables in the given content.
  ///
  /// Supports ${VAR_NAME} syntax for environment variable substitution.
  String _substituteEnvironmentVariables(String content) {
    final env = Platform.environment;
    return content.replaceAllMapped(RegExp(r'\$\{([^}]+)\}'), (match) {
      final varName = match.group(1)!;
      return env[varName] ?? match.group(0)!;
    });
  }

  /// Parses a duration string (e.g., "1h", "30m", "45s").
  Duration? _parseDuration(String? durationStr) {
    if (durationStr == null) return null;

    final match = RegExp(
      r'^(\d+)([hms])$',
    ).firstMatch(durationStr.toLowerCase());
    if (match == null) return null;

    final value = int.tryParse(match.group(1)!);
    if (value == null) return null;

    final unit = match.group(2)!;
    switch (unit) {
      case 'h':
        return Duration(hours: value);
      case 'm':
        return Duration(minutes: value);
      case 's':
        return Duration(seconds: value);
      default:
        return null;
    }
  }

  /// Parses a boolean string.
  bool? _parseBool(String? boolStr) {
    if (boolStr == null) return null;
    final lower = boolStr.toLowerCase();
    if (lower == 'true' || lower == '1') return true;
    if (lower == 'false' || lower == '0') return false;
    return null;
  }

  /// Parses a list of strings from JSON.
  List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.cast<String>();
    }
    return [];
  }

  /// Parses a map of strings from JSON.
  Map<String, String> _parseStringMap(dynamic value) {
    if (value == null) return {};
    if (value is Map) {
      return value.cast<String, String>();
    }
    return {};
  }
}
