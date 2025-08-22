import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:pointycastle/export.dart';
import 'package:super_simple_authentication_server/src/util/rsa_key_manager.dart';

/// Verifies a JWT and returns the payload if the signature is valid.
/// Supports both symmetric (HS256) and asymmetric (RS256) signing.
///
/// If the signature is invalid, the function returns `null`.
Future<Map<String, dynamic>?> verifyJwt(
  String jwt, {
  String? secretKey,
  String? publicKeyPem,
  @visibleForTesting HMac? hmac,
  @visibleForTesting RSAPublicKey? testPublicKey,
}) async {
  final [encodedHeader, encodedPayload, encodedSignature] = jwt.split('.');

  // Decode and parse the header to determine the algorithm
  final headerBytes = base64Url.decode(
    encodedHeader.padRight(
      ((encodedHeader.length + 3) ~/ 4) * 4,
      '=',
    ),
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

  bool isValidSignature = false;

  if (algorithm == 'HS256') {
    // Symmetric verification
    final resolvedSecretKey =
        secretKey ?? Platform.environment['JWT_SECRET_KEY']!;

    final secretKeyBytes = base64Url.decode(resolvedSecretKey);
    
    // Use PointyCastle for HMAC-SHA256
    final hmac = HMac(SHA256Digest(), 64);
    hmac.init(KeyParameter(secretKeyBytes));
    hmac.update(utf8.encode(signatureInput), 0, utf8.encode(signatureInput).length);
    final signatureBytes = hmac.doFinal();

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
      final resolvedPublicKeyPem = publicKeyPem ?? 
          Platform.environment['JWT_PUBLIC_KEY'] ?? 
          Platform.environment['JWT_RSA_PUBLIC_KEY'];
      
      if (resolvedPublicKeyPem == null) {
        throw Exception('JWT_PUBLIC_KEY or JWT_RSA_PUBLIC_KEY environment variable is required for RS256 verification');
      }

      // Parse the public key PEM
      final lines = resolvedPublicKeyPem.split('\n');
      final base64Key = lines
          .where((line) => !line.startsWith('-----'))
          .join('');
      
      final keyBytes = base64.decode(base64Key);
      final asn1Parser = ASN1Parser(keyBytes);
      final topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;
      
      // Extract the bit string containing the public key
      final bitString = topLevelSeq.elements![1] as ASN1BitString;
      final publicKeyParser = ASN1Parser(bitString.contentBytes());
      final publicKeySeq = publicKeyParser.nextObject() as ASN1Sequence;
      
      final modulus = (publicKeySeq.elements![0] as ASN1Integer).value!;
      final exponent = (publicKeySeq.elements![1] as ASN1Integer).value!;
      
      publicKey = RSAPublicKey(modulus, exponent);
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
