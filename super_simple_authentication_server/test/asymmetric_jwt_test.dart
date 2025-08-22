import 'dart:convert';
import 'dart:io';

import 'package:pointycastle/export.dart';
import 'package:test/test.dart';
import 'package:super_simple_authentication_server/src/util/create_jwt_asymmetric.dart';
import 'package:super_simple_authentication_server/src/verify_jwt.dart';
import 'package:super_simple_authentication_server/src/util/rsa_key_manager.dart';

void main() {
  group('Asymmetric JWT Tests', () {
    late String privateKeyPem;
    late String publicKeyPem;
    late String keyId;

    setUpAll(() async {
      // Generate a test key pair
      privateKeyPem = await RsaKeyManager.generateKeyPair();
      publicKeyPem = await RsaKeyManager.extractPublicKey(privateKeyPem);
      keyId = await RsaKeyManager.generateKeyId(privateKeyPem);
    });

    test('should create and verify asymmetric JWT', () async {
      // Set environment variables for testing
      final originalPrivateKey = Platform.environment['JWT_PRIVATE_KEY'];
      final originalPublicKey = Platform.environment['JWT_PUBLIC_KEY'];
      
      Platform.environment['JWT_PRIVATE_KEY'] = privateKeyPem;
      Platform.environment['JWT_PUBLIC_KEY'] = publicKeyPem;

      try {
        // Create asymmetric JWT
        final token = await createJwtAsymmetric(
          subject: 'test-user',
          isNewUser: false,
          keyId: keyId,
          issuer: 'test-issuer',
          audience: 'test-audience',
        );

        // Verify the JWT
        final payload = await verifyJwt(token);

        expect(payload, isNotNull);
        expect(payload!['sub'], equals('test-user'));
        expect(payload['new'], equals(false));
        expect(payload['iss'], equals('test-issuer'));
        expect(payload['aud'], equals('test-audience'));
        expect(payload['kid'], isNull); // kid is in header, not payload

        // Verify the JWT header contains RS256 algorithm
        final parts = token.split('.');
        final header = json.decode(
          utf8.decode(base64Url.decode(parts[0])),
        ) as Map<String, dynamic>;

        expect(header['alg'], equals('RS256'));
        expect(header['typ'], equals('JWT'));
        expect(header['kid'], equals(keyId));
      } finally {
        // Restore original environment variables
        if (originalPrivateKey != null) {
          Platform.environment['JWT_PRIVATE_KEY'] = originalPrivateKey;
        } else {
          Platform.environment.remove('JWT_PRIVATE_KEY');
        }
        
        if (originalPublicKey != null) {
          Platform.environment['JWT_PUBLIC_KEY'] = originalPublicKey;
        } else {
          Platform.environment.remove('JWT_PUBLIC_KEY');
        }
      }
    });

    test('should reject JWT with invalid signature', () async {
      // Set environment variables for testing
      final originalPrivateKey = Platform.environment['JWT_PRIVATE_KEY'];
      final originalPublicKey = Platform.environment['JWT_PUBLIC_KEY'];
      
      Platform.environment['JWT_PRIVATE_KEY'] = privateKeyPem;
      Platform.environment['JWT_PUBLIC_KEY'] = publicKeyPem;

      try {
        // Create asymmetric JWT
        final token = await createJwtAsymmetric(
          subject: 'test-user',
          isNewUser: false,
          keyId: keyId,
        );

        // Tamper with the signature
        final parts = token.split('.');
        final tamperedSignature = base64Url.encode([1, 2, 3, 4, 5]);
        final tamperedToken = '${parts[0]}.${parts[1]}.$tamperedSignature';

        // Verify the tampered JWT should fail
        final payload = await verifyJwt(tamperedToken);
        expect(payload, isNull);
      } finally {
        // Restore original environment variables
        if (originalPrivateKey != null) {
          Platform.environment['JWT_PRIVATE_KEY'] = originalPrivateKey;
        } else {
          Platform.environment.remove('JWT_PRIVATE_KEY');
        }
        
        if (originalPublicKey != null) {
          Platform.environment['JWT_PUBLIC_KEY'] = originalPublicKey;
        } else {
          Platform.environment.remove('JWT_PUBLIC_KEY');
        }
      }
    });

    test('should generate valid JWKS', () async {
      final jwks = await RsaKeyManager.generateJwks(privateKeyPem, keyId: keyId);
      
      expect(jwks, contains('keys'));
      expect(jwks['keys'], isA<List>());
      expect(jwks['keys'].length, equals(1));
      
      final key = jwks['keys'][0] as Map<String, dynamic>;
      expect(key['kty'], equals('RSA'));
      expect(key['use'], equals('sig'));
      expect(key['alg'], equals('RS256'));
      expect(key['kid'], equals(keyId));
      expect(key, contains('n')); // modulus
      expect(key, contains('e')); // exponent
    });

    test('should handle missing environment variables gracefully', () async {
      // Clear environment variables
      final originalPrivateKey = Platform.environment['JWT_PRIVATE_KEY'];
      final originalPublicKey = Platform.environment['JWT_PUBLIC_KEY'];
      
      Platform.environment.remove('JWT_PRIVATE_KEY');
      Platform.environment.remove('JWT_PUBLIC_KEY');

      try {
        // Should throw when trying to create JWT without private key
        expect(
          () => createJwtAsymmetric(
            subject: 'test-user',
            isNewUser: false,
          ),
          throwsA(isA<Exception>()),
        );
      } finally {
        // Restore original environment variables
        if (originalPrivateKey != null) {
          Platform.environment['JWT_PRIVATE_KEY'] = originalPrivateKey;
        }
        
        if (originalPublicKey != null) {
          Platform.environment['JWT_PUBLIC_KEY'] = originalPublicKey;
        }
      }
    });
  });
}