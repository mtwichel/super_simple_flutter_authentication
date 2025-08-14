import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:pointycastle/export.dart';
import 'package:super_simple_authentication_server/src/oauth/oauth.dart';
import 'package:test/test.dart';

class MockHttpClient extends Mock implements http.Client {}

class MockPublicKey extends Mock implements PublicKey {}

void main() {
  group('JwksKeyCache', () {
    late MockHttpClient mockHttpClient;
    late JwksKeyCache jwksKeyCache;
    const testJwksUri = 'https://example.com/.well-known/jwks.json';

    setUp(() {
      mockHttpClient = MockHttpClient();
      jwksKeyCache = JwksKeyCache(
        httpClient: mockHttpClient,
        defaultCacheDuration: const Duration(minutes: 5),
      );
    });

    tearDown(() {
      jwksKeyCache.dispose();
    });

    group('getKeys', () {
      test('fetches and parses RSA keys successfully', () async {
        // Arrange
        const rsaJwks = {
          'keys': [
            {
              'kty': 'RSA',
              'kid': 'test-key-1',
              'use': 'sig',
              'alg': 'RS256',
              'n': 'sRJjz2msHH_4e-8KTvWhW8_hXjzlrZ8VrKKVmH8nq7LKP1_2Qw',
              'e': 'AQAB',
            },
          ],
        };

        when(() => mockHttpClient.get(Uri.parse(testJwksUri))).thenAnswer(
          (_) async => http.Response(
            json.encode(rsaJwks),
            200,
            headers: {'content-type': 'application/json'},
          ),
        );

        // Act
        final keys = await jwksKeyCache.getKeys(testJwksUri);

        // Assert
        expect(keys, hasLength(1));
        expect(keys.first.keyId, equals('test-key-1'));
        expect(keys.first.keyType, equals('RSA'));
        expect(keys.first.algorithm, equals('RS256'));
        verify(() => mockHttpClient.get(Uri.parse(testJwksUri))).called(1);
      });
      test('parses both ECDSA and RSA keys successfully', () async {
        // Arrange - Mix of ECDSA and RSA keys
        const mixedJwks = {
          'keys': [
            {
              'kty': 'EC',
              'kid': 'test-ec-key',
              'use': 'sig',
              'alg': 'ES256',
              'crv': 'P-256',
              'x': 'f83OJ3D2xF1Bg8vub9tLe1gHMzV76e8Tus9uPHvRVEU',
              'y': 'x_FEzRu9m36HLN_tue659LNpXW6pCyStikYjKIWI5a0',
            },
            {
              'kty': 'RSA',
              'kid': 'test-rsa-key',
              'use': 'sig',
              'alg': 'RS256',
              'n': 'sRJjz2msHH_4e-8KTvWhW8_hXjzlrZ8VrKKVmH8nq7LKP1_2Qw',
              'e': 'AQAB',
            },
          ],
        };

        when(() => mockHttpClient.get(Uri.parse(testJwksUri))).thenAnswer(
          (_) async => http.Response(
            json.encode(mixedJwks),
            200,
            headers: {'content-type': 'application/json'},
          ),
        );

        // Act
        final keys = await jwksKeyCache.getKeys(testJwksUri);

        // Assert - Should return both keys
        expect(keys, hasLength(2));

        final ecKey = keys.firstWhere((k) => k.keyType == 'EC');
        final rsaKey = keys.firstWhere((k) => k.keyType == 'RSA');

        expect(ecKey.keyId, equals('test-ec-key'));
        expect(ecKey.algorithm, equals('ES256'));

        expect(rsaKey.keyId, equals('test-rsa-key'));
        expect(rsaKey.algorithm, equals('RS256'));

        verify(() => mockHttpClient.get(Uri.parse(testJwksUri))).called(1);
      });

      test('caches keys and reuses them within cache duration', () async {
        // Arrange
        const jwks = {
          'keys': [
            {
              'kty': 'RSA',
              'kid': 'cached-key',
              'use': 'sig',
              'alg': 'RS256',
              'n': 'sRJjz2msHH_4e-8KTvWhW8_hXjzlrZ8VrKKVmH8nq7LKP1_2Qw',
              'e': 'AQAB',
            },
          ],
        };

        when(() => mockHttpClient.get(Uri.parse(testJwksUri))).thenAnswer(
          (_) async => http.Response(
            json.encode(jwks),
            200,
            headers: {'content-type': 'application/json'},
          ),
        );

        // Act - First call
        final keys1 = await jwksKeyCache.getKeys(testJwksUri);

        // Act - Second call (should use cache)
        final keys2 = await jwksKeyCache.getKeys(testJwksUri);

        // Assert
        expect(keys1, hasLength(1));
        expect(keys2, hasLength(1));
        expect(keys1.first.keyId, equals(keys2.first.keyId));

        // HTTP client should only be called once due to caching
        verify(() => mockHttpClient.get(Uri.parse(testJwksUri))).called(1);
      });

      test('refreshes expired cache', () async {
        // Arrange
        const jwks = {
          'keys': [
            {
              'kty': 'RSA',
              'kid': 'expired-key',
              'use': 'sig',
              'alg': 'RS256',
              'n': 'sRJjz2msHH_4e-8KTvWhW8_hXjzlrZ8VrKKVmH8nq7LKP1_2Qw',
              'e': 'AQAB',
            },
          ],
        };

        when(() => mockHttpClient.get(Uri.parse(testJwksUri))).thenAnswer(
          (_) async => http.Response(
            json.encode(jwks),
            200,
            headers: {'content-type': 'application/json'},
          ),
        );

        // Create cache with very short duration
        final shortCacheJwks = JwksKeyCache(
          httpClient: mockHttpClient,
          defaultCacheDuration: const Duration(milliseconds: 10),
        );

        // Act - First call
        await shortCacheJwks.getKeys(testJwksUri);

        // Wait for cache to expire
        await Future.delayed(const Duration(milliseconds: 20));

        // Act - Second call (should fetch fresh keys)
        await shortCacheJwks.getKeys(testJwksUri);

        // Assert - HTTP client should be called twice
        verify(() => mockHttpClient.get(Uri.parse(testJwksUri))).called(2);

        shortCacheJwks.dispose();
      });

      test('uses cached keys when available within cache duration', () async {
        // Arrange
        const jwks = {
          'keys': [
            {
              'kty': 'RSA',
              'kid': 'cached-fallback-key',
              'use': 'sig',
              'alg': 'RS256',
              'n': 'sRJjz2msHH_4e-8KTvWhW8_hXjzlrZ8VrKKVmH8nq7LKP1_2Qw',
              'e': 'AQAB',
            },
          ],
        };

        when(() => mockHttpClient.get(Uri.parse(testJwksUri))).thenAnswer(
          (_) async => http.Response(
            json.encode(jwks),
            200,
            headers: {'content-type': 'application/json'},
          ),
        );

        // Act - First call (populate cache)
        final keys1 = await jwksKeyCache.getKeys(testJwksUri);

        // Act - Second call within cache duration (should use cache)
        final keys2 = await jwksKeyCache.getKeys(testJwksUri);

        // Assert
        expect(keys1, hasLength(1));
        expect(keys2, hasLength(1));
        expect(keys1.first.keyId, equals(keys2.first.keyId));

        // Should only call HTTP client once due to caching
        verify(() => mockHttpClient.get(Uri.parse(testJwksUri))).called(1);
      });

      test(
        'throws JwksException when no cached keys and network fails',
        () async {
          // Arrange
          when(
            () => mockHttpClient.get(Uri.parse(testJwksUri)),
          ).thenAnswer((_) async => http.Response('Server Error', 500));

          // Act & Assert
          expect(
            () => jwksKeyCache.getKeys(testJwksUri),
            throwsA(
              isA<JwksException>()
                  .having((e) => e.message, 'message', contains('HTTP 500'))
                  .having((e) => e.jwksUri, 'jwksUri', equals(testJwksUri)),
            ),
          );
        },
      );

      test('throws JwksException when JWKS format is invalid', () async {
        // Arrange
        const invalidJwks = {'invalid': 'format'};

        when(() => mockHttpClient.get(Uri.parse(testJwksUri))).thenAnswer(
          (_) async => http.Response(
            json.encode(invalidJwks),
            200,
            headers: {'content-type': 'application/json'},
          ),
        );

        // Act & Assert
        expect(
          () => jwksKeyCache.getKeys(testJwksUri),
          throwsA(
            isA<JwksException>()
                .having(
                  (e) => e.message,
                  'message',
                  contains('missing "keys" field'),
                )
                .having((e) => e.jwksUri, 'jwksUri', equals(testJwksUri)),
          ),
        );
      });

      test('throws JwksException when no valid keys found', () async {
        // Arrange
        const emptyJwks = {'keys': []};

        when(() => mockHttpClient.get(Uri.parse(testJwksUri))).thenAnswer(
          (_) async => http.Response(
            json.encode(emptyJwks),
            200,
            headers: {'content-type': 'application/json'},
          ),
        );

        // Act & Assert
        expect(
          () => jwksKeyCache.getKeys(testJwksUri),
          throwsA(
            isA<JwksException>()
                .having(
                  (e) => e.message,
                  'message',
                  contains('No valid keys found'),
                )
                .having((e) => e.jwksUri, 'jwksUri', equals(testJwksUri)),
          ),
        );
      });

      test('skips keys with non-signature use', () async {
        // Arrange
        const jwks = {
          'keys': [
            {
              'kty': 'RSA',
              'kid': 'encryption-key',
              'use': 'enc', // Not for signatures
              'alg': 'RS256',
              'n': 'sRJjz2msHH_4e-8KTvWhW8_hXjzlrZ8VrKKVmH8nq7LKP1_2Qw',
              'e': 'AQAB',
            },
            {
              'kty': 'RSA',
              'kid': 'signature-key',
              'use': 'sig', // For signatures
              'alg': 'RS256',
              'n': 'sRJjz2msHH_4e-8KTvWhW8_hXjzlrZ8VrKKVmH8nq7LKP1_2Qw',
              'e': 'AQAB',
            },
          ],
        };

        when(() => mockHttpClient.get(Uri.parse(testJwksUri))).thenAnswer(
          (_) async => http.Response(
            json.encode(jwks),
            200,
            headers: {'content-type': 'application/json'},
          ),
        );

        // Act
        final keys = await jwksKeyCache.getKeys(testJwksUri);

        // Assert - Only the signature key should be included
        expect(keys, hasLength(1));
        expect(keys.first.keyId, equals('signature-key'));
      });

      test('handles network timeout gracefully', () async {
        // Arrange
        when(
          () => mockHttpClient.get(Uri.parse(testJwksUri)),
        ).thenThrow(const SocketException('Connection timeout'));

        // Act & Assert
        expect(
          () => jwksKeyCache.getKeys(testJwksUri),
          throwsA(
            isA<JwksException>()
                .having(
                  (e) => e.message,
                  'message',
                  contains('Failed to fetch or parse JWKS'),
                )
                .having((e) => e.jwksUri, 'jwksUri', equals(testJwksUri)),
          ),
        );
      });

      test('uses custom cache duration when provided', () async {
        // Arrange
        const jwks = {
          'keys': [
            {
              'kty': 'RSA',
              'kid': 'custom-duration-key',
              'use': 'sig',
              'alg': 'RS256',
              'n': 'sRJjz2msHH_4e-8KTvWhW8_hXjzlrZ8VrKKVmH8nq7LKP1_2Qw',
              'e': 'AQAB',
            },
          ],
        };

        when(() => mockHttpClient.get(Uri.parse(testJwksUri))).thenAnswer(
          (_) async => http.Response(
            json.encode(jwks),
            200,
            headers: {'content-type': 'application/json'},
          ),
        );

        // Act - Use custom cache duration
        await jwksKeyCache.getKeys(
          testJwksUri,
          cacheDuration: const Duration(seconds: 1),
        );

        // Wait for custom cache to expire (but not default cache)
        await Future.delayed(const Duration(milliseconds: 1100));

        // Act - Second call should fetch fresh keys
        await jwksKeyCache.getKeys(testJwksUri);

        // Assert - Should be called twice due to custom short cache duration
        verify(() => mockHttpClient.get(Uri.parse(testJwksUri))).called(2);
      });
    });

    group('invalidateCache', () {
      test('forces fresh fetch on next getKeys call', () async {
        // Arrange
        const jwks = {
          'keys': [
            {
              'kty': 'RSA',
              'kid': 'invalidate-test-key',
              'use': 'sig',
              'alg': 'RS256',
              'n': 'sRJjz2msHH_4e-8KTvWhW8_hXjzlrZ8VrKKVmH8nq7LKP1_2Qw',
              'e': 'AQAB',
            },
          ],
        };

        when(() => mockHttpClient.get(Uri.parse(testJwksUri))).thenAnswer(
          (_) async => http.Response(
            json.encode(jwks),
            200,
            headers: {'content-type': 'application/json'},
          ),
        );

        // Act - First call
        await jwksKeyCache.getKeys(testJwksUri);

        // Invalidate cache
        jwksKeyCache.invalidateCache(testJwksUri);

        // Act - Second call (should fetch fresh keys)
        await jwksKeyCache.getKeys(testJwksUri);

        // Assert - Should be called twice due to cache invalidation
        verify(() => mockHttpClient.get(Uri.parse(testJwksUri))).called(2);
      });
    });

    group('clearCache', () {
      test('clears all cached keys', () async {
        // Arrange
        const jwks = {
          'keys': [
            {
              'kty': 'RSA',
              'kid': 'clear-test-key',
              'use': 'sig',
              'alg': 'RS256',
              'n': 'sRJjz2msHH_4e-8KTvWhW8_hXjzlrZ8VrKKVmH8nq7LKP1_2Qw',
              'e': 'AQAB',
            },
          ],
        };

        const testJwksUri2 = 'https://example2.com/.well-known/jwks.json';

        when(() => mockHttpClient.get(Uri.parse(testJwksUri))).thenAnswer(
          (_) async => http.Response(
            json.encode(jwks),
            200,
            headers: {'content-type': 'application/json'},
          ),
        );

        when(() => mockHttpClient.get(Uri.parse(testJwksUri2))).thenAnswer(
          (_) async => http.Response(
            json.encode(jwks),
            200,
            headers: {'content-type': 'application/json'},
          ),
        );

        // Act - Cache keys from two different URIs
        await jwksKeyCache.getKeys(testJwksUri);
        await jwksKeyCache.getKeys(testJwksUri2);

        // Clear all cache
        jwksKeyCache.clearCache();

        // Act - Fetch keys again (should make fresh requests)
        await jwksKeyCache.getKeys(testJwksUri);
        await jwksKeyCache.getKeys(testJwksUri2);

        // Assert - Each URI should be called twice (once before clear, once after)
        verify(() => mockHttpClient.get(Uri.parse(testJwksUri))).called(2);
        verify(() => mockHttpClient.get(Uri.parse(testJwksUri2))).called(2);
      });
    });

    group('JsonWebKey', () {
      test('equality works correctly', () {
        // Arrange
        final mockKey1 = MockPublicKey();
        final mockKey2 = MockPublicKey();

        final key1 = JsonWebKey(
          keyId: 'test-key',
          algorithm: 'RS256',
          keyType: 'RSA',
          publicKey: mockKey1,
        );

        final key2 = JsonWebKey(
          keyId: 'test-key',
          algorithm: 'RS256',
          keyType: 'RSA',
          publicKey: mockKey1, // Same instance
        );

        final key3 = JsonWebKey(
          keyId: 'different-key',
          algorithm: 'RS256',
          keyType: 'RSA',
          publicKey: mockKey2,
        );

        // Assert
        expect(key1, equals(key2));
        expect(key1, isNot(equals(key3)));
        expect(key1.hashCode, equals(key2.hashCode));
      });

      test('toString works correctly', () {
        // Arrange
        final mockKey = MockPublicKey();
        final key = JsonWebKey(
          keyId: 'test-key',
          algorithm: 'RS256',
          keyType: 'RSA',
          publicKey: mockKey,
        );

        // Act
        final result = key.toString();

        // Assert
        expect(result, contains('JsonWebKey'));
        expect(result, contains('keyId: test-key'));
        expect(result, contains('algorithm: RS256'));
        expect(result, contains('keyType: RSA'));
      });
    });

    group('JwksException', () {
      test('toString works correctly without URI', () {
        // Arrange
        const exception = JwksException('Test error message');

        // Act
        final result = exception.toString();

        // Assert
        expect(result, equals('JwksException: Test error message'));
      });

      test('toString works correctly with URI', () {
        // Arrange
        const exception = JwksException(
          'Test error message',
          jwksUri: 'https://example.com/jwks',
        );

        // Act
        final result = exception.toString();

        // Assert
        expect(
          result,
          equals(
            'JwksException: Test error message (URI: https://example.com/jwks)',
          ),
        );
      });
    });
  });
}
