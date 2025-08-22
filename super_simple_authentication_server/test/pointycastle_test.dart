import 'dart:convert';
import 'dart:io';

import 'package:pointycastle/export.dart';
import 'package:test/test.dart';
import 'package:super_simple_authentication_server/src/util/rsa_key_manager.dart';

void main() {
  group('PointyCastle RSA Tests', () {
    test('should generate RSA key pair', () async {
      final privateKeyPem = await RsaKeyManager.generateKeyPair();
      
      expect(privateKeyPem, isNotEmpty);
      expect(privateKeyPem, contains('-----BEGIN PRIVATE KEY-----'));
      expect(privateKeyPem, contains('-----END PRIVATE KEY-----'));
    });

    test('should extract public key from private key', () async {
      final privateKeyPem = await RsaKeyManager.generateKeyPair();
      final publicKeyPem = await RsaKeyManager.extractPublicKey(privateKeyPem);
      
      expect(publicKeyPem, isNotEmpty);
      expect(publicKeyPem, contains('-----BEGIN PUBLIC KEY-----'));
      expect(publicKeyPem, contains('-----END PUBLIC KEY-----'));
    });

    test('should sign and verify data', () async {
      final privateKeyPem = await RsaKeyManager.generateKeyPair();
      final privateKey = RsaKeyManager._decodePrivateKeyPem(privateKeyPem);
      final publicKey = RSAPublicKey(privateKey.modulus!, privateKey.privateExponent!);
      
      final testData = utf8.encode('Hello, World!');
      
      // Sign the data
      final signature = RsaKeyManager.signRsaSha256(testData, privateKey);
      expect(signature, isNotEmpty);
      
      // Verify the signature
      final isValid = RsaKeyManager.verifyRsaSha256(testData, signature, publicKey);
      expect(isValid, isTrue);
    });

    test('should generate JWKS', () async {
      final privateKeyPem = await RsaKeyManager.generateKeyPair();
      final keyId = await RsaKeyManager.generateKeyId(privateKeyPem);
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

    test('should handle BigInt to bytes conversion correctly', () {
      final testValue = BigInt.parse('123456789');
      final bytes = RsaKeyManager._bigIntToBytes(testValue);
      
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(0));
      
      // Convert back to verify
      final hexString = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      final reconstructed = BigInt.parse(hexString, radix: 16);
      expect(reconstructed, equals(testValue));
    });
  });
}