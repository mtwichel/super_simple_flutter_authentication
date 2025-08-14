import 'package:super_simple_authentication_server/src/oauth/oauth.dart';
import 'package:test/test.dart';

void main() {
  group('OAuthVerificationError', () {
    test('has all expected error types', () {
      const expectedTypes = [
        OAuthVerificationError.invalidTokenFormat,
        OAuthVerificationError.invalidSignature,
        OAuthVerificationError.tokenExpired,
        OAuthVerificationError.invalidAudience,
        OAuthVerificationError.invalidIssuer,
        OAuthVerificationError.missingRequiredClaims,
        OAuthVerificationError.providerNotConfigured,
        OAuthVerificationError.jwksUnavailable,
        OAuthVerificationError.networkError,
        OAuthVerificationError.unknownError,
      ];

      expect(OAuthVerificationError.values, equals(expectedTypes));
    });
  });

  group('OAuthVerificationException', () {
    test('creates instance with required fields', () {
      const exception = OAuthVerificationException(
        type: OAuthVerificationError.invalidTokenFormat,
        message: 'Test message',
      );

      expect(exception.type, equals(OAuthVerificationError.invalidTokenFormat));
      expect(exception.message, equals('Test message'));
      expect(exception.providerId, isNull);
      expect(exception.details, isNull);
    });

    test('creates instance with all fields', () {
      const exception = OAuthVerificationException(
        type: OAuthVerificationError.invalidSignature,
        message: 'Signature verification failed',
        providerId: 'google',
        details: {'key_id': 'abc123', 'algorithm': 'RS256'},
      );

      expect(exception.type, equals(OAuthVerificationError.invalidSignature));
      expect(exception.message, equals('Signature verification failed'));
      expect(exception.providerId, equals('google'));
      expect(
        exception.details,
        equals({'key_id': 'abc123', 'algorithm': 'RS256'}),
      );
    });

    group('factory constructors', () {
      test('invalidTokenFormat creates correct exception', () {
        final exception = OAuthVerificationException.invalidTokenFormat(
          providerId: 'google',
          details: {'token_parts': 2},
        );

        expect(
          exception.type,
          equals(OAuthVerificationError.invalidTokenFormat),
        );
        expect(
          exception.message,
          equals('The provided JWT token has an invalid format'),
        );
        expect(exception.providerId, equals('google'));
        expect(exception.details, equals({'token_parts': 2}));
      });

      test('invalidSignature creates correct exception', () {
        final exception = OAuthVerificationException.invalidSignature(
          providerId: 'apple',
          details: {'key_id': 'xyz789'},
        );

        expect(exception.type, equals(OAuthVerificationError.invalidSignature));
        expect(exception.message, equals('JWT signature verification failed'));
        expect(exception.providerId, equals('apple'));
        expect(exception.details, equals({'key_id': 'xyz789'}));
      });

      test(
        'tokenExpired creates correct exception without expiration time',
        () {
          final exception = OAuthVerificationException.tokenExpired(
            providerId: 'google',
          );

          expect(exception.type, equals(OAuthVerificationError.tokenExpired));
          expect(exception.message, equals('JWT token has expired'));
          expect(exception.providerId, equals('google'));
        },
      );

      test('tokenExpired creates correct exception with expiration time', () {
        final expiredAt = DateTime(2023, 1, 1, 12);
        final exception = OAuthVerificationException.tokenExpired(
          providerId: 'google',
          expiredAt: expiredAt,
        );

        expect(exception.type, equals(OAuthVerificationError.tokenExpired));
        expect(exception.message, equals('JWT token expired at $expiredAt'));
        expect(exception.providerId, equals('google'));
      });

      test(
        'invalidAudience creates correct exception without audience details',
        () {
          final exception = OAuthVerificationException.invalidAudience(
            providerId: 'google',
          );

          expect(
            exception.type,
            equals(OAuthVerificationError.invalidAudience),
          );
          expect(
            exception.message,
            equals('JWT audience claim does not match expected client ID'),
          );
          expect(exception.providerId, equals('google'));
        },
      );

      test(
        'invalidAudience creates correct exception with audience details',
        () {
          final exception = OAuthVerificationException.invalidAudience(
            providerId: 'google',
            expectedAudience: 'client123',
            actualAudience: 'client456',
          );

          expect(
            exception.type,
            equals(OAuthVerificationError.invalidAudience),
          );
          expect(
            exception.message,
            equals('Invalid audience: expected client123, got client456'),
          );
          expect(exception.providerId, equals('google'));
        },
      );

      test(
        'invalidIssuer creates correct exception without issuer details',
        () {
          final exception = OAuthVerificationException.invalidIssuer(
            providerId: 'apple',
          );

          expect(exception.type, equals(OAuthVerificationError.invalidIssuer));
          expect(
            exception.message,
            equals('JWT issuer claim does not match expected provider'),
          );
          expect(exception.providerId, equals('apple'));
        },
      );

      test('invalidIssuer creates correct exception with issuer details', () {
        final exception = OAuthVerificationException.invalidIssuer(
          providerId: 'apple',
          expectedIssuer: 'https://appleid.apple.com',
          actualIssuer: 'https://accounts.google.com',
        );

        expect(exception.type, equals(OAuthVerificationError.invalidIssuer));
        expect(
          exception.message,
          equals(
            'Invalid issuer: expected https://appleid.apple.com, got https://accounts.google.com',
          ),
        );
        expect(exception.providerId, equals('apple'));
      });

      test(
        'missingRequiredClaims creates correct exception without claim details',
        () {
          final exception = OAuthVerificationException.missingRequiredClaims(
            providerId: 'custom',
          );

          expect(
            exception.type,
            equals(OAuthVerificationError.missingRequiredClaims),
          );
          expect(
            exception.message,
            equals('Required claims are missing from the JWT token'),
          );
          expect(exception.providerId, equals('custom'));
        },
      );

      test(
        'missingRequiredClaims creates correct exception with claim details',
        () {
          final exception = OAuthVerificationException.missingRequiredClaims(
            providerId: 'custom',
            missingClaims: ['email', 'email_verified'],
          );

          expect(
            exception.type,
            equals(OAuthVerificationError.missingRequiredClaims),
          );
          expect(
            exception.message,
            equals('Missing required claims: email, email_verified'),
          );
          expect(exception.providerId, equals('custom'));
        },
      );

      test('missingRequiredClaims handles empty claims list', () {
        final exception = OAuthVerificationException.missingRequiredClaims(
          providerId: 'custom',
        );

        expect(
          exception.type,
          equals(OAuthVerificationError.missingRequiredClaims),
        );
        expect(
          exception.message,
          equals('Required claims are missing from the JWT token'),
        );
        expect(exception.providerId, equals('custom'));
      });

      test(
        'providerNotConfigured creates correct exception without provider ID',
        () {
          final exception = OAuthVerificationException.providerNotConfigured();

          expect(
            exception.type,
            equals(OAuthVerificationError.providerNotConfigured),
          );
          expect(
            exception.message,
            equals('The specified OAuth provider is not configured'),
          );
          expect(exception.providerId, isNull);
        },
      );

      test(
        'providerNotConfigured creates correct exception with provider ID',
        () {
          final exception = OAuthVerificationException.providerNotConfigured(
            providerId: 'custom-provider',
          );

          expect(
            exception.type,
            equals(OAuthVerificationError.providerNotConfigured),
          );
          expect(
            exception.message,
            equals('OAuth provider "custom-provider" is not configured'),
          );
          expect(exception.providerId, equals('custom-provider'));
        },
      );

      test('jwksUnavailable creates correct exception without JWKS URI', () {
        final exception = OAuthVerificationException.jwksUnavailable(
          providerId: 'google',
        );

        expect(exception.type, equals(OAuthVerificationError.jwksUnavailable));
        expect(
          exception.message,
          equals('Unable to fetch provider public keys'),
        );
        expect(exception.providerId, equals('google'));
      });

      test('jwksUnavailable creates correct exception with JWKS URI', () {
        final exception = OAuthVerificationException.jwksUnavailable(
          providerId: 'google',
          jwksUri: 'https://www.googleapis.com/oauth2/v3/certs',
        );

        expect(exception.type, equals(OAuthVerificationError.jwksUnavailable));
        expect(
          exception.message,
          equals(
            'JWKS endpoint unavailable: https://www.googleapis.com/oauth2/v3/certs',
          ),
        );
        expect(exception.providerId, equals('google'));
      });

      test('networkError creates correct exception without original error', () {
        final exception = OAuthVerificationException.networkError(
          providerId: 'apple',
        );

        expect(exception.type, equals(OAuthVerificationError.networkError));
        expect(
          exception.message,
          equals('A network error occurred during token verification'),
        );
        expect(exception.providerId, equals('apple'));
      });

      test('networkError creates correct exception with original error', () {
        final exception = OAuthVerificationException.networkError(
          providerId: 'apple',
          originalError: 'Connection timeout',
        );

        expect(exception.type, equals(OAuthVerificationError.networkError));
        expect(
          exception.message,
          equals('Network error during verification: Connection timeout'),
        );
        expect(exception.providerId, equals('apple'));
      });

      test('unknownError creates correct exception without original error', () {
        final exception = OAuthVerificationException.unknownError(
          providerId: 'custom',
        );

        expect(exception.type, equals(OAuthVerificationError.unknownError));
        expect(
          exception.message,
          equals('An unexpected error occurred during token verification'),
        );
        expect(exception.providerId, equals('custom'));
      });

      test('unknownError creates correct exception with original error', () {
        final exception = OAuthVerificationException.unknownError(
          providerId: 'custom',
          originalError: 'Unexpected null value',
        );

        expect(exception.type, equals(OAuthVerificationError.unknownError));
        expect(
          exception.message,
          equals('Unknown error during verification: Unexpected null value'),
        );
        expect(exception.providerId, equals('custom'));
      });
    });

    group('toString', () {
      test('includes basic message', () {
        const exception = OAuthVerificationException(
          type: OAuthVerificationError.invalidTokenFormat,
          message: 'Test message',
        );

        final string = exception.toString();

        expect(string, equals('OAuthVerificationException: Test message'));
      });

      test('includes provider ID when present', () {
        const exception = OAuthVerificationException(
          type: OAuthVerificationError.invalidSignature,
          message: 'Signature failed',
          providerId: 'google',
        );

        final string = exception.toString();

        expect(
          string,
          equals(
            'OAuthVerificationException: Signature failed (Provider: google)',
          ),
        );
      });

      test('includes details when present', () {
        const exception = OAuthVerificationException(
          type: OAuthVerificationError.networkError,
          message: 'Network failed',
          providerId: 'apple',
          details: {'status_code': 500, 'retry_count': 3},
        );

        final string = exception.toString();

        expect(
          string,
          equals(
            'OAuthVerificationException: Network failed (Provider: apple) '
            'Details: {status_code: 500, retry_count: 3}',
          ),
        );
      });

      test('handles empty details map', () {
        const exception = OAuthVerificationException(
          type: OAuthVerificationError.unknownError,
          message: 'Unknown error',
          details: {},
        );

        final string = exception.toString();

        expect(string, equals('OAuthVerificationException: Unknown error'));
      });

      test('handles null provider ID and details', () {
        const exception = OAuthVerificationException(
          type: OAuthVerificationError.tokenExpired,
          message: 'Token expired',
        );

        final string = exception.toString();

        expect(string, equals('OAuthVerificationException: Token expired'));
      });
    });
  });
}
