import 'package:super_simple_authentication_server/src/oauth/oauth.dart';
import 'package:test/test.dart';

void main() {
  group('OAuthProviderConfig', () {
    test('creates instance with required fields', () {
      const config = OAuthProviderConfig(
        id: 'google',
        issuer: 'https://accounts.google.com',
        clientId: 'client123',
      );

      expect(config.id, equals('google'));
      expect(config.issuer, equals('https://accounts.google.com'));
      expect(config.clientId, equals('client123'));
      expect(config.jwksUri, isNull);
      expect(config.keysCacheDuration, equals(const Duration(hours: 1)));
      expect(config.requiredClaims, isEmpty);
      expect(config.claimMappings, isEmpty);
      expect(config.autoDiscovery, isFalse);
    });

    test('creates instance with all fields populated', () {
      const config = OAuthProviderConfig(
        id: 'custom',
        issuer: 'https://auth.example.com',
        clientId: 'client456',
        jwksUri: 'https://auth.example.com/jwks',
        keysCacheDuration: Duration(hours: 2),
        requiredClaims: ['email', 'email_verified'],
        claimMappings: {'email': 'user_email', 'name': 'full_name'},
        autoDiscovery: true,
      );

      expect(config.id, equals('custom'));
      expect(config.issuer, equals('https://auth.example.com'));
      expect(config.clientId, equals('client456'));
      expect(config.jwksUri, equals('https://auth.example.com/jwks'));
      expect(config.keysCacheDuration, equals(const Duration(hours: 2)));
      expect(config.requiredClaims, equals(['email', 'email_verified']));
      expect(
        config.claimMappings,
        equals({'email': 'user_email', 'name': 'full_name'}),
      );
      expect(config.autoDiscovery, isTrue);
    });

    test('wellKnownConfigUrl generates correct URL', () {
      const config = OAuthProviderConfig(
        id: 'test',
        issuer: 'https://auth.example.com',
        clientId: 'client123',
      );

      expect(
        config.wellKnownConfigUrl,
        equals('https://auth.example.com/.well-known/openid_configuration'),
      );
    });

    test('wellKnownConfigUrl handles issuer with path', () {
      const config = OAuthProviderConfig(
        id: 'test',
        issuer: 'https://auth.example.com/oauth',
        clientId: 'client123',
      );

      expect(
        config.wellKnownConfigUrl,
        equals(
          'https://auth.example.com/oauth/.well-known/openid_configuration',
        ),
      );
    });

    test('wellKnownConfigUrl handles issuer with trailing slash', () {
      const config = OAuthProviderConfig(
        id: 'test',
        issuer: 'https://auth.example.com/',
        clientId: 'client123',
      );

      expect(
        config.wellKnownConfigUrl,
        equals('https://auth.example.com//.well-known/openid_configuration'),
      );
    });

    test('copyWith creates new instance with updated fields', () {
      const original = OAuthProviderConfig(
        id: 'google',
        issuer: 'https://accounts.google.com',
        clientId: 'client123',
      );

      final updated = original.copyWith(
        clientId: 'newclient456',
        jwksUri: 'https://www.googleapis.com/oauth2/v3/certs',
        keysCacheDuration: const Duration(hours: 2),
        autoDiscovery: true,
      );

      expect(updated.id, equals('google')); // unchanged
      expect(
        updated.issuer,
        equals('https://accounts.google.com'),
      ); // unchanged
      expect(updated.clientId, equals('newclient456')); // changed
      expect(
        updated.jwksUri,
        equals('https://www.googleapis.com/oauth2/v3/certs'),
      ); // added
      expect(
        updated.keysCacheDuration,
        equals(const Duration(hours: 2)),
      ); // changed
      expect(updated.autoDiscovery, isTrue); // changed
    });

    test('copyWith with null values keeps original values', () {
      const original = OAuthProviderConfig(
        id: 'google',
        issuer: 'https://accounts.google.com',
        clientId: 'client123',
        jwksUri: 'https://www.googleapis.com/oauth2/v3/certs',
        requiredClaims: ['email'],
        claimMappings: {'email': 'user_email'},
        autoDiscovery: true,
      );

      final updated = original.copyWith();

      expect(updated.id, equals(original.id));
      expect(updated.issuer, equals(original.issuer));
      expect(updated.clientId, equals(original.clientId));
      expect(updated.jwksUri, equals(original.jwksUri));
      expect(updated.keysCacheDuration, equals(original.keysCacheDuration));
      expect(updated.requiredClaims, equals(original.requiredClaims));
      expect(updated.claimMappings, equals(original.claimMappings));
      expect(updated.autoDiscovery, equals(original.autoDiscovery));
    });

    test('equality works correctly', () {
      const config1 = OAuthProviderConfig(
        id: 'google',
        issuer: 'https://accounts.google.com',
        clientId: 'client123',
        jwksUri: 'https://www.googleapis.com/oauth2/v3/certs',
        requiredClaims: ['email', 'email_verified'],
        claimMappings: {'email': 'user_email'},
        autoDiscovery: true,
      );

      const config2 = OAuthProviderConfig(
        id: 'google',
        issuer: 'https://accounts.google.com',
        clientId: 'client123',
        jwksUri: 'https://www.googleapis.com/oauth2/v3/certs',
        requiredClaims: ['email', 'email_verified'],
        claimMappings: {'email': 'user_email'},
        autoDiscovery: true,
      );

      const config3 = OAuthProviderConfig(
        id: 'apple',
        issuer: 'https://accounts.google.com',
        clientId: 'client123',
        jwksUri: 'https://www.googleapis.com/oauth2/v3/certs',
        requiredClaims: ['email', 'email_verified'],
        claimMappings: {'email': 'user_email'},
        autoDiscovery: true,
      );

      expect(config1, equals(config2));
      expect(config1, isNot(equals(config3)));
      expect(config1.hashCode, equals(config2.hashCode));
    });

    test('equality handles different required claims order', () {
      const config1 = OAuthProviderConfig(
        id: 'test',
        issuer: 'https://auth.example.com',
        clientId: 'client123',
        requiredClaims: ['email', 'name'],
      );

      const config2 = OAuthProviderConfig(
        id: 'test',
        issuer: 'https://auth.example.com',
        clientId: 'client123',
        requiredClaims: ['name', 'email'],
      );

      // Order matters for list equality
      expect(config1, isNot(equals(config2)));
    });

    test('equality handles different claim mappings', () {
      const config1 = OAuthProviderConfig(
        id: 'test',
        issuer: 'https://auth.example.com',
        clientId: 'client123',
        claimMappings: {'email': 'user_email', 'name': 'full_name'},
      );

      const config2 = OAuthProviderConfig(
        id: 'test',
        issuer: 'https://auth.example.com',
        clientId: 'client123',
        claimMappings: {'email': 'user_email', 'name': 'full_name'},
      );

      const config3 = OAuthProviderConfig(
        id: 'test',
        issuer: 'https://auth.example.com',
        clientId: 'client123',
        claimMappings: {'email': 'user_email', 'name': 'display_name'},
      );

      expect(config1, equals(config2));
      expect(config1, isNot(equals(config3)));
    });

    test('toString provides readable representation', () {
      const config = OAuthProviderConfig(
        id: 'google',
        issuer: 'https://accounts.google.com',
        clientId: 'client123',
        jwksUri: 'https://www.googleapis.com/oauth2/v3/certs',
        keysCacheDuration: Duration(hours: 2),
        requiredClaims: ['email'],
        claimMappings: {'email': 'user_email'},
        autoDiscovery: true,
      );

      final string = config.toString();

      expect(string, contains('OAuthProviderConfig('));
      expect(string, contains('id: google'));
      expect(string, contains('issuer: https://accounts.google.com'));
      expect(string, contains('clientId: client123'));
      expect(
        string,
        contains('jwksUri: https://www.googleapis.com/oauth2/v3/certs'),
      );
      expect(string, contains('keysCacheDuration: 2:00:00.000000'));
      expect(string, contains('requiredClaims: [email]'));
      expect(string, contains('claimMappings: {email: user_email}'));
      expect(string, contains('autoDiscovery: true'));
    });

    test('toString handles null and empty values', () {
      const config = OAuthProviderConfig(
        id: 'test',
        issuer: 'https://auth.example.com',
        clientId: 'client123',
      );

      final string = config.toString();

      expect(string, contains('jwksUri: null'));
      expect(string, contains('requiredClaims: []'));
      expect(string, contains('claimMappings: {}'));
      expect(string, contains('autoDiscovery: false'));
    });
  });
}
