import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:meta/meta.dart';

/// Verifies a JWT and returns the payload if the signature is valid.
/// Supports both symmetric (HS256) and asymmetric (RS256) signing.
///
/// If the signature is invalid, the function returns `null`.
Future<Map<String, dynamic>?> verifyJwt(
  String jwt, {
  String? secretKey,
  String? publicKeyPem,
  @visibleForTesting Hmac? hmac,
  @visibleForTesting RsaSsaPkcs1v15? rsaVerifier,
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

    final resolvedHmac = hmac ?? Hmac.sha256();
    final secretKeyBytes = SecretKey(base64Url.decode(resolvedSecretKey));

    final signatureBytes = await resolvedHmac.calculateMac(
      utf8.encode(signatureInput),
      secretKey: secretKeyBytes,
    );

    if (signatureBytes.bytes.length == existingSignatureBytes.length) {
      isValidSignature = true;
      for (var i = 0; i < signatureBytes.bytes.length; i++) {
        if (signatureBytes.bytes[i] != existingSignatureBytes[i]) {
          isValidSignature = false;
          break;
        }
      }
    }
  } else if (algorithm == 'RS256') {
    // Asymmetric verification
    final resolvedPublicKeyPem = publicKeyPem ?? 
        Platform.environment['JWT_PUBLIC_KEY'] ?? 
        Platform.environment['JWT_RSA_PUBLIC_KEY'];
    
    if (resolvedPublicKeyPem == null) {
      throw Exception('JWT_PUBLIC_KEY or JWT_RSA_PUBLIC_KEY environment variable is required for RS256 verification');
    }

    final resolvedRsaVerifier = rsaVerifier ?? RsaSsaPkcs1v15.sha256();
    final publicKey = await resolvedRsaVerifier.importPublicKey(
      pem: resolvedPublicKeyPem,
    );

    try {
      await resolvedRsaVerifier.verify(
        utf8.encode(signatureInput),
        signature: Signature(existingSignatureBytes, publicKey: publicKey),
      );
      isValidSignature = true;
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
