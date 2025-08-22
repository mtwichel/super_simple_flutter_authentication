import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';

/// Manages RSA key pairs for JWT asymmetric signing.
/// This class handles key generation, storage, and public key export.
class RsaKeyManager {
  static const int _defaultKeySize = 2048;
  
  /// Generates a new RSA key pair and returns the PEM-formatted private key.
  /// The public key can be extracted using [extractPublicKey].
  static Future<String> generateKeyPair({int keySize = _defaultKeySize}) async {
    final rsaSigner = RsaSsaPkcs1v15.sha256();
    final keyPair = await rsaSigner.newKeyPair(keySize: keySize);
    
    // Export private key as PEM
    final privateKeyPem = await rsaSigner.exportPrivateKey(keyPair);
    return privateKeyPem;
  }

  /// Extracts the public key from a PEM-formatted private key.
  /// Returns the public key in PEM format.
  static Future<String> extractPublicKey(String privateKeyPem) async {
    final rsaSigner = RsaSsaPkcs1v15.sha256();
    final privateKey = await rsaSigner.importPrivateKey(pem: privateKeyPem);
    final publicKey = await rsaSigner.exportPublicKey(privateKey);
    return publicKey;
  }

  /// Extracts the public key from a PEM-formatted private key and returns it
  /// in JWK (JSON Web Key) format for use in JWKS endpoints.
  static Future<Map<String, dynamic>> extractPublicKeyJwk(
    String privateKeyPem, {
    String? keyId,
    String? use = 'sig',
    String? alg = 'RS256',
  }) async {
    final rsaSigner = RsaSsaPkcs1v15.sha256();
    final privateKey = await rsaSigner.importPrivateKey(pem: privateKeyPem);
    final publicKey = await rsaSigner.exportPublicKey(privateKey);
    
    // Parse the PEM to extract modulus and exponent
    final pemLines = publicKey.split('\n');
    final base64Key = pemLines
        .where((line) => !line.startsWith('-----'))
        .join('');
    
    final keyBytes = base64.decode(base64Key);
    
    // Extract modulus and exponent from DER-encoded public key
    // This is a simplified approach - in production you might want to use a proper ASN.1 parser
    final modulusStart = keyBytes.indexOf(0x02) + 2; // Skip to modulus
    final modulusLength = keyBytes[modulusStart - 1];
    final modulus = keyBytes.sublist(modulusStart, modulusStart + modulusLength);
    
    final exponentStart = modulusStart + modulusLength + 2;
    final exponentLength = keyBytes[exponentStart - 1];
    final exponent = keyBytes.sublist(exponentStart, exponentStart + exponentLength);
    
    return {
      'kty': 'RSA',
      'use': use,
      'alg': alg,
      if (keyId != null) 'kid': keyId,
      'n': base64Url.encode(modulus).replaceAll('=', ''),
      'e': base64Url.encode(exponent).replaceAll('=', ''),
    };
  }

  /// Generates a JWKS (JSON Web Key Set) from a private key.
  /// This is the format used by Firebase and other OAuth providers.
  static Future<Map<String, dynamic>> generateJwks(
    String privateKeyPem, {
    String? keyId,
  }) async {
    final jwk = await extractPublicKeyJwk(privateKeyPem, keyId: keyId);
    
    return {
      'keys': [jwk],
    };
  }

  /// Loads a private key from environment variables or file.
  /// Returns the PEM-formatted private key.
  static String loadPrivateKey() {
    final privateKeyPem = Platform.environment['JWT_PRIVATE_KEY'] ?? 
        Platform.environment['JWT_RSA_PRIVATE_KEY'];
    
    if (privateKeyPem == null) {
      throw Exception('JWT_PRIVATE_KEY or JWT_RSA_PRIVATE_KEY environment variable is required');
    }
    
    return privateKeyPem;
  }

  /// Generates a key ID based on the public key fingerprint.
  /// This is useful for key rotation scenarios.
  static Future<String> generateKeyId(String privateKeyPem) async {
    final publicKey = await extractPublicKey(privateKeyPem);
    final publicKeyBytes = utf8.encode(publicKey);
    
    // Simple hash-based key ID - in production you might want to use SHA-256
    final hash = publicKeyBytes.fold<int>(0, (hash, byte) => hash + byte);
    return hash.toRadixString(16).padLeft(8, '0');
  }
}