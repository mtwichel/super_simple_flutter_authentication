import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:meta/meta.dart';

/// Creates a JWT with asymmetric signing using RSA.
/// This is similar to Firebase's JWT implementation.
Future<String> createJwtAsymmetric({
  required bool? isNewUser,
  Duration validFor = const Duration(hours: 1),
  Duration notBefore = Duration.zero,
  String? audience,
  String? subject,
  String? issuer,
  String? keyId,
  Map<String, dynamic> additionalClaims = const {},
  @visibleForTesting RsaSsaPkcs1v15? rsaSigner,
}) async {
  final payload = {
    ...additionalClaims,
    if (audience != null) 'aud': audience,
    if (subject != null) 'sub': subject,
    if (issuer != null) 'iss': issuer,
    if (notBefore != Duration.zero)
      'nbf': DateTime.now().add(notBefore).toUtc().toUnixTimestamp(),
    'iat': DateTime.now().toUtc().toUnixTimestamp(),
    'exp': DateTime.now().add(validFor).toUtc().toUnixTimestamp(),
    if (isNewUser != null) 'new': isNewUser,
  };

  // Create the header with RS256 algorithm and optional key ID
  final header = {
    'alg': 'RS256',
    'typ': 'JWT',
    if (keyId != null) 'kid': keyId,
  };

  // Encode header and payload
  final encodedHeader = base64Url
      .encode(utf8.encode(json.encode(header)))
      .replaceAll('=', '');
  final encodedPayload = base64Url
      .encode(utf8.encode(json.encode(payload)))
      .replaceAll('=', '');

  // Create the signature input
  final signatureInput = '$encodedHeader.$encodedPayload';

  // Get the private key from environment or use default
  final privateKeyPem = Platform.environment['JWT_PRIVATE_KEY'] ?? 
      Platform.environment['JWT_RSA_PRIVATE_KEY'];
  
  if (privateKeyPem == null) {
    throw Exception('JWT_PRIVATE_KEY or JWT_RSA_PRIVATE_KEY environment variable is required for asymmetric signing');
  }

  // Create the signature using RSA
  final resolvedRsaSigner = rsaSigner ?? RsaSsaPkcs1v15.sha256();
  final privateKey = await resolvedRsaSigner.importPrivateKey(
    pem: privateKeyPem,
  );
  
  final signatureBytes = await resolvedRsaSigner.sign(
    utf8.encode(signatureInput),
    secretKey: privateKey,
  );
  
  final encodedSignature = base64Url
      .encode(signatureBytes.bytes)
      .replaceAll('=', '');

  // Combine all parts to create the JWT
  return '$encodedHeader.$encodedPayload.$encodedSignature';
}

extension on DateTime {
  int toUnixTimestamp() => millisecondsSinceEpoch ~/ 1000;
}