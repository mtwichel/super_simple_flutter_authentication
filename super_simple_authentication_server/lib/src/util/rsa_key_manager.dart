import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:pointycastle/export.dart';

/// Manages RSA key pairs for JWT asymmetric signing.
/// This class handles key generation, storage, and public key export using PointyCastle.
class RsaKeyManager {
  static const int _defaultKeySize = 2048;
  
  /// Generates a new RSA key pair and returns the PEM-formatted private key.
  /// The public key can be extracted using [extractPublicKey].
  static Future<String> generateKeyPair({int keySize = _defaultKeySize}) async {
    final secureRandom = SecureRandom('Fortuna');
    final random = Random.secure();
    final seed = List<int>.generate(32, (i) => random.nextInt(256));
    secureRandom.seed(KeyParameter(Uint8List.fromList(seed)));

    final keyGen = RSAKeyGenerator()
      ..init(ParametersWithRandom(
        RSAKeyGeneratorParameters(BigInt.from(65537), keySize, 64),
        secureRandom,
      ));

    final keyPair = keyGen.generateKeyPair();
    final privateKey = keyPair.privateKey as RSAPrivateKey;
    final publicKey = keyPair.publicKey as RSAPublicKey;

    // Convert to PEM format
    final privateKeyPem = _encodePrivateKeyPem(privateKey);
    return privateKeyPem;
  }

  /// Extracts the public key from a PEM-formatted private key.
  /// Returns the public key in PEM format.
  static Future<String> extractPublicKey(String privateKeyPem) async {
    final privateKey = _decodePrivateKeyPem(privateKeyPem);
    final publicKey = RSAPublicKey(privateKey.modulus!, privateKey.privateExponent!);
    return _encodePublicKeyPem(publicKey);
  }

