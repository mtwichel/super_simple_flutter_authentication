import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:super_simple_authentication_server/src/oauth/oauth.dart';
import 'package:test/test.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  group('OAuthProviderRegistry', () {
    late OAuthProviderRegistry registry;
    late MockHttpClient mockHttpClient;

    setUp(() {
      mockHttpClient = MockHttpClient();
      registry = OAuthProviderRegistry(httpClient: mockHttpClient);
    });

    tearDown(() {
      reset(mockHttpClient);
    });

    group('registerProvider', () {
      test('should register a new provider', () {
        const config = OAuthProviderConfig(
          id: 'test-provider',
          issuer: 'https://test.com',
          clientId: 'test-client-id',
        );

        registry.registerProvider(config);

        expect(registry.getProvider('test-provider'), equals(config));
        expect(registry.getRegisteredProviders(), contains('test-provider'));
      });

      test('should replace existing provider with same id', () {
        const config1 = OAuthProviderConfig(
          id: 'test-provider',
          issuer: 'https://test1.com',
          clientId: 'client-1',
        );
        const config2 = OAuthProviderConfig(
          id: 'test-provider',
          issuer: 'https://test2.com',
          clientId: 'client-2',
        );

        registry.registerProvider(config1);
        registry.registerProvider(config2);

        expect(registry.getProvider('test-provider'), equals(config2));
        expect(registry.getRegisteredProviders(), hasLength(1));
      });
    });

    group('getProvider', () {
      test('should return null for non-existent provider', () {
        expect(registry.getProvider('non-existent'), isNull);
      });

      test('should return correct provider configuration', () {
        const config = OAuthProviderConfig(
          id: 'test-provider',
          issuer: 'https://test.com',
          clientId: 'test-client-id',
        );

        registry.registerProvider(config);

        expect(registry.getProvider('test-provider'), equals(config));
      });
    });

    group('getRegisteredProviders', () {
      test('should return empty list when no providers registered', () {
        expect(registry.getRegisteredProviders(), isEmpty);
      });

      test('should return list of all registered provider ids', () {
        const config1 = OAuthProviderConfig(
          id: 'provider-1',
          issuer: 'https://test1.com',
          clientId: 'client-1',
        );
        const config2 = OAuthProviderConfig(
          id: 'provider-2',
          issuer: 'https://test2.com',
          clientId: 'client-2',
        );

        registry.registerProvider(config1);
        registry.registerProvider(config2);

        final providers = registry.getRegisteredProviders();
        expect(providers, hasLength(2));
        expect(providers, containsAll(['provider-1', 'provider-2']));
      });
    });

    group('clear', () {
      test('should remove all registered providers', () {
        const config1 = OAuthProviderConfig(
          id: 'provider-1',
          issuer: 'https://test1.com',
          clientId: 'client-1',
        );
        const config2 = OAuthProviderConfig(
          id: 'provider-2',
          issuer: 'https://test2.com',
          clientId: 'client-2',
        );

        registry.registerProvider(config1);
        registry.registerProvider(config2);
        expect(registry.getRegisteredProviders(), hasLength(2));

        registry.clear();

        expect(registry.getRegisteredProviders(), isEmpty);
        expect(registry.getProvider('provider-1'), isNull);
        expect(registry.getProvider('provider-2'), isNull);
      });
    });

    group('performAutoDiscovery', () {
      test('should discover JWKS URI from well-known endpoint', () async {
        const wellKnownResponse = {
          'issuer': 'https://test.com',
          'jwks_uri': 'https://test.com/jwks',
          'authorization_endpoint': 'https://test.com/auth',
        };

        when(
          () => mockHttpClient.get(
            Uri.parse('https://test.com/.well-known/openid_configuration'),
          ),
        ).thenAnswer(
          (_) async => http.Response(jsonEncode(wellKnownResponse), 200),
        );

        const originalConfig = OAuthProviderConfig(
          id: 'test',
          issuer: 'https://test.com',
          clientId: 'test-client-id',
          autoDiscovery: true,
        );

        final discoveredConfig = await registry.performAutoDiscovery(
          originalConfig,
        );

        expect(discoveredConfig.jwksUri, equals('https://test.com/jwks'));
        expect(discoveredConfig.id, equals(originalConfig.id));
        expect(discoveredConfig.issuer, equals(originalConfig.issuer));
        expect(discoveredConfig.clientId, equals(originalConfig.clientId));

        verify(
          () => mockHttpClient.get(
            Uri.parse('https://test.com/.well-known/openid_configuration'),
          ),
        ).called(1);
      });

      test('should throw exception for HTTP error response', () async {
        when(
          () => mockHttpClient.get(
            Uri.parse('https://test.com/.well-known/openid_configuration'),
          ),
        ).thenAnswer((_) async => http.Response('Not Found', 404));

        const config = OAuthProviderConfig(
          id: 'test',
          issuer: 'https://test.com',
          clientId: 'test-client-id',
          autoDiscovery: true,
        );

        await expectLater(
          registry.performAutoDiscovery(config),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception for invalid JSON response', () async {
        when(
          () => mockHttpClient.get(
            Uri.parse('https://test.com/.well-known/openid_configuration'),
          ),
        ).thenAnswer((_) async => http.Response('invalid json', 200));

        const config = OAuthProviderConfig(
          id: 'test',
          issuer: 'https://test.com',
          clientId: 'test-client-id',
          autoDiscovery: true,
        );

        await expectLater(
          registry.performAutoDiscovery(config),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception for missing jwks_uri in response', () async {
        const wellKnownResponse = {
          'issuer': 'https://test.com',
          'authorization_endpoint': 'https://test.com/auth',
          // Missing jwks_uri
        };

        when(
          () => mockHttpClient.get(
            Uri.parse('https://test.com/.well-known/openid_configuration'),
          ),
        ).thenAnswer(
          (_) async => http.Response(jsonEncode(wellKnownResponse), 200),
        );

        const config = OAuthProviderConfig(
          id: 'test',
          issuer: 'https://test.com',
          clientId: 'test-client-id',
          autoDiscovery: true,
        );

        await expectLater(
          registry.performAutoDiscovery(config),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
