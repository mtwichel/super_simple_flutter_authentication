import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:pointycastle/asn1/asn1_parser.dart';
import 'package:pointycastle/asn1/primitives/asn1_bit_string.dart';
import 'package:pointycastle/asn1/primitives/asn1_integer.dart';
import 'package:pointycastle/asn1/primitives/asn1_sequence.dart';
import 'package:pointycastle/export.dart';
import 'package:super_simple_authentication_toolkit/src/util/rsa_key_manager.dart';

/// Verifies a JWT and returns the payload if the signature is valid.
/// Supports both symmetric (HS256) and asymmetric (RS256) signing.
///
/// If the signature is invalid, the function returns `null`.
Future<Map<String, dynamic>?> verifyJwt(
  String jwt, {
  String? secretKey,
  String? publicKeyPem,
  bool enableJwksLookup = true,
  @visibleForTesting HMac? hmac,
  @visibleForTesting RSAPublicKey? testPublicKey,
}) async {
  final [encodedHeader, encodedPayload, encodedSignature] = jwt.split('.');

  // Decode and parse the header to determine the algorithm
  final headerBytes = base64Url.decode(
    encodedHeader.padRight(((encodedHeader.length + 3) ~/ 4) * 4, '='),
  );
  final header = Map<String, dynamic>.from(
    json.decode(utf8.decode(headerBytes)) as Map,
  );

  final algorithm = header['alg'] as String?;
  if (algorithm == null) {
    return null;
  }

  // Add padding if needed to make length a multiple of 4
  final paddedSignature = encodedSignature.padRight(
    ((encodedSignature.length + 3) ~/ 4) * 4,
    '=',
  );
  final existingSignatureBytes = base64Url.decode(paddedSignature);

  final signatureInput = '$encodedHeader.$encodedPayload';

  var isValidSignature = false;

  if (algorithm == 'HS256') {
    // Symmetric verification
    final resolvedSecretKey =
        secretKey ?? Platform.environment['JWT_SECRET_KEY']!;

    final secretKeyBytes = base64Url.decode(resolvedSecretKey);

    // Use PointyCastle for HMAC-SHA256
    final hmac = HMac(SHA256Digest(), 64)..init(KeyParameter(secretKeyBytes));

    final inputBytes = utf8.encode(signatureInput);
    hmac.update(inputBytes, 0, inputBytes.length);
    final signatureBytes = Uint8List(hmac.macSize);
    hmac.doFinal(signatureBytes, 0);

    if (signatureBytes.length == existingSignatureBytes.length) {
      isValidSignature = true;
      for (var i = 0; i < signatureBytes.length; i++) {
        if (signatureBytes[i] != existingSignatureBytes[i]) {
          isValidSignature = false;
          break;
        }
      }
    }
  } else if (algorithm == 'RS256') {
    // Asymmetric verification
    RSAPublicKey publicKey;
    if (testPublicKey != null) {
      publicKey = testPublicKey;
    } else {
      // Try JWKS lookup first if enabled and jku is present
      final jku = header['jku'] as String?;
      final kid = header['kid'] as String?;

      if (enableJwksLookup && jku != null && kid != null) {
        try {
          publicKey = await _fetchPublicKeyFromJwks(jku, kid);
        } catch (e) {
          // Fall back to environment variable if JWKS lookup fails
          publicKey = _getPublicKeyFromEnvironment(publicKeyPem);
        }
      } else {
        publicKey = _getPublicKeyFromEnvironment(publicKeyPem);
      }
    }

    try {
      isValidSignature = RsaKeyManager.verifyRsaSha256(
        utf8.encode(signatureInput),
        existingSignatureBytes,
        publicKey,
      );
    } catch (e) {
      isValidSignature = false;
    }
  } else {
    // Unsupported algorithm
    return null;
  }

  if (!isValidSignature) {
    return null;
  }

  final payload = Map<String, dynamic>.from(
    json.decode(
          utf8.decode(
            base64Url.decode(
              encodedPayload.padRight(
                ((encodedPayload.length + 3) ~/ 4) * 4,
                '=',
              ),
            ),
          ),
        )
        as Map,
  );
  return payload;
}

/// Fetches a public key from a JWKS endpoint.
Future<RSAPublicKey> _fetchPublicKeyFromJwks(
  String jwksUrl,
  String keyId,
) async {
  final response = await http.get(Uri.parse(jwksUrl));
  if (response.statusCode != 200) {
    throw Exception('Failed to fetch JWKS from $jwksUrl');
  }

  final jwks = json.decode(response.body) as Map<String, dynamic>;
  final rawKeys = jwks['keys'] as List?;
  final keys = rawKeys == null
      ? null
      : List<Map<String, dynamic>>.from(rawKeys);

  if (keys == null) {
    throw Exception('No keys found in JWKS');
  }

  // Find the key with matching key ID
  final key = keys.firstWhere(
    (k) => k['kid'] == keyId,
    orElse: () => throw Exception('Key with ID $keyId not found in JWKS'),
  );

  // Extract modulus and exponent from JWK
  final modulus = _base64UrlToBigInt(key['n'] as String);
  final exponent = _base64UrlToBigInt(key['e'] as String);

  return RSAPublicKey(modulus, exponent);
}

/// Gets public key from environment variables.
RSAPublicKey _getPublicKeyFromEnvironment(String? publicKeyPem) {
  final resolvedPublicKeyPem =
      publicKeyPem ?? Platform.environment['JWT_RSA_PUBLIC_KEY'];

  if (resolvedPublicKeyPem == null) {
    throw Exception(
      '''JWT_RSA_PUBLIC_KEY environment variable is required for RS256 verification''',
    );
  }

  // Parse the public key PEM
  final lines = resolvedPublicKeyPem.split('\n');
  final base64Key = lines.where((line) => !line.startsWith('-----')).join();

  final keyBytes = base64.decode(base64Key);
  final asn1Parser = ASN1Parser(keyBytes);
  final topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;

  // Extract the bit string containing the public key
  final bitString = topLevelSeq.elements![1] as ASN1BitString;
  final publicKeyParser = ASN1Parser(
    Uint8List.fromList(bitString.stringValues!),
  );
  final publicKeySeq = publicKeyParser.nextObject() as ASN1Sequence;

  final modulus = (publicKeySeq.elements![0] as ASN1Integer).integer!;
  final exponent = (publicKeySeq.elements![1] as ASN1Integer).integer!;

  return RSAPublicKey(modulus, exponent);
}

/// Converts base64url-encoded string to BigInt.
BigInt _base64UrlToBigInt(String base64Url) {
  // Add padding if needed
  final padded = base64Url.padRight(((base64Url.length + 3) ~/ 4) * 4, '=');

  // Convert base64url to base64
  final base64Str = padded.replaceAll('-', '+').replaceAll('_', '/');

  // Decode to bytes
  final bytes = base64.decode(base64Str);

  // Convert to BigInt
  return BigInt.parse(
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
    radix: 16,
  );
}