  /// Extracts the public key from a PEM-formatted private key and returns it
  /// in JWK (JSON Web Key) format for use in JWKS endpoints.
  static Future<Map<String, dynamic>> extractPublicKeyJwk(
    String privateKeyPem, {
    String? keyId,
    String? use = 'sig',
    String? alg = 'RS256',
  }) async {
    final privateKey = _decodePrivateKeyPem(privateKeyPem);
    final publicKey = RSAPublicKey(privateKey.modulus!, privateKey.privateExponent!);
    
    // Convert modulus and exponent to base64url encoding
    final modulusBytes = _bigIntToBytes(publicKey.modulus!);
    final exponentBytes = _bigIntToBytes(publicKey.exponent!);
    
    return {
      'kty': 'RSA',
      'use': use,
      'alg': alg,
      if (keyId != null) 'kid': keyId,
      'n': base64Url.encode(modulusBytes).replaceAll('=', ''),
      'e': base64Url.encode(exponentBytes).replaceAll('=', ''),
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

  /// Signs data using RSA-SHA256 with a private key.
  static Uint8List signRsaSha256(Uint8List data, RSAPrivateKey privateKey) {
    final signer = RSASigner(SHA256Digest(), '0609608648016503040201');
    signer.init(true, PrivateKeyParameter<RSAPrivateKey>(privateKey));
    return signer.generateSignature(data).bytes;
  }

  /// Verifies RSA-SHA256 signature with a public key.
  static bool verifyRsaSha256(Uint8List data, Uint8List signature, RSAPublicKey publicKey) {
    final signer = RSASigner(SHA256Digest(), '0609608648016503040201');
    signer.init(false, PublicKeyParameter<RSAPublicKey>(publicKey));
    return signer.verifySignature(data, RSASignature(signature));
  }

  /// Decodes a PEM-formatted private key to RSAPrivateKey.
  static RSAPrivateKey _decodePrivateKeyPem(String pem) {
    final lines = pem.split('\n');
    final base64Key = lines
        .where((line) => !line.startsWith('-----'))
        .join('');
    
    final keyBytes = base64.decode(base64Key);
    final asn1Parser = ASN1Parser(keyBytes);
    final topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;
    
    // Parse the ASN.1 structure for RSA private key
    final values = topLevelSeq.elements!;
    final version = values[0] as ASN1Integer;
    
    if (version.value!.toInt() != 0) {
      throw Exception('Unsupported RSA private key version');
    }
    
    final modulus = (values[1] as ASN1Integer).value!;
    final publicExponent = (values[2] as ASN1Integer).value!;
    final privateExponent = (values[3] as ASN1Integer).value!;
    final prime1 = (values[4] as ASN1Integer).value!;
    final prime2 = (values[5] as ASN1Integer).value!;
    final exponent1 = (values[6] as ASN1Integer).value!;
    final exponent2 = (values[7] as ASN1Integer).value!;
    final coefficient = (values[8] as ASN1Integer).value!;
    
    return RSAPrivateKey(modulus, privateExponent, prime1, prime2);
  }

  /// Encodes an RSAPrivateKey to PEM format.
  static String _encodePrivateKeyPem(RSAPrivateKey privateKey) {
    final asn1Seq = ASN1Sequence([
      ASN1Integer(BigInt.zero), // version
      ASN1Integer(privateKey.modulus!),
      ASN1Integer(privateKey.exponent!),
      ASN1Integer(privateKey.privateExponent!),
      ASN1Integer(privateKey.p!),
      ASN1Integer(privateKey.q!),
      ASN1Integer(privateKey.privateExponent! % (privateKey.p! - BigInt.one)),
      ASN1Integer(privateKey.privateExponent! % (privateKey.q! - BigInt.one)),
      ASN1Integer(privateKey.q! * privateKey.q!.modInverse(privateKey.p!)),
    ]);
    
    final keyBytes = asn1Seq.encode();
    final base64Key = base64.encode(keyBytes);
    
    final pemLines = <String>[];
    pemLines.add('-----BEGIN PRIVATE KEY-----');
    
    for (var i = 0; i < base64Key.length; i += 64) {
      final end = (i + 64 < base64Key.length) ? i + 64 : base64Key.length;
      pemLines.add(base64Key.substring(i, end));
    }
    
    pemLines.add('-----END PRIVATE KEY-----');
    return pemLines.join('\n');
  }

  /// Encodes an RSAPublicKey to PEM format.
  static String _encodePublicKeyPem(RSAPublicKey publicKey) {
    final asn1Seq = ASN1Sequence([
      ASN1Sequence([
        ASN1ObjectIdentifier('1.2.840.113549.1.1.1'), // RSA algorithm
        ASN1Null(),
      ]),
      ASN1BitString(_encodePublicKeyAsn1(publicKey)),
    ]);
    
    final keyBytes = asn1Seq.encode();
    final base64Key = base64.encode(keyBytes);
    
    final pemLines = <String>[];
    pemLines.add('-----BEGIN PUBLIC KEY-----');
    
    for (var i = 0; i < base64Key.length; i += 64) {
      final end = (i + 64 < base64Key.length) ? i + 64 : base64Key.length;
      pemLines.add(base64Key.substring(i, end));
    }
    
    pemLines.add('-----END PUBLIC KEY-----');
    return pemLines.join('\n');
  }

  /// Encodes public key components to ASN.1 format.
  static Uint8List _encodePublicKeyAsn1(RSAPublicKey publicKey) {
    final asn1Seq = ASN1Sequence([
      ASN1Integer(publicKey.modulus!),
      ASN1Integer(publicKey.exponent!),
    ]);
    return asn1Seq.encode();
  }

  /// Converts a BigInt to bytes, removing leading zeros.
  static Uint8List _bigIntToBytes(BigInt value) {
    final hexString = value.toRadixString(16);
    // Ensure even length by adding leading zero if needed
    final paddedHex = hexString.length % 2 == 0 ? hexString : '0$hexString';
    
    final byteList = <int>[];
    for (var i = 0; i < paddedHex.length; i += 2) {
      byteList.add(int.parse(paddedHex.substring(i, i + 2), radix: 16));
    }
    
    // Remove leading zeros
    var startIndex = 0;
    while (startIndex < byteList.length - 1 && byteList[startIndex] == 0) {
      startIndex++;
    }
    
    return Uint8List.fromList(byteList.sublist(startIndex));
  }
}